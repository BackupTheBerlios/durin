#!/usr/bin/perl -w 

use Durin::Classification::Experimentation::ExperimentFactory;

use IO::File;
use Statistics::Distributions;
use File::Spec::Functions;
use Env;
use DBI;
use Text::Template;

#DBI->trace(2);
use strict;
use warnings;


$|=1;
my $inFile = 0;

if ($#ARGV < 0)
  {
    print "Generates experimental summaries: scatter plots and significance tests\n";
    die "Usage: gScatterPlotas.pl experiment.exp.pm [percentage]\n";
  }

my $ExpFileName = $ARGV[$inFile];
my $percentage = 5;
if ($#ARGV == 1) {
  $percentage = $ARGV[1];
}

my $exp_chr = do $ExpFileName;
my $exp = Durin::Classification::Experimentation::ExperimentFactory->createExperiment($exp_chr);

my $table = $exp->getSQLiteTable();
#my $scatterer = new Durin::Plot::Scatterer($exp);
#$scatterer->setMeasure("AUC");
#$scatterer->setScatteringAttribute("maxIW");


scatter($exp,
	$table,
	"AUC",
	["maxIW"],
	"inducer",
	["proportion","nNodes","nVal"],
	["run","fold"]);
scatter($exp,
	$table,
	"AUC",
	["nVal"],
	"inducer",
	["proportion","nNodes","maxIW"],
	["run","fold"]);

scatter($exp,
	$table,
	"AUC",
	["nNodes"],
	"inducer",
	["proportion","nVal","maxIW"],
	["run","fold"]);

scatter($exp,
	$table,
	"AUC",
	["proportion"],
	"inducer",
	["nNodes","nVal","maxIW"],
	["run","fold"]);

#package Scatterer;

#use Class::MethodMaker 
#  new_with_init => 'new',
#  get_set => [-java => qw/ ModelGenerationCharacteristics ModelKind/];

#sub init {
  
#}

sub single_scatter {
  my ($exp,
      $table,
      $measure,
      $scattering_attribute,$v1,$v2,
      $grouping_attributes,
      $ordering_attributes,
      $running_attributes,$running_attributes_values) = @_;
  
  my @join_attributes = @$ordering_attributes;
  push @join_attributes, @$grouping_attributes;
  my $joint_table = $table->select_and_join($scattering_attribute,[$v1,$v2],
					    $measure,
					    \@join_attributes
					   );
  
  my $v1_att = Matrix::MultiAttribute::to_att($v1);
  my $v2_att = Matrix::MultiAttribute::to_att($v2);
  my $measure_v1 = $measure."_".$v1_att;
  my $measure_v2 = $measure."_".$v2_att;
  my $filename = "";
  for (my $i = 0; $i < scalar(@$running_attributes) ; $i++) {
    $filename = $filename.$running_attributes->[$i]."=".$running_attributes_values->[$i]."-";
  }
  
  my $filename1 = $filename."$v1_att-$v2_att-$measure";
  my $filename2 = $filename."$v2_att-$v1_att-$measure";
  

 
  my ($v1_v2,$v2_v1) = @{multiple_sig_test($joint_table,
					   $measure_v1,$measure_v2,
					   $grouping_attributes,
					   $percentage # Statistical sig percentage
					  )};
  
  my $filename_sig_1 = catfile(catfile($exp->getBaseFileName(),"sig/$percentage"),$filename1);
  my $filename_sig_2 = catfile(catfile($exp->getBaseFileName(),"sig/$percentage"),$filename2);
  
  my $file1 = new IO::File; 
  $file1->open(">$filename_sig_1.sig") or die $!;
  print $file1 "$v1_v2 - $v2_v1";
  $file1->close();
  my $file2 = new IO::File; 
  $file2->open(">$filename_sig_2.sig") or die $!;
  print $file2 "$v2_v1 - $v1_v2";
  $file2->close();
  
  my $grouped_table = $joint_table->avg_group_by([$measure_v1,$measure_v2],
						 $grouping_attributes);
  
  my $filename_figures_1 = catfile(catfile($exp->getBaseFileName(),"figures"),$filename1);
  my $filename_figures_2 = catfile(catfile($exp->getBaseFileName(),"figures"),$filename2);
  plot_scatter($grouped_table,
	       $measure,
	       $v1_att,$v2_att,
	       $filename_figures_1);
  plot_scatter($grouped_table,
	       $measure,
	       $v2_att,$v1_att,
	       $filename_figures_2);
  
  #sig_test($joint_table,
  #	   $mea

}

sub scatter {
  my ($exp,
      $table,
      $measure,
      $running_attributes,
      $scattering_attribute,
      $grouping_attributes,
      $ordering_attributes) = @_;
  
  my $running_attributes_value_set = $table->project_unique($running_attributes);
  foreach my $running_attributes_values (@{$running_attributes_value_set->fetchall_arrayref()}) {
    my $subtable = $table->select($running_attributes,$running_attributes_values);
    my $scattering_attribute_values = $subtable->project_unique([$scattering_attribute]);
    my $visited = {};
    foreach my $scattering_attribute_value_1 (@{$scattering_attribute_values->fetchall_arrayref()}) {
      my $v1 =	$scattering_attribute_value_1->[0];
      $visited->{$v1} = 1;
      foreach my $scattering_attribute_value_2 (@{$scattering_attribute_values->fetchall_arrayref()}) { 
	my $v2 = $scattering_attribute_value_2->[0];
	if (!($visited->{$v2})) {
	  single_scatter($exp,
			 $subtable,
			 $measure,
			 $scattering_attribute,$v1,$v2,
			 $grouping_attributes,
			 $ordering_attributes,
			 $running_attributes,$running_attributes_values);
	}
      }
    }
  }
}

sub multiple_sig_test {
  my ($joint_table,
      $v1,$v2,
      $grouping_attributes,
      $percentage) = @_;

  my $v1_v2 = 0;
  my $v2_v1 = 0;
  my $grouping_attributes_value_set = $joint_table->project_unique($grouping_attributes);
  foreach my $grouping_attributes_values (@{$grouping_attributes_value_set->fetchall_arrayref()}) {
    my $subtable = $joint_table->select($grouping_attributes,$grouping_attributes_values);
    my $dif_table_1 = $subtable->project_difference($v1,$v2);
    my $dif_table_2 = $subtable->project_difference($v2,$v1);
    my $result = sig_test($dif_table_1,$percentage);
    if ($result == 1) {
      $v1_v2++;
    } 
    $result = sig_test($dif_table_2,$percentage);
    if ($result == 1) {
      $v2_v1++;
    }
  }
  return [$v1_v2,$v2_v1];
}

sub sig_test {
  my ($table,$percentage) = @_;
  
  my $difference = $table->fetchall_arrayref([0]);
  my $UValue = calculateUValue($difference);
  my $n = scalar(@$difference);
  my $U99 = Statistics::Distributions::tdistr($n-1,$percentage/100);
  #print "n:$n  U: $UValue c:$U99\n";
  my $result = 0;
  if ($UValue>$U99) {
    #print "$dataset: $m2 sign. better than $m1 at $percentage%\n";
    $result = 1;
  } else {
    #print "No sign. difference\n";
  }
  #print join(",",@$ERdifference)."\n\n";
  return $result;
}

sub calculateUValue {
  my ($difference) = @_;

  my $n = scalar(@$difference);
  my $sum = 0;
  foreach my $x (@$difference) {
    $sum += $x->[0];
  }
  my $xav = $sum / $n;
  my $sn2 = 0;
  foreach my $x (@$difference) {
    $sn2 += ($x->[0] - $xav)*($x->[0] - $xav);
  }
  #print join(",",@$ERdifference)."\n\n";
  #print "sn2:$sn2\n";
  
  if ($sn2==0) {
    return 0;
  }
  return (sqrt($n)*$xav)/(sqrt($sn2/($n-1)));
}


sub plot_scatter {
  my ($joint_table,
      $measure,
      $modelA,$modelB,
      $filename) = @_;
  
  print "$modelA against $modelB\n";
  # transform plot data into string
  my $data = "";
  my $i = 0;
  #print "m1\n";
  my $max_x;
  my $max_y;
  my $min_x;
  my $min_y;
  my $init = 0;
  #print "m2\n";
  my $logPoutliers = [];
  my $data_hashref = $joint_table->fetchall_arrayref({});
  foreach my $row (@$data_hashref) {
    #foreach my $key (keys %$row) {
    #  print "$key = ".$row->{$key}."\n";
    #}
    #print "Y yasta\n";
    my $x = $row->{$measure."_".$modelA};
    #print "x:$x\n";
    my $y = $row->{$measure."_".$modelB};
    #print "y:$y\n";
    if ($init == 0) {
      $max_x = $x;
      $min_x = $x;
      $max_y = $y;
      $min_y = $y;
      $init = 1;
    }
    
    if ($x > 1000) {
      if ($y > 1000) {
	print "There is a weird two sided outlier?\n";
      } else {
	push @$logPoutliers,["x",$y];
      }
    } else {
      if ($y > 1000) { 
	push @$logPoutliers,["y",$x];
      } else {
	$max_x = $x if $x > $max_x; 
	$min_x = $x if $x < $min_x;
	$max_y = $y if $y > $max_y; 
	$min_y = $y if $y < $min_y;
	$data = $data."".$x." ".$y."\n";
      }
    }
  }
  my $multiplied_x = 0;
  my $multiplied_y = 0;
  foreach my $outlier (@$logPoutliers) {
    if ("x" eq $outlier->[0]) {
      if (!$multiplied_x) {
	$max_x *= 1.1;
	$multiplied_x = 1;
      }
      $data = $data."".$max_x." ".$outlier->[1]."\n";
    } else { 
      if (!$multiplied_y) {
	$max_y *= 1.1;
	$multiplied_y = 1;
      }
      $data = $data."".$outlier->[1]." ".$max_y."\n";
    }
  }
  $data = $data."e\n";
#  print $data."\n";
  
  # generate gnuplot file
  
  my $tmpFile = File::Temp->new(DIR=>'/tmp',
				SUFFIX => '.gnuplot');
  
  my $template = Text::Template->new(SOURCE => "$DURIN_HOME/scripts/plot.gnuplot.tmpl")
    or die "Couldn't construct template: $Text::Template::ERROR";
  
  # It is a squared plot. Collapse the max's and min's.
  my $min = $min_x < $min_y ? $min_x : $min_y;
  my $max = $max_x < $max_y ? $max_y : $max_x;

 
  my %vars = (x_size => 2,
	      y_size => 2,
	      x_range_min => $min-($max-$min)*0.1,
	      x_range_max => $max+($max-$min)*0.1,
	      y_range_min => $min-($max-$min)*0.1,
	      y_range_max => $max+($max-$min)*0.1,
	      output => $filename.".eps",
	      data => $data
	     );
  #print "Template:".$template."\n";
  my $result = $template->fill_in(HASH => \%vars);
  die "$Text::Template::ERROR\n"  if (!defined $result);
  print $tmpFile $result;
  system "gnuplot ".$tmpFile->filename;
}



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

scatter($table,
	"AUC",
	["maxIW"],
	"inducer",
	["proportion","nNodes","nVal"],
	["run","fold"]);
scatter($table,
	"AUC",
	["nVal"],
	"inducer",
	["proportion","nNodes","maxIW"],
	["run","fold"]);

scatter($table,
	"AUC",
	["nNodes"],
	"inducer",
	["proportion","nVal","maxIW"],
	["run","fold"]);

scatter($table,
	"AUC",
	["proportion"],
	"inducer",
	["nNodes","nVal","maxIW"],
	["run","fold"]);




sub single_scatter {
  my ($table,$measure,$scattering_attribute,$scattering_attribute_value_1,$scattering_attribute_value_2,$grouping_attributes,$ordering_attributes,$running_attributes,$running_attributes_values) = @_;
  #my $grouping_attributes_value_set = $table->project_unique($grouping_attributes);
  #foreach my $grouping_attributes_values (@{$grouping_attributes_value_set->fetchall_arrayref()}) {
  #  print "Fourth\n";
  #  my $subtable = $table->select($grouping_attributes,$grouping_attributes_values);
  #  print "Fifth\n";
  #my $joint_table = $table->join

  my $joint_table = $table->select_and_join($scattering_attribute,
					    [$scattering_attribute_value_1,$scattering_attribute_value_2],
					    $measure,
					    $ordering_attributes,
					    $grouping_attributes
					   );
  plot_scatter($joint_table,$measure,Matrix::MultiAttribute::to_att($scattering_attribute_value_1),Matrix::MultiAttribute::to_att($scattering_attribute_value_2),$running_attributes,$running_attributes_values);
  # The order is NOT GUARANTEED to be the same!! 
  #plot_scatter
  #do_scatter(
}

sub scatter {
  my ($table,$measure,$running_attributes,$scattering_attribute,$grouping_attributes,$ordering_attributes) = @_;
  
  my $running_attributes_value_set = $table->project_unique($running_attributes);
  #print "First\n";
  foreach my $running_attributes_values (@{$running_attributes_value_set->fetchall_arrayref()}) {
    #print "Second\n";
    my $subtable = $table->select($running_attributes,$running_attributes_values);
    #print "Third\n";
    my $scattering_attribute_values = $subtable->project_unique([$scattering_attribute]);
    my $visited = {};
    foreach my $scattering_attribute_value_1 (@{$scattering_attribute_values->fetchall_arrayref()}) {
      my $v1 =	$scattering_attribute_value_1->[0];
      $visited->{$v1} = 1;
      foreach my $scattering_attribute_value_2 (@{$scattering_attribute_values->fetchall_arrayref()}) { 
	my $v2 = $scattering_attribute_value_2->[0];
	#if (!$visited->{$v2}) {
	if (!($v2 eq $v1)) {
	  single_scatter($subtable,$measure,$scattering_attribute,$v1,$v2,$grouping_attributes,$ordering_attributes,$running_attributes,$running_attributes_values);
	}
      }
    }
  }
}

sub plot_scatter {
  my ($joint_table,$measure,$modelA,$modelB,$running_attributes,$running_attributes_values) = @_;

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

  my $filename = "";
  for (my $i = 0; $i < scalar(@$running_attributes) ; $i++) {
    $filename = $filename.$running_attributes->[$i]."=".$running_attributes_values->[$i]."-";
  }
  $filename = $filename."$modelA-$modelB-$measure.eps";
  
  my %vars = (x_size => 2,
	      y_size => 2,
	      x_range_min => $min-($max-$min)*0.1,
	      x_range_max => $max+($max-$min)*0.1,
	      y_range_min => $min-($max-$min)*0.1,
	      y_range_max => $max+($max-$min)*0.1,
	      output => $filename,
	      data => $data
	     );
  #print "Template:".$template."\n";
  my $result = $template->fill_in(HASH => \%vars);
  die "$Text::Template::ERROR\n"  if (!defined $result);
  print $tmpFile $result;
  system "gnuplot ".$tmpFile->filename;
}



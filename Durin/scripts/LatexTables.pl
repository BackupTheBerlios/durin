#!/usr/bin/perl -w 

use IO::File;
use Durin::Classification::Experimentation::ResultTable;
use Durin::Classification::Experimentation::CompleteResultTable;
use Durin::ProbClassification::ProbModelApplication;
use Durin::Utilities::MathUtilities;

my $inFile = 0;

if ($#ARGV < 0)
  {
    print "Generates Latex table files addecuate for placing them in papers\n";
    die "Usage: LatexTables.pl experiment.exp\n";
  }

$ExpFileName = $ARGV[$inFile];
our $exp;

do $ExpFileName;

my $AveragesTable = $exp->loadResultsFromFiles();
$AveragesTable->compressRuns();
PrintTables($AveragesTable);
print "Done\n";

sub PrintTables {
  my ($AveragesTable) = @_;
  my $proportions=$AveragesTable->getProportions();
  foreach my $proportion (@$proportions) {
    PrintLaTexTable($AveragesTable,"ER","ERTable-$proportion.tex",$proportion);
    PrintLaTexTable($AveragesTable,"LogP","LogPTable-$proportion.tex",$proportion);
  }
}

#PrintLaTexERTable($AveragesTable,$ARGV[$ER],$ARGV[$proportion]);
#PrintLaTexLogPTable($AveragesTable,$ARGV[$LOGP],$ARGV[$proportion]);


sub PrintLaTexTable {
  my ($AveragesTable,$measure,$file_name,$proportion) = @_;
  
  my $file = new IO::File;
  $file->open(">$file_name") or die "Unable to open $file_name\n";
  
  print $file "\\begin{table}[hbt]\n";
  print $file "\\begin{center}\n";
  print $file "\\tiny\n";
  print $file "\\begin{tabular}{|l|c|c|c|c|c|c|c|c|c|c|c|c|}\\hline\n";
  
  my $models = $AveragesTable->getModels();
  my $datasets = $AveragesTable->getDatasets();
  
  #  my @models = keys %{$AveragesTable->{$calculatedList->[0]}};
  #print $list[0]->[0]."\n";
  print $file "{\\bf Dataset}";
  foreach my $model (@$models)
    {
      print $file " & $model";
    }
  print $file "\\\\ \\hline \\hline\n";
  #print "Hola radiola\n";
  foreach my $dataset (@$datasets){
    print $file "{\\sc $dataset } ";
    #print "Dataset: $dataset\n";
    foreach my $model (@$models) {
      #print "Model: $model\n";
      my $MeasureAv = GetMeasureAv($AveragesTable,$measure,$model,$dataset,$proportion);
      my $MeasureStDev = GetMeasureStDev($AveragesTable,$measure,$model,$dataset,$proportion);
      print "$dataset,$model,$proportion,$MeasureAv +- $MeasureStDev\n";
      if ($MeasureAv == -1) {
	print $file " & - ";
      } else {
	if (HasModelMinimumMeasureForDatasetAndProportion($AveragesTable,$measure,$model,$dataset,$proportion)) {
	  printf $file " & {\\bf %.2f \$\\pm\$ %.2f} " , ($MeasureAv,$MeasureStDev );  
	} else {
	  printf $file " & %.2f \$\\pm\$ %.2f " , ($MeasureAv,$MeasureStDev);
	}
      }
    }
    print $file "\\\\ \\hline\n";
  }
  print $file "\\end{tabular}\n";
  print $file "\\end{center}\n";
  #%\vspace{-0.4cm}
  my $prop100 = 100*$proportion;
  print $file "\\caption{Averages and standard deviations of ".GetMeasureName($measure)." using $prop100\\% of the learning data}\n";
  print $file "\\protect\\label{".$measure."Table-$proportion}\n";
  #\caption{Average accuracies and their standard deviations}
  #\protect\label{AverageAccuracies}
  print $file "\\end{table}\n";
  
  $file->close();
}

sub GetMeasureAv {
  my ($AveragesTable,$measure,$model,$dataset,$proportion) = @_;
  
  my $val;
  if ($measure eq "ER") {
    $val = $AveragesTable->getAvER($model,$dataset,$proportion);
  } else {
    if ($measure eq "LogP") {
      $val = $AveragesTable->getAvLogP($model,$dataset,$proportion);
    }
  }
  return $val;
}

sub GetMeasureStDev {
  my ($AveragesTable,$measure,$model,$dataset,$proportion) = @_;

  #print "Measure: $measure\n";
  my $val;
  if ($measure eq "ER") {
    $val = $AveragesTable->getStDevER($model,$dataset,$proportion);
  } else {
    if ($measure eq "LogP") {
      $val = $AveragesTable->getStDevLogP($model,$dataset,$proportion);
    }
  }
  return $val;
}

sub HasModelMinimumMeasureForDatasetAndProportion {
  my ($AveragesTable,$measure,$model,$dataset,$proportion) = @_;

  my $val;
  if ($measure eq "ER") {
    $val = $AveragesTable->HasModelMinimumERForDatasetAndProportion($model,$dataset,$proportion);
  } else {
    if ($measure eq "LogP") {
      $val = $AveragesTable->HasModelMinimumLogPForDatasetAndProportion($model,$dataset,$proportion);
    }
  }
  return $val;
}

sub GetMeasureName {
  my ($measure) = @_;
  
  my $val;
  if ($measure eq "ER") {
    $val = "error rate";
  } else {
    if ($measure eq "LogP") {
      $val = '$LogScore$';
    }
  }
  return $val;
}

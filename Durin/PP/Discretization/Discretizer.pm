
package Durin::PP::Discretization::Discretizer;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

#use Durin::Data::MemoryTable;
use Durin::PP::Discretization::Frequency;
use Durin::PP::Discretization::FayyadIrani;
use Durin::PP::Discretization::DiscretizationApplier;

sub new_delta
  {
    my ($class,$self) = @_;
    
    #   $self->{METADATA} = undef; 
}

sub clone_delta
  { 
    my ($class,$self,$source) = @_;
    
    #   $self->setMetadata($source->getMetadata()->clone());
  }

sub run
  {
    my ($self) = @_;
    
    my $input = $self->getInput();
    
    my $methodName = $input->{DISCMETHOD};
    my $method;
    if ($methodName eq "Frequency")
      {
	$method = Durin::PP::Discretization::Frequency->new();
      }
    else
      {
	if ($methodName eq "Fayyad-Irani")
	  {
	    $method = Durin::PP::Discretization::FayyadIrani->new();
	  }
	else
	  {
	    die "Unknown discretization method: $methodName\n";
	  }
      }
    
    $method->setInput($input);
    $method->run();
    my $discretization = $method->getOutput();
    print "Discretization:\n";
    foreach my $d (@$discretization)
      {
	print (join(",",@$d),"\n");
      }
    my $inputDA;
      
    $inputDA->{TABLE} = $input->{TABLE};
    if (exists $input->{OUTPUT_TABLE})
      {
	$inputDA->{OUTPUT_TABLE} =  $input->{OUTPUT_TABLE};
      }
    
    $inputDA->{DISC} = $discretization;
    my $DA = Durin::PP::Discretization::DiscretizationApplier->new();
    $DA->setInput($inputDA);
    $DA->run();
    my $discTable = $DA->getOutput();
    #$discTable->open();
    #$discTable->applyFunction(sub
    #			      {
    #				my ($row) = @_;
    #				
    #				print join(',',@$row)."\n";
    #			      }
    #			     );
    #    $discTable->close();
    my $output;
    $output->{TABLE} = $discTable;
    $output->{DISC} = $discretization;
    $self->setOutput($output);
  }

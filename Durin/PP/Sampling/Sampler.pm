# Sampling is done using memory tables...

package Durin::PP::Sampling::Sampler;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::Data::MemoryTable;
#use Durin::Data::FileTable;

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
  
    my $Input = $self->getInput();
    my $table = $Input->{TABLE};
    my $percent = $Input->{PERCENTAGE};
    	
    my ($train,$test,$sub);

    $train = Durin::Data::MemoryTable->new();
    $test = Durin::Data::MemoryTable->new();
    #$train = Durin::Data::FileTable->new();
    #$test = Durin::Data::FileTable->new();
    my $metadataTrain = Durin::Metadata::Table->new();
    $metadataTrain->setSchema($table->getMetadata()->getSchema());
    $metadataTrain->setName($table->getMetadata()->getName()."-Train");
    $train->setMetadata($metadataTrain);
    my $metadataTest = Durin::Metadata::Table->new();
    $metadataTest->setSchema($table->getMetadata()->getSchema());
    $metadataTest->setName($table->getMetadata()->getName()."-Test");
    $test->setMetadata($metadataTest);

    my $count = 0;
    $train->open();
    $test->open();    
    $table->open();
    if  (exists $Input->{FUNCTION})
      {
	# print "Exists\n";
	my $function = $Input->{FUNCTION};
	$sub = sub 
	  {
	   my ($row) = @_;
	   
	   if ((rand 1) < $percent)
	   {
	     $train->addRow($row);
	     &$function($row);
	   }
	   else
	   {
	     $test->addRow($row);
	   }
	   # $count++;
	  }
      }
    else
      {
	#print "Does not exist\n";
        $sub = sub 
	  {
	   my ($row) = @_;
	   
	   if ((rand 1) < $percent)
	   {
	     $train->addRow($row);
	   }
	   else
	   {
	     $test->addRow($row);
	   }
	   # $count++;
	  }
      }
    $table->applyFunction($sub);
    #    print "Dataset contains: $count examples\n";
    $table->close();
    $train->close();
    $test->close();
    my ($output) = {};
    $output->{TRAIN} = $train;
    $output->{TEST} = $test;
    $self->setOutput($output);
  }

1;

package Durin::PP::TableTransformator;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

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

sub run($)
{
  my ($self) = @_;
  
  my $Input = $self->getInput();
  my $inTable = $Input->{TABLE_SOURCE};
  my $outTable = $Input->{TABLE_DESTINATION};
  my $vector = $Input->{TRANSFORMATION_VECTOR};
  my $i;
  my $trans;
  
  $inTable->open("<");
  $outTable->open(">");
  $inTable->applyFunction(sub
			  {
			    my ($row) = @_;
			    
			    $i = 0;
			    foreach $trans (@$vector)
			      {
				$row->[$i] = $trans->transform($row->[$i]);
				$i++;
			      }
			    $outTable->addRow($row);
			  }
			 );
  $outTable->close();
  $inTable->close();
}

1;

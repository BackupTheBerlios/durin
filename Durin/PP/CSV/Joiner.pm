# Joins two CSV's which are already ordered by the key value

package Durin::PP::CSV::Joiner;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

sub new_delta
{
    my ($class,$self) = @_;
    
    #$self->{COPIER} = Durin::PP::TableCopier->new();
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
  my $master = $Input->{TABLE_MASTER};
  my $keyNameMaster = $Input->{KEY_FIELD_MASTER};
  my $slave = $Input->{TABLE_SLAVE};
  my $keyNameSlave = $Input->{KEY_FIELD_SLAVE};
  my $outFile = $Input->{TABLE_DESTINATION};
  
  $master->open("<");
  $slave->open("<");


  # We get the column indexes
  
  my $headerMapMaster = $master->getHeaderMap();
  my $keyIndexMaster = $headerMapMaster->{$keyNameMaster};
  my $headerMapSlave = $slave->getHeaderMap();
  my $keyIndexSlave = $headerMapSlave->{$keyNameSlave};
  
  
  # Process headers
  
  my $headersMaster = $master->getHeaders();
  my $headersSlave = $slave->getHeaders();
  my $numFieldsMaster = scalar(@$headersMaster);
  my $headers = joinRows($headersMaster, $headersSlave,$keyIndexSlave);
  
  $outFile->setHeaders($headers);
  $outFile->open(">");
  
  #print "Start reading\n";
  # Start reading
  
  my ($rowMaster,$rowSlave);
  
  $master -> start;
  $slave -> start;
  my $bigger = 1;
  my $equal = 1;

  while ((!($master->eof)) && (!($slave->eof)))
    {
      $rowMaster = $master->getNextRow();	
      while (scalar(@$rowMaster) < $numFieldsMaster)
	{
	  #	print " Adding a field\n";
	  push @$rowMaster,"";
	}
      $bigger = $bigger || ($rowMaster->[$keyIndexMaster] > $rowSlave->[$keyIndexSlave]);
      while ((!($slave->eof)) && $bigger)
	{
	  $rowSlave = $slave->getNextRow();
	  $bigger = ($rowMaster->[$keyIndexMaster] > $rowSlave->[$keyIndexSlave]);
	}
      
      $equal = ($rowMaster->[$keyIndexMaster] == $rowSlave->[$keyIndexSlave]);
      
      while ((!($slave->eof)) && $equal)
	{
	  my $row = joinRows($rowMaster, $rowSlave, $keyIndexSlave);
	  $outFile->addRow($row);	
	  $rowSlave = $slave->getNextRow();
	  $equal = ($rowMaster->[$keyIndexMaster] == $rowSlave->[$keyIndexSlave]);
	}
      if ($equal)
	{
	  my $row = joinRows($rowMaster, $rowSlave, $keyIndexSlave);
	  $outFile->addRow($row);	
	}
      $bigger = 0;
    }
  $self->setOutput($outFile);
}


sub joinRows
  {
    my ($rowMaster, $rowSlave, $index) = @_;
    
    #print "RowMaster: @$rowMaster\n RowSlave: @$rowSlave \n";
    
    splice(@$rowSlave, $index,1);
    
    my $row = [];
    push(@$row, @$rowMaster);
    push(@$row, @$rowSlave);
    return $row;
  }

1;

package Durin::PP::CSV::Sorter;

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
  my $inFile = $Input->{TABLE_SOURCE};
  my $sortField = $Input->{KEY_FIELD};
  my $outFile = $Input->{TABLE_DESTINATION};
  my $alfabetically = $Input->{ALFABETICALLY};
  
  $inFile->open("<");
  #print "B\n";
  # We get the column indexes

  my $headerMap = $inFile->getHeaderMap();
  my $columnIndex = $headerMap->{$sortField};
  #print "Column: $columnIndex\n";
  # Process headers
  
  my $headers = $inFile->getHeaders();
  
  my @rowArray = ();
  #print "Start reading\n";
  $inFile->applyFunction(sub
			  {
			    my ($row) = @_;
			    
			    push @rowArray,$row;
			  }
			 );
  $inFile->close();
  
  my @newArray;
  my $sortingSub;
  
  if ($alfabetically)
    {
      $sortingSub = alfabetically($columnIndex);
    }
  else
    {
      $sortingSub = numerically($columnIndex);
    }
  
  @newArray = sort $sortingSub @rowArray;
  $outFile->setHeaders($headers);
  $outFile->open(">");
  
  #print "Start writing\n";
  
  foreach my $row (@newArray)
    {
      #print "Row: ".join(",",@$row)."\n";
      $outFile->addRow($row);
    }
  $outFile->close();
  $self->setOutput($outFile);
}

sub alfabetically
  {
    my ($colIndex) = @_;
    
    return sub
      {
	return $a->[$colIndex] cmp $b->[$colIndex];
      }
  }

sub numerically
  {
    my ($colIndex) = @_;
    
    return sub
      {
	#print "Row A: ".join(",",@$a)."\n";
	#print "Row B: ".join(",",@$b)."\n";

	return $a->[$colIndex] <=> $b->[$colIndex];
      }
  }

1;

# Implements Gabow's algorithm for finding k maximum weighted spanning tree

package Durin::Algorithms::Gabow;

use Durin::Components::Process;

@ISA = (Durin::Components::Process);

use strict;

use Durin::DataStructures::UGraph;
use Durin::DataStructures::Graph;
use Durin::DataStructures::OrderedList;
use Durin::DataStructures::WeightedGraph;
use Durin::Algorithms::Kruskal;

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
    
    my $Result = [];
    my $UGraph = $self->getInput()->{GRAPH};
    my $k = $self->getInput()->{K};
   
    # Calculate the MST $F with weight $t using Kruskal and add it to the list
   
    #foreach my $e (@{$UGraph->getEdges()})
    #  {
    #	print "[$e->[0],$e->[1],$e->[2]]\n";
    #  }
    
    my $kruskal = Durin::Algorithms::Kruskal->new();
    {
      my $input = {};
      $input->{GRAPH} = $UGraph;
      $kruskal->setInput($input);
    }
    $kruskal->run();
    my $output = $kruskal->getOutput();
    my $WG = $output->{TREE};
    my $t = $WG->getWeight();
    #print"Weight Kruskal: $t\n";
    my $Tree = Durin::DataStructures::WeightedGraph->new();
    $WG->copyDirectedTo($Tree);
    my $L = $output->{LIST};
    
    #print"We have done Kruskal\n";
    push @$Result,($Tree);

    my $in = [];
    my $out = [];
    my $ex = EX($Tree,$in,$out,$L);
    #print "First EX done\n";
    #print "Exchange: [$ex->{E}[0],$ex->{E}[1],$ex->{E}[2]] is substituted by [$ex->{F}[0],$ex->{F}[1],$ex->{F}[2]]\n";
    #print "Weight decrease: ",$ex->{R},"\n";

    # $ex has functions ex->getEdgeDeleted and ex->getEdgeAdded;
    my $P = Durin::DataStructures::OrderedList->new();
    $P->add($t+$ex->{R},[$ex,$Tree,$in,$out]);
    my $i = 1;
    my $Finished = 0;
    while (($i < $k) && !$Finished)
      {
	$Finished = GEN($P,$L,$Result);
	$i++;
      }
    $output = {};
    $output->{TREELIST} = $Result;
    $self->setOutput($output);
  }

sub GEN
  {
    my ($P,$L,$Result)= @_;
    
    if ($P->isEmpty())
      {
	return 1;
      }
    
    my ($t,$Tuple) = @{$P->getFirst()};
    my ($ex,$Tree,$IN,$OUT) = @$Tuple;

    #print "Tuple selected: \n";
    #print "Exchange: [$ex->{E}[0],$ex->{E}[1],$ex->{E}[2]] is substituted by [$ex->{F}[0],$ex->{F}[1],$ex->{F}[2]]\n";
    #print "IN: \n";
    #foreach my $e (@$IN)
    #  {
#	print "[$e->[0],$e->[1],$e->[2]]\n";
#      } print "OUT: \n";
#    foreach my $e (@$OUT)
#      {
#	print "[$e->[0],$e->[1],$e->[2]]\n";
#      }
    #print "Before change Tree:\n";
    #foreach my $e (@{$Tree->getEdges()})
    #  {
#	print "[$e->[0],$e->[1],$e->[2]]\n";
#      }
    # Calculate the new tree

    my $newTree = CreateNew($Tree,$ex);
    
 #   print "After change Tree:\n";
 #   foreach my $e (@{$newTree->getEdges()})
 #     {
#	print "[$e->[0],$e->[1],$e->[2]]\n";
#      }
    
    push @$Result,($newTree);
    
    # Calculating the new additions to $P
    # Be careful with the copies
    
    my $ti = $t - $ex->{F}->[2] + $ex->{E}->[2];
    #print "T: $t Ti: $ti RealWeight:", $newTree->getWeight(),"\n";
    my @INi = @$IN;
    push @INi,($ex->{E});
    my @OUTj = @$OUT;
    push @OUTj,($ex->{E});
    $ex = EX($Tree,\@INi,$OUT,$L); 
    if (defined $ex)
      {
	#print "Adding to the list:\n";
	#print "Exchange: [$ex->{E}[0],$ex->{E}[1],$ex->{E}[2]] is substituted by [$ex->{F}[0],$ex->{F}[1],$ex->{F}[2]]\n";
	#print "IN: \n";
#	foreach my $e (@INi)
#	  {
	    #print "[$e->[0],$e->[1],$e->[2]]\n";
#	  } 
#print "OUT: \n";
#	foreach my $e (@$OUT)
#	  {
	    #print "[$e->[0],$e->[1],$e->[2]]\n";
#	  }
	#print "Tree:\n";
#	foreach my $e (@{$Tree->getEdges()})
#	  {
	    #print "[$e->[0],$e->[1],$e->[2]]\n";
#	  }
	#print "Weight after exchange: ",$ti + $ex->{R},"\n";
	$P->add($ti+$ex->{R},[$ex,$Tree,\@INi,$OUT]);
      }
    $ex = EX($newTree,$IN,\@OUTj,$L);
    if (defined $ex)
      {
	#print "Adding to the list:\n";
	#print "Exchange: [$ex->{E}[0],$ex->{E}[1],$ex->{E}[2]] is substituted by [$ex->{F}[0],$ex->{F}[1],$ex->{F}[2]]\n";
	#print "IN: \n";
#	foreach my $e (@$IN)
#	  {
	    #print "[$e->[0],$e->[1],$e->[2]]\n";
#	  } #print "OUT: \n";
#	foreach my $e (@OUTj)
#	  {
	    #print "[$e->[0],$e->[1],$e->[2]]\n";
#	  }
	#print "Tree:\n";
#	foreach my $e (@{$Tree->getEdges()})
#	  {
	    #print "[$e->[0],$e->[1],$e->[2]]\n";
#	  }
	#print "Weight after exchange: ",$t + $ex->{R},"\n";
	$P->add($t+$ex->{R},[$ex,$newTree,$IN,\@OUTj]);
      }
  }

sub EX
  {
    my ($Tree,$IN,$OUT,$L) = @_;
    
    my $r = -exp(200);
    my ($e,$f);

 #   print "STARTING EX:\n";
 #   print "IN: \n";
 #   foreach my $e (@$IN)
 #     {
#	print "[$e->[0],$e->[1],$e->[2]]\n";
#      } 
#    print "OUT: \n";
#    foreach my $e (@$OUT)
#      {
#	print "[$e->[0],$e->[1],$e->[2]]\n";
#      }
#    print "Tree:\n";
 #   foreach my $e (@{$Tree->getEdges()})
 #     {
	#print "[$e->[0],$e->[1],$e->[2]]\n";
      #}
    
    # Initialize set;
    my $Set = {};
    foreach my $node (@{$Tree->getNodes()})
      {
	$Set->{$node} = $node;
      }
    
    foreach my $edge (@$IN)
      {
	my ($x,$y,$weight) = @$edge;

	if ($Tree->areConnected($x,$y))
	  {
	    Update($Set,$y,$x);
	  }
	else
	  {
	    Update($Set,$x,$y);
	  }
      }
    
    foreach my $edge (@$L)
      {
	my ($x,$y,$weight) = @$edge;
	##print "Analyzing: $x,$y,$weight\n";
	my $isForbidden = grep {EqualEdges($_,$edge) } @$OUT;
	if (!$isForbidden)
	  {
	#    print "X: $x, Y: $y, SetX:", $Set->{$x}," SetY:",$Set->{$y},"\n"; 
	    if (!(($Set->{$x} eq $y) || ($Set->{$y} eq $x)))
	      { 
		if (!$Tree->areConnected($x,$y) && !$Tree->areConnected($y,$x))
		  {
		    my $a;
		    if ($Tree->isAncestor($x,$y))
		      {
			$a = $x;
		      }
		    else
		      {
			if ($Tree->isAncestor($y,$x))
			  {
			    $a = $y;
			  }
			else
			  {
			    # We calculate the common ancestor
			    #print "X: $x\n";
			    #print "Processing X: $x, Y: $y\n";
			    my $parents = $Tree->getParents($x);
			    # print "Parents found\n";
			    if (scalar(@$parents) > 0)
			      {
				$a = $Set->{$parents->[0]};
				while (!$Tree->isAncestor($a,$y) )
				  {
				    $a = $Set->{$Tree->getParents($a)->[0]};
				  }
			      }
			    else
			      {
				# $x is the root, hence it is the common ancestor
				$a = $x; 
			      }
			  }
		      }
		    $a = $Set->{$a};
		#    print "Common ancestor: $a\n";
		    #And climb up to him from $x and $y
		    foreach my $v1 ($x,$y)
		      {
			#print "V1 = $v1\n";
			my $v = $Set->{$v1};
			#print "V = $v\n";
			my $vParent;
			while (!($v eq $a))
			  {
			    
			    $vParent = $Tree->getParents($v)->[0];
			 #   print "VParent: $vParent\n";
			    my $weightSubstracted = $Tree->getEdgeLabel($vParent,$v);
			    my $r1 = $weight - $weightSubstracted;
			    if ($r1 > $r)
			      {
				$r = $r1;
				$e = [$vParent,$v,$weightSubstracted];
				#if ($v1 eq $x)
				#  {
				#    $f = [$x,$y,$weight];
				#  }
				#else
				#  {
				    $f = [$x,$y,$weight];
				#  }
			      }
			    Update($Set,$v,$vParent);
			    $v = $Set->{$v};
			  }
		      }
		  }
	      }
	  }
      }
    my $ex;
    if (defined $e)
      {
	$ex = {};
	$ex->{E} = $e;
	$ex->{F} = $f;
	$ex->{R} = $r;
      }
    else
      {
	$ex = undef;
      }
    return $ex;
  }

sub EqualEdges
  {
    my ($e1,$e2) = @_;
    
    return ((($e1->[0] eq $e2->[0]) && ($e1->[1] eq $e2->[1])) || (($e1->[0] eq $e2->[1]) && ($e1->[1] eq $e2->[0])));
  }

sub CreateNew
  {
    my ($tree,$ex) = @_;

    my $newTree = Durin::DataStructures::UWeightedGraph->new();
    foreach my $edge (@{$tree->getEdges()})
      {
	if (!EqualEdges($edge,$ex->{E}))
	  {
	    $newTree->addEdge($edge->[0],$edge->[1],$edge->[2]);
	  }   
	else
	  {
	 #   print "I do not copy it because:[$edge->[0],$edge->[1],$edge->[2]] and [$ex->{E}->[0],$ex->{E}->[1],$ex->{E}->[2]] are equals\n";
	  }
      }
    my $edge = $ex->{F};
    $newTree->addEdge($edge->[0],$edge->[1],$edge->[2]);
    #print "Tree before we make it directed: \n";
    #foreach my $e (@{$newTree->getEdges()})
    #  {
#	print "[$e->[0],$e->[1],$e->[2]]\n";
#      }
    
    my $WeightedTree = Durin::DataStructures::WeightedGraph->new();
    $newTree->copyDirectedTo($WeightedTree);
    return $WeightedTree;
  }

sub Update
  {
    my ($Set,$son,$father) = @_;
    
    $father = $Set->{$father};
    
    my @keys = keys %$Set;
    
    my $oldSetSon = $Set->{$son};
    foreach my $key (@keys)
      {
	if ($Set->{$key} eq $oldSetSon)
	  {
	    $Set->{$key} = $father;
	  }
      }
  }

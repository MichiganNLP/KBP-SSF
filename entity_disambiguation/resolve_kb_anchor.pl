use strict;
use warnings;
use Data::Dumper;

#sample call
#perl resolve_kb_anchor.pl kb_to_wiki_id/ kb_to_anchor/
#processes all files in kb_to_wiki_id and stores the result in kb_to_anchor

my $input_path = shift @ARGV;
my $output_path = shift @ARGV;

my %anchor = ();
&loadAnchorProbability (\%anchor);

my @files = <$input_path*>;

foreach my $KBfile (@files) {
  my @pieces = split /\//, $KBfile;
  print Dumper \@pieces;
  &mapKBtoAnchor($input_path, pop @pieces, $output_path, \%anchor);
}

sub loadAnchorProbability{
  my ($anchor) = @_;
  open(ANCHOR, "anchor_probability.csv") or die "anchor_probability.csv is not readable.\n" ;
  binmode (ANCHOR, ':utf8') ;
  my $index = 0;		
  while (defined (my $line = <ANCHOR>)) {
    #print $line."\n";
    ++$index;
    chomp($line) ; 
	  if ($line =~ m/^\"(.+)\", (\d+), (\d+(\.\d+)?)$/) {
	    my $text = $1;
	    my $id = $2;
	    my $probability = $3;
	    #print "$text $id $probability\n";
      $anchor->{$id}{$text} = $probability; 
	  } else {
      print "expression not matched\n";
    }
	print $index."\n";
	#if ($index > 100000) {last;}
}
close ANCHOR;
print "Finished loading anchors\n";
}

sub mapKBtoAnchor{
  my ($input_path, $KBfile, $output_path, $anchor) = @_;
  my $filepath = $input_path."$KBfile";
  open(KBTOWIKI, "$input_path/$KBfile") or die "$KBfile is not readable.\n" ;
  binmode (KBTOWIKI, ':utf8');	
  open(KBTOANCHOR, ">$output_path/$KBfile") or die "$KBfile is not readable.\n" ;
  binmode (KBTOANCHOR, ':utf8');	
  while (my $line = <KBTOWIKI>){
    chomp $line;
    if ($line =~ m/^\"(.+)\", (\d+)$/) {
      my $kbID = $1;
      my $wikiID = $2;
      #print Dumper $anchor->{$wikiID};
      foreach my $text (keys %{$anchor->{$wikiID}}){
        print KBTOANCHOR "$kbID,\"$text\",".$anchor->{$wikiID}{$text}."\n";
        #kb id, surface form, probability
      }
      #print "$kbID $wikiID\n";
    } else {
      print "expression not matched\n";
    }
  }
  close (KBTOANCHOR);
  close(KBTOWIKI);
}


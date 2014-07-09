#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Storable qw(nstore);


my $source_path = "kb_to_anchor/";
my @files = <$source_path*>;
print Dumper \@files;

my %kb = ();
foreach my $file (@files){
  open(KB, $file) or die "$file is not readable.\n" ;
  binmode (KB, ':utf8') ;
  while (my $line = <KB>){
    chomp $line;
    if ($line =~ m/^(.+),\"(.+)\",(\d+(\.\d+)?)$/) {
	    my $kbID = $1;
	    my $text = $2;
	    my $probability = sprintf("%.5f", $3); #round to two decimal places
	    $kb{$text}{$kbID} = $probability;
	    $kb{$kbID}{$text} = $probability;
    }
  }    
  close KB;
  #print Dumper \%kb;
}

&saveObject("anchor_to_KB.object",\%kb);
&saveObject("KB_to_anchor.object",\%kb);


exit;

sub saveObject{
  my ($objectFile, $hash) = @_;
  print "Storing the $objectFile object...";
  nstore $hash, $objectFile;
  print " Done! Storing its dump...";
  my $textFile=$objectFile.".txt";
  open OUT,">$textFile";
  print OUT Dumper $hash;
  close OUT;
  print " Done!\n\n";
}

##############################################################
#
#load wikipedia categories
#
##############################################################

sub loadWikiCategories{
  my ($page) = @_;
  print "Loading the category file...";
  my %category = ();
  open(CAT, "categorylink.csv") or die "categorylink.csv is not readable.\n" ;
  binmode (CAT, ':utf8') ;		
  while (defined (my $line = <CAT>)) {
    chomp ($line);
    (my $catID, my $wikiID) = split (/\,/,$line);
    push @{$category{$wikiID}}, $catID;
  }
  close CAT;
  print " Done!\n";
}

sub loadWikiPages{
  my ($page) = @_;
  open(PAGE, "page.csv") or die "page.csv is not readable.\n" ;
  binmode (PAGE, ':utf8') ;		
  my $collisions = 0;
  while (defined (my $line = <PAGE>)) {
   chomp($line) ; 
	  if ($line =~ m/^(\d+),\"(.+)\",(\d+)$/) {
	  	my $id = $1 ;
	    my $title = $2 ;
	  	my $type = $3 ;
	  	if ($type != 1) {next;}					
	    if (exists $page->{$title}) { 
	      ++$collisions; 
	      print $line."\n";
	      print $title," ($id) ", $page->{$title}."\n";
	    }
	  $page->{$title} = $id;
	  }
	}
  close PAGE;
}


##############################################################
#
#load wikipedia surface forms (anchors)
#
##############################################################

print "Loading the anchor file...";
my %anchor = (); #Look up using surface form
my %idLookup = (); #Look up using wikiID

open(ANCHOR, "anchor.csv") or die "anchor.csv is not readable.\n" ;
binmode (ANCHOR, ':utf8') ;		
my $noOfEntities = 0;
while (defined (my $line = <ANCHOR>)) {
  chomp($line) ; 
	if ($line =~ m/^\"(.+)\",(\d+),(\d+)$/) {
	  my $surfaceForm = $1;
	  my $wikiID = $2;
	  my $count = $3;
    $count++; #to make up for the incorrect 0 counts
    $surfaceForm =~ s/\d+//g;
    $surfaceForm =~ s/\s+/ /g;
    $surfaceForm =~ s/\s$//g;
    if ($surfaceForm eq ""){next;}
    $surfaceForm = lc($surfaceForm);
    $anchor{$surfaceForm}{id}{$wikiID}{count} += $count; 
    $anchor{$surfaceForm}{total_count} += $count;
    $idLookup{$wikiID}{surface_form}{$surfaceForm}{count} += $count;
    $idLookup{$wikiID}{total_count} += $count;
    $noOfEntities++;
	}
  if ($noOfEntities % 100000 == 0){
      print $noOfEntities."\n";
  }
}
close ANCHOR;
print " Done!\n\n";


##############################################################
#
#load wikipedia pages
#
##############################################################
print "Loading the wiki pages...";
my %page = ();
&loadWikiPages(\%page);
print " Done!\n\n";

##############################################################
#
#load KB
#
##############################################################
print "Starting loading the KB... ";
my %KB = ();

# create XML object
my $xml = new XML::Simple;

# read XML files
my @KBfiles = <KBP-Resources/KB/data/*>;
foreach my $KBfile (@KBfiles){
  print $KBfile."\n";
  my $data = $xml->XMLin($KBfile);
  foreach my $entry (keys %{$data}) {
    foreach my $entity (keys %{$data->{$entry}}) {
      #entity is the name field under entity in a KB file
          
      my $KBid = $data->{$entry}{$entity}{'id'};
      $KB{$KBid}{'name'} = $entity; #name as it appears in Wikipedia
      $KB{$KBid}{'type'} = $data->{$entry}{$entity}{'type'};
      $KB{$KBid}{'wiki_title'} = $data->{$entry}{$entity}{'wiki_title'};
    if (exists $page{$entity}) {
     $KB{$KBid}{'wiki_id'} = $page{$entity};
    }
   }
  }
}
print "Done processing all KB files!\n\n";


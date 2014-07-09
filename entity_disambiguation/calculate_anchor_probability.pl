#!/usr/bin/perl
use strict;
use warnings;
# use module
use XML::Simple;
use Data::Dumper;
use Storable qw(nstore);
use DB_File;

sub normalize {
  my ($text) = @_;
  $text =~ s/\d+//g;
  $text =~ s/\s+/ /g;
  $text =~ s/\s$//g;
  $text = lc($text);
  return $text;
}

##############################################################
#
#load wikipedia anchors
#
##############################################################

print "Loading the anchor file...";
my $path = "/local/KBP-SSF-2014/entity_disambiguation/";
my $anchor_file = $path."anchor.csv";
my $anchor_probability_file = $path."anchor_probability.csv";
my %anchor = (); #Look up using surface form
my %anchor_count = (); #Look up using surface form

open(ANCHOR, $anchor_file) or die "anchor.csv is not readable.\n" ;
binmode (ANCHOR, ':utf8') ;
my $index = 0;		
while (defined (my $line = <ANCHOR>)) {
  ++$index;
  chomp($line) ; 
	if ($line =~ m/^\"(.+)\",(\d+),(\d+)$/) {
	  my $text = $1;
	  my $id = $2;
	  my $count = $3;
    $count++; #to make up for the incorrect 0 counts
    $text = normalize($text);
    if ($text eq ""){next;}
    $anchor{$text}{$id} += $count; 
    $anchor_count{$text} += $count;
	}
	print $index."\n";
	#if ($index > 100000) {last;}
}
close ANCHOR;
print "Finished loading anchors\n";

open(ANCHOR, ">", $anchor_probability_file) or die "anchor_probability.csv is not readable.\n" ;
binmode (ANCHOR, ':utf8') ;		
foreach my $key (keys %anchor){
  foreach my $id (keys %{$anchor{$key}}) {
   print ANCHOR "\"$key\", $id, ".($anchor{$key}{$id} / $anchor_count{$key})."\n";
 }
}
close(ANCHOR);
print "Finished loading anchors\n";

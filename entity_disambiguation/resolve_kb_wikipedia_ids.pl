#!/usr/bin/perl
use strict;
use warnings;
# use module
use XML::Simple;
use Data::Dumper;
use Storable qw(nstore);
use DB_File;

if (scalar @ARGV != 3){
  print "Incorrect number of parameters specified!\n";
  exit;
} 
print Dumper \@ARGV;
my $input_path = shift @ARGV;
my $KBfile = shift @ARGV;
my $output_path = shift @ARGV;


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
print $KBfile."\n";
open(MAP, ">$output_path/$KBfile") or die "$output_path/$KBfile KB file could not be created.\n" ;
binmode (MAP, ':utf8') ;		
#while (defined (my $line = <PAGE>)) {
#  chomp($line);
#  my $offset = tell(PAGE);
#  if ($line =~ /entity_mention/) {
    
#  }

#}

my $data = $xml->XMLin($input_path."/".$KBfile);
foreach my $entry (keys %{$data}) {
  foreach my $entity (keys %{$data->{$entry}}) {
    if (exists $page{$entity}) {
      #entity is the name field under entity in a KB file      
      my $KBid = $data->{$entry}{$entity}{'id'};
      print MAP "\"$KBid\", ", $page{$entity}."\n";
    }
  }
}
close(MAP);
print "Done processing all KB files!\n\n";

#!/usr/bin/perl
use strict;
use warnings;
# use module
use XML::Simple;
use Data::Dumper;
use Storable;
use File::Basename;
use File::Path qw(make_path);
use File::Find::Rule;

if (scalar @ARGV != 3){
  print "Incorrect number of parameters specified!\n";
  exit;
} 
#print Dumper \@ARGV;

my $input_path = shift @ARGV;
my $output_path = shift @ARGV;
my $kb_file = shift @ARGV;

my $KBref = retrieve($kb_file); #anchor_to_KB

my @folders = File::Find::Rule->directory->in($input_path);

for (my $i = 1; $i < scalar @folders; $i++){
   opendir(DIR, $folders[$i]) or die $!;
   while (my $file = readdir(DIR)) {
     if ($file =~ m/^\./){next;}
     print $file."\n";
     &processFile("$folders[$i]/$file");
   }
   closedir(DIR);
}

my %stopwords = &loadStopWords();


 
 
sub processFile {
  my ($annot_file) = @_;
  
   # read XML files
  my $file_name = basename($annot_file);
  open(IN, "$annot_file") or die "$annot_file is not readable.\n" ;
  binmode (IN, ':utf8') ;	
  make_path("$output_path/$input_path/");	
  open(OUT, ">$output_path/$input_path/$file_name") or die "--$output_path/$input_path/$file_name is not readable.\n" ;
  binmode (OUT, ':utf8') ;		
  my $scanning_mentions = 1;
  my %mentions = ();
  while (defined (my $line = <IN>)) {
   #chomp($line) ; 
    if ($line =~ /\<\/entity\>/) {
       $scanning_mentions = 0;
       my %resolutions = ();
       &resolveMentions(\%mentions, \%resolutions);
       #print Dumper \%mentions; print Dumper \%resolutions;
       print OUT "        <entity_resolution>\n";
       foreach my $mention (keys %resolutions) {
        foreach my $kbid (sort {$resolutions{$mention}{$b} <=> $resolutions{$mention}{$a}} keys %{$resolutions{$mention}}) {
          my $score = ($mentions{$mention} * $resolutions{$mention}{$kbid}) / (scalar (keys %mentions));
          my $rounded = sprintf("%.5f", $score);
          if ($rounded > 0) {
            print OUT "          <resolution PROBABILITY=".'"'.($rounded).'"'.">$kbid</resolution>\n";
          }
        }
       }
     print OUT "        </entity_resolution>\n";
     print OUT $line;
     next;
   }
   print OUT $line;
   if ($line =~ /\<entity /) {
     %mentions = (); #reset
     $scanning_mentions = 1;
     next;
   }
   if ($scanning_mentions && ($line =~ /\<charseq.*?\>(.*?)\<\/charseq\>/)) {
     if (!exists $stopwords{$1}) {
       $mentions{lc($1)}++;
     }
   }
 }
 close(IN);
 close(OUT);
}

#foreach my $annot_file (@annot_files) {
#} 

sub loadStopWords {
	my %stopwords=();
	if (-e "stopwords") { 
	  open STOP, "<", "stopwords";
	  while (my $line=<STOP>) {
	    chomp($line);
	    $stopwords{$line}++;
	  }
	  close STOP;
	}
	return %stopwords;
}

sub GetFileName {
  my ($path) = @_;
  return basename($path);
}

sub resolveMentions {
  my ($mentions, $resolutions) = @_;
  foreach my $mention (keys %{$mentions}) {
    foreach my $kbid (keys %{$KBref->{$mention}}) {
      $resolutions->{$mention}{$kbid} += $KBref->{$mention}{$kbid};
    }
  }
}


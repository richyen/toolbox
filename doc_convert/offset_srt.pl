#!/usr/bin/perl

### A simple script to transpose timestamps for SRT files ###
use Data::Dumper qw(Dumper);
use strict;

sub offset_file {
  my ($filename, $slide_target, $time_target, $begin_slidenum, $end_slidenum) = @_;
  open(my $file, '<', $filename) or die "could not open $filename: $!";
  
  my $slide_offset = $begin_slidenum - $slide_target;
  my $time_offset;
  my $start_writing = 0;
  my $slide_num;
  my $oldstart;
  my $oldend;
  my $text;

  while (<$file>) {
    my $line = $_;
    chomp $line;
    if ($line =~ /^(\d+)$/) {
      $slide_num = $1;
      print Dumper("found a new slide $slide_num");
      if ($slide_num >= $begin_slidenum) {
        $start_writing = 1;
      }
      if ( $slide_num > $end_slidenum ){
        print Dumper("No more processing required");
        close($file);
        return;
      }
    } elsif ($line =~ /^(\d\d:\d\d:\d\d,\d\d\d) --> (\d\d:\d\d:\d\d,\d\d\d)$/) {
      $oldstart = $1;
      $oldend   = $2;
      if ($slide_num == $begin_slidenum) {
        $time_offset = new_timecode($oldstart, $time_target);
      }
      print Dumper("Found a new timecode",$oldstart, $oldend);
    } elsif ($line =~ /^$/) {
      my $new_slidenum = $slide_num - $slide_offset;
      apply_offset($filename, $new_slidenum, $oldstart, $oldend, $time_offset, $text) if $start_writing;
      print Dumper("Flushed to new file");
      $text = '';
    } else {
      print Dumper("Appending text");
      $text .= "$line\n";
    }
  }
  close($file);
  return;
}

sub apply_offset {
  my ($filename, $new_slidenum, $oldstart, $oldend, $time_offset, $text) = @_;
  my $newfilename = $filename;
  $newfilename =~ s/(.*)\.srt/$1_offset.srt/;
  open (my $outfile, '>>', $newfilename) or die "could not open $newfilename";
  print $outfile $new_slidenum . "\n";
  print $outfile new_timecode($oldstart, $time_offset) . " --> " . new_timecode($oldend, $time_offset) . "\n";
  print $outfile $text;
  print $outfile "\n";
  close($outfile);
}

sub new_timecode {
  my ($t, $o) = @_;
  my $t_ms = convert_to_milliseconds($t);
  my $o_ms = convert_to_milliseconds($o);
  print Dumper("$t_ms - $o_ms");
  return convert_to_timecode($t_ms - $o_ms);
}

sub convert_to_milliseconds {
  my $t = shift;
  $t =~ /(\d\d):(\d\d):(\d\d),(\d\d\d)/;
  my ($h,$m,$s,$ms) = ($1,$2,$3,$4);
  return $ms + ($s * 1000) + ($m * 60 * 1000) + ($h * 60 * 60 * 1000);
}

sub convert_to_timecode {
  my $t = shift;
  my $h    = int ($t / (60 * 60 * 1000)) || 0;
  my $m_ms = $t % (60 * 60 * 1000);
  my $m    = int ($m_ms / (60 * 1000)) || 0;
  my $s_ms = $m_ms % (60 * 1000);
  my $s    = int ($s_ms / 1000) || 0;
  my $ms   = $s_ms % 1000;
  return sprintf("%02d:%02d:%02d,%03d",$h,$m,$s,$ms);
}

sub main {
  my ($filename, $slide_target, $time_target, $begin_slidenum, $end_slidenum) = @ARGV;
  offset_file($filename, $slide_target, $time_target, $begin_slidenum, $end_slidenum);
}

main();

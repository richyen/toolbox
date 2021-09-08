#!/usr/bin/perl

#This script extracts events from an iCal .ics format file
#Output is a tab-separated file with the format:
#Monthname <tab> Day <tab> Description of Event
use strict;

my $filename = $ARGV[0];

print "opening $filename...";
open('FILE',"+<",$filename);
print "$filename opened\n";
open('OUT','>','file.txt');

my @monthnames = qw(January February March April May June July August September October November December);
my $array = {};
my $event_found = 0;
my $date_found = 0;
my ($year,$month,$day);
while(<FILE>) {
	if ($_ =~ /^BEGIN:VEVENT/) {
		$event_found = 1;
		print "event found...";
		next;
	}
	if ($_ =~ /DTSTART/ && $event_found) {
		$_ =~ /(\d{4})(\d{2})(\d{2})/;
		($year,$month,$day) = ($1,$2,$3);
		$date_found = 1;
		print "date found: ".int($month)." ".int($day)."...";
		next;
	}
	if ($_ =~ /^SUMMARY:(.*)/ && $date_found && $event_found) {
		$array->{int($month) - 1}->{int($day) - 1} = $1;
		print "$1\n";
		$date_found = 0;
		$event_found = 0;
		next;
	}
}
foreach (0 .. 11) {
	my $m = $_;
	my $mon = $array->{$m};
	foreach my $d (sort {$a <=> $b} keys %$mon) {
		my $string = $mon->{$d};
		print OUT $monthnames[$m] . "\t" . ($d + 1) . "\t" . $string . "\n";
	}
}

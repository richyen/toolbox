#!/usr/bin/perl
use strict;
open (my $file, '<', 'text.txt');

my @arr;
my $stack = '';
my $first_time = 1;

while (<$file>) {
    if ($_ =~ /^\-\-\-\+\+\ /xms) {
        push @arr, $stack;
        if ($first_time) {
            $first_time = 0;
        } else {
            $stack = $_;
        }
    } else {
        $stack .= $_;
    }
}
close ($file);

foreach my $r (reverse @arr) {
    print $r;
}

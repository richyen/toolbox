#!/usr/bin/perl

use strict;
use Spreadsheet::WriteExcel;
use Data::Dumper qw(Dumper);

main(shift, shift);

sub main {
    my $threshold = shift;
    my $filename = shift;
    if (!defined $threshold || !defined $filename) {
        print STDERR "Usage: $0 <threshold> <filename>\n";
        exit;
    }
    print Dumper "Beginning conversion of $filename";
    open (my $fh, '<', $filename);
    $filename =~ s/\..*?$//;
    my $counter = 0;
    my $file_counter = 1;
    my $header = [];
    my $ss = [];
    while (<$fh>) { #gather
        my $line = $_;
        chomp $line;
        next if $line !~ /\|/;
        $line =~ s/^ +(\S)/$1/g;
        $line =~ s/ +\| +/|/g;
        my @data = split '\|', $line;
        if (scalar @$header == 0) {
            $header = \@data;
        }
        push @$ss, \@data;
        $counter++;
        if ($counter % ($threshold + 1) == 0) { #flush
            my $save_name = sprintf('%s_%02d.xls', $filename, $file_counter++);
            print Dumper "Preparing to write $save_name";
            my $workbook = Spreadsheet::WriteExcel->new($save_name);
            my $worksheet = $workbook->add_worksheet();
            $worksheet->write_col(0, 0, $ss);
            $workbook->close();
            print Dumper "Saved $save_name";
            $ss = [ $header ]; #reset
        }
    }
    if (scalar @$ss > 0) {
        my $save_name = sprintf('%s_%02d.xls', $filename, $file_counter++);
        print Dumper "Preparing to write $save_name";
        my $workbook = Spreadsheet::WriteExcel->new($save_name);
        my $worksheet = $workbook->add_worksheet();
        $worksheet->write_col(0, 0, $ss);
        $workbook->close();
        print Dumper "Saved $save_name";
    }
    close($fh);
    print Dumper "Conversion complete";
}

#!/usr/bin/perl

use strict;

### A script to remove stray .ready files in a PG instance.
### pg_archivecleanup will remove WAL files, but .ready files
### can be orphaned, as in the case of one client

# Get PGDATA
my $pgdata = shift;
die "Usage: $0 /path/to/pgdata" if !defined $pgdata;

# Get version
open my $file, '<', "$pgdata/PG_VERSION";
my $ver = <$file>;
close $file;

# Use version to determine name of WAL dir
my $waldir = int($ver) >= 10 ? "$pgdata/pg_wal" : "$pgdata/pg_xlog";

# Construct archive_status dir
my $archive_status = "$waldir/archive_status";

# Read archive_status dir
opendir(DIR,$archive_status);

while (my $f = readdir(DIR)) {
  # Only work with .ready files
  next unless $f =~ /^(0.*)\.ready$/;
  my $walfile = $1;
  if (-e "$waldir/$walfile") {
    print STDOUT "File $walfile exists, skipping $f\n";
  } else {
    # Delete .ready file only if corresponding WAL file does not exist
    print STDOUT "File $walfile does not exist, deleting $f\n";
    unlink("$archive_status/$f") or warn "Can't unlink $f: $!";
  }
}

# Done
closedir(DIR);

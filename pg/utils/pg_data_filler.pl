#!/usr/bin/perl
use strict;
use DBI;
use DBD::Pg;
use Data::Dumper qw(Dumper);
use Switch;

our $DEBUG = 0;
our $NUMROWS = 1000;

### Fill a table with random data
## TODO:
## - Handle all user tables in a database
## - Build internal map of foreign key relationships and ensure FK integrity when generating data
## - Use multiple threads/processes when inserting data, and group by FK dependencies

sub main {
  my ($tab_name) = @ARGV;
  $DEBUG && print Dumper($tab_name);
  chomp $tab_name;
  my $tab_cols = tab_cols(get_tab_oid($tab_name));
  $DEBUG && print Dumper($tab_cols);
  my $inserts = build_insert_statements($tab_name, $tab_cols);
  my $retval = do_inserts($inserts);
  print Dumper($retval);
}

### Utility Functions
## Get table OID
sub get_tab_oid {
  my $tab_name = shift;
  $tab_name =~ s/"//g;
  $tab_name =~ /(.*)\.(.*)/;
  my $schema = $1 || 'public';
  my $relname = $2 || $tab_name;
  $DEBUG && print Dumper([$tab_name,$schema,$relname]);
  my $query = "SELECT c.oid FROM pg_class c JOIN pg_namespace n ON (c.relnamespace = n.oid) WHERE n.nspname = '$schema' AND c.relname = '$relname' AND relkind = 'r'";
  my $raw = execute_query($query);
  $DEBUG && print Dumper($raw);
  return $raw->[0]->[0];
}

## Get columns of table
sub tab_cols {
  my $tab_oid = shift;
  my $query = "SELECT attname, attnum, format_type(t.oid,atttypmod) AS atttype FROM pg_attribute a JOIN pg_type t ON t.oid=a.atttypid WHERE attrelid = $tab_oid AND attnum > 0 ORDER BY attnum";
  my $table_def = execute_query($query);
  $DEBUG && print Dumper($table_def);
  return $table_def;
}

## Generate random data based on data type and constraints
sub build_insert_statements {
  my ($tab_name, $tab_cols) = @_;
  my ($cols, $typs) = ([],[]);
  foreach my $tab_col (@$tab_cols) {
    my ($attname, $attnum, $atttype) = (@$tab_col);
    push @$cols, "\"$attname\"";
    push @$typs, $atttype;
  }
  my $colstring = join ',', @$cols;
  my $rows = bulk_generate($typs);
  my $statements = [];
  foreach my $r (@$rows) {
    my $valstring = join ',', @$r;
    push @$statements, "INSERT INTO $tab_name ($colstring) VALUES ($valstring)";
  }
  return $statements;
}

sub bulk_generate {
  my $typs = shift;
  my $rows = [];
  for (1 .. $NUMROWS) {
    my $row = generate_values($typs);
    while (!ensure_unique($row,$rows,[0..scalar(@$typs)-1])) {
      print STDERR "Regenerating values\n";
      $row = generate_values($typs);
    }
    push @$rows, $row;
  }
  return $rows;
}

sub generate_values {
  my $typs = shift;
  my $vals = [];
  foreach my $typ (@$typs) {
    push @$vals, generate_data($typ);
  }
  return $vals;
}

sub ensure_unique {
  my ($row, $rows, $cols) = @_;
  foreach my $i (@$cols) {
    foreach my $r (@$rows) {
      if ($r->[$i] eq $row->[$i]) {
        print Dumper("Not unique", $r->[$i], $row->[$i], $i);
        return 0;
      }
    }
  }
  return 1;
}

sub generate_data {
  my $type = shift;
  $type =~ /(.*)\((.*)\)/;
  my $type_name = $1 || $type;
  my $constraint = $2 || 'unconstrained';
  my $data;

  $DEBUG && print Dumper($type);
  switch ($type_name) {
    case /char/              {
                               $data = "'".random_string($constraint)."'";
                             }
    case /int/               {
                               $data = int(rand(( ( 2 ** 31 ) - 1 ))); # Cast bigints into ints for now
                             }
    case 'numeric'           {
                               my ($p,$s) = split ',', $constraint;
                               die "Bad data type $type, $type_name, $constraint" if !defined $p || !defined $s;
                               my $n1 = random_number($p - $s);
                               my $n2 = $s == 0 ? '' : '.' . random_number($s);
                               $data = "$n1$n2";
                             }
    else                     { die "Type $type_name not handled"; }
  }
  $DEBUG && print Dumper($data);
  return $data;
}

sub random_number {
  my $digits = shift;
  my @numbers = (0..9);
  return join '', (map { $numbers[rand @numbers]} @numbers)[1..$digits];
}

sub random_string {
  my $strlen = shift;
  my @alphanumeric = ('a'..'z', 'A'..'Z', 0..9);
  return join '', (map { $alphanumeric[rand @alphanumeric]} @alphanumeric)[1..$strlen];
}

sub do_inserts {
  my $inserts = shift;
  my $num_inserted = 0;
  my $dbh = connect_to_database();
  eval {
    foreach my $i (@$inserts) {
      $dbh->do($i) or die $dbh->errstr;
      $num_inserted++;
    }
  };
  if ($@) {
      my $error = $@;
      print STDERR "$error\n";
      $dbh->rollback();
  } else {
      $dbh->commit();
      print STDOUT "successfully inserted all $num_inserted rows to database\n";
  }
  $dbh->disconnect();
  return $num_inserted;
}

sub execute_query {
  my $query = shift;
  my $dbh = connect_to_database();
  my $sth = $dbh->prepare($query);
  $sth->execute() or die $dbh->errstr;
  my $rows = $sth->fetchall_arrayref();
  $sth->finish();
  $dbh->disconnect();
  return $rows;
}

sub connect_to_database {
    my $dbh;
    my $dbname = 'edb';
    my $dbhost = '127.0.0.1';
    my $dbuser = 'enterprisedb';
    my $dbpass = 'abc123';
    print STDOUT "attempting to connect to database with dbname=$dbname and dbhost=$dbhost\n";
    eval {
        # catch connection errors (i.e., pg_hba.conf misconfiguration)
        $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;user=$dbuser;password=$dbpass") or die DBI->errstr;
    };
    $dbh->{AutoCommit} = 0;
    if ($@) {
        my $error = $@;
        print STDERR "$error\n";
    } else {
        print STDOUT "successfully connected to database\n";
    }
    return $dbh;
}

main();

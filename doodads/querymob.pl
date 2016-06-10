#!/usr/local/perl/bin/perl

use DBI;
use strict;

use constant NUM_CHILDREN => 125;
use constant NUM_LOOPS => 5;

main();

sub main {
    my $process = $$;
    open(OUT,">>","pool.log");
    print OUT "process $$ starting\n";
    close(OUT);
    for (1 .. NUM_CHILDREN) {
        my $pid = fork;
        if ($pid != $$ && $pid != 0) { #report results
            open(OUT,">>","pool.log");
            print OUT "$$ spawns $pid\n";
            close(OUT);
        }

        if ($pid == 0) { #only children do processing
            for (1 .. NUM_LOOPS) {
                my $dbh;
                eval {
                    my $time1 = time;
                    $dbh = connect_to_db() or die "could not connect";
                    my $time2 = time;
                    my $total = $time2 - $time1;
                    open(OUT,">>","pool.log");
                    print OUT "time to acquire handle: $time2 - $time1 = $total\n";
                    close(OUT);
                };
                if ($@) {
                    open(OUT,">>","pool.log");
                    print OUT "died: $@\n";
                    close(OUT);
                }

                open(OUT,">>","pool.log");
                print OUT "Child $$ iteration number $_ starting\n";
                close(OUT);
                my $sth = $dbh->prepare(SQL_QUERY());
                $sth->execute();
                $sth->finish();
                $dbh->disconnect();
            }
            last; #no grandchildren
        }
    }
}

sub connect_to_db {
    my $dbname = '';
    my $dbhost = '';
    my $dbuser = '';
    my $dbpass = '';
    my $dbport = 9900;
    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;user=$dbuser;password=$dbpass;port=$dbport");
    $dbh->{AutoCommit} = 0;
    return $dbh;
}

sub SQL_QUERY {
    my $random_number = int(rand()*1000000);
    my $random_number2 = int(rand()*1000000);
		my $table = '';
    return "select * from $table where id between $random_number AND $random_number2 ORDER BY id DESC";
}

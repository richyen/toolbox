#!/usr/bin/perl

#This script attempts to rename all files files with ALL CAPS to no caps
#ALL CAPS phenomenon occurs when copying data from a Windows (FAT/NTFS) filesystem
&rename_directory('.');
sub rename_directory{
	my $homedir = shift;
	print "performing rename on directory $homedir\n";
	opendir(DIR,$homedir);
	foreach(readdir(DIR)){
		next if ($_ =~ /\.{1,2}$/) || (($_ =~ /[a-z]/) && !(-d $_));
		&rename_directory("$homedir/$_") if (-d "$homedir/$_");
		print "renaming $_ to ".lc($_)."\n";
		#rename("$homedir/$_","$homedir/".lc($_));
	}
	closedir(DIR);
}

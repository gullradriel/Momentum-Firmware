#!/usr/bin/perl
use strict;
use warnings;
use File::Find;

# Path to the header file containing macros
my $macro_file = 'furi/core/check.h';

# Array to store macro names
my @macros;

# Read macro names from the file, exclude those starting with '_'
open my $macro_fh, '<', $macro_file or die "Cannot open '$macro_file': $!\n";
while (my $line = <$macro_fh>) {
    chomp $line;
    # Match macro definitions like '#define NAME' (excluding those starting with '_')
    if ($line =~ /^\s*#\s*define\s+(\w+)\s*\(/g && $1 !~ /^_/) {
        push @macros, $1;
    }
}
close $macro_fh;

# Debugging output to see the macros extracted
print "Macros found: ", join(", ", @macros), "\n" if @macros;

# If no valid macros are found, exit
if (@macros == 0) {
    die "No valid macros found in $macro_file.\n";
}
my $macrolist=join("|",@macros);
# Define the regular expressions to match different assignment cases
my $regex_eq  = qr/.*\((?!.*(\+=|\-=|==|!=|>=|<=)).*=.*\)/;  # Matches '=' but not '=='
my $regex_pls = qr/.*\(.*\+=.*\)/;  # Matches '+='
my $regex_min = qr/.*\(.*\-=.*\)/;  # Matches '-='

my $ret = 0 ;

# Subroutine to process each file
sub process_file {
    # Only process .c and .h files
    return unless /\.(c|h)$/;

    open my $fh, '<', $_ or die "Cannot open file '$_': $!\n";
    my $line_num = 0;

    while (my $line = <$fh>) {
        $line_num++;
        # Check each macro
        if ($line =~ qr/$macrolist/) {
            if ($line =~ $regex_eq) {
                print "Bad assignment as expression found in $File::Find::name at line $line_num (assignment '=') for $line";
                $ret = 1 ;
            }
            elsif ($line =~ $regex_pls) {
                print "Bad assignment as expression found in $File::Find::name at line $line_num (assignment '+=') for $line";
                $ret = 1 ;
            }
            elsif ($line =~ $regex_min) {
                print "Bad assignment as expression found in $File::Find::name at line $line_num (assignment '-=') for $line";
                $ret = 1 ;
            }
        }
    }
close $fh;
}

# Start the recursive search
find(\&process_file, "applications/");
find(\&process_file, "furi/");
find(\&process_file, "lib/");
find(\&process_file, "targets/");

exit $ret ;

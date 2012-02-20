#!/usr/bin/perl -w
#    $0 [-v] watbun_filename
# e.g. $0 ar009.2618
#
# -Ian! D. Allen - idallen@idallen.ca - www.idallen.com

# ar001.0254 760812 ccng.doc/doreen/predict 
# ar097.0513 831223 racornale/brlp2 (incomplete file)

use strict;
use Getopt::Std;

my $USAGE = "usage: $0 [-v] arnum.filenum";
our($opt_v);
&getopts('v') || die $USAGE;

$opt_v = '-v' if $opt_v;
$opt_v = '' unless $opt_v;

my $fileno = shift or die;

# tape number is at start of $fileno
my ($tape) = $fileno =~ /^(ar\d+)/;
die "$0: cannot parse '$fileno'\n" unless defined $tape;
# remove leading zeroes from tape number
$tape =~ s/ar0+/ar/;
# see if the file exists
my $f = "Archive/$tape/$fileno";
if ( ! -s $f ) {
    die "missing $f\n";
}

exec("./a.out $opt_v <$f");

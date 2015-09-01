#!/usr/bin/perl
# Aug 14, 2014
# This updates a variable in a Perl source code file. The line
# that is updated must contain "SUBVER=n" where N is any number
# of digits. The file is copied to a production dir, then SUBVER
# is incremented in the test directory source .pl file.
#
# LOG


=pod

=head1 SYNOPSIS

F<updver.pl>

Copy test program to production, THEN update SUBVER in .pl file.

=head1 LIMITATIONS

=head1 LOG

11/17/2014 Put all backups in subdir 'backup'.

7/21/2015 Copy program first, then update SUBVER.

9/1/2015 Fixed bug where backup file wasn't getting copied to 'backup/' subdir.


=cut

use warnings;
use strict;
require '/home/chuck/perl/util2.pl';
my($s);
use Fcntl; # Needed by SDBM_File
use SDBM_File;
use Data::Dumper;

$s="File::Copy";
eval("use $s;");
if ($@)
    {
    die "$0: ERROR: $s not installed.\n";
    }

my ($USERNAME)=$ENV{USER};
use Text::Wrap;
my $columns=65;
$columns=65;

# For time use $s=localtime();
########## Variables ##########
our(@lin);
my($DEBUGDETAIL);
my($INFILE,$ERRFILE,$lpos,$lcnt,$outfn,$SEP);
my($pcnt,$errcnt,$zpos);
my(@a,@b,@k,@l,$d,$i,$j,$k,$lin,$t,$z,$maxwrit,@written);
my($page);
my($errfile,$fn,$fnbak);
my($day,$mo,$hr,$min,$year,$sec,$perldate,$sqldate,$donedir);
my($dir,$oldn,$newn);

$pcnt=0; # Count of items processed.
$SEP=chr(9); # chr(9)=tab.

my $SUBVER=3; # Update this.
my $VER="v2015-0831.".sprintf("%03d",$SUBVER);

########## Begin main ##########
print "\n"; # print blank line to separate warning messages from our messages.
if (!(defined($ARGV[1])))
    {print "$VER Usage: perl $0 file.pl /copy/to/this/dir/\n";
    $s='';
    $s.="\n";
    print wrap('','',$s);
    print "Current Perl version: $^V\n";

    print "\n";
    exit;
    }


$fn=$ARGV[0]; # Source file.
if (! -e $fn)
    {
    $s="$0 ERROR: Couldn not find file $fn.";
    debugpr($s);
    exit 1;
    }
# if (!-t $fn) # Check if file opened. Shows always open.
#     {
#     $s="$0 ERROR: File $fn is open. Please close it and try again.";
#     debugpr($s);
#     exit 1;
#     }

#$fnbak=`pwd`.'/backup/'.$fn.'.upd'.getfulldatetime();
$fnbak='backup/'.$fn.'.upd'.getfulldatetime();
$dir=$ARGV[1]; # Destination dir.
if (! -e $dir)
    {
    $s="$0 ERROR: Could not find dir $dir.";
    debugpr($s);
    exit 1;
    }
if (! -d $dir)
    {
    $s="$0 ERROR: $dir is not a directory.";
    debugpr($s);
    exit 1;
    }
$dir='./backup';
if (! -e $dir)
    {
    $s="$0 ERROR: Could not find dir $dir.";
    debugpr($s);
    exit 1;
    }

copy($fn,$fnbak) or die "$0: ERROR from copy(). Could not copy $fn to $fnbak: $!.";
print "Copied $fn to $fnbak\n";

$outfn=$ARGV[1].'/'.$fn;
copy($fn,$outfn) or die "$0: ERROR from copy(). Could not copy $fn to $outfn: $!.";
print "Copied $fn to $outfn. \n";


# Open original filename.
open ($INFILE,$fn) or die "$0: ERROR on open.() Could not open $fn: $!.";
@lin=<$INFILE>;
chomp(@lin);
close($INFILE);

my $found=0;
for ($i=0; $i<=$#lin; $i++)
    {
    $lin=$lin[$i];
    if ($lin=~m/\$SUBVER=(\d+)/)
        {
        $oldn=$1;
        $newn=$oldn+1;
        copy($fn,$dir); # Copy old file to dir
        $lin=~s/=$oldn/=$newn/;
        $lin[$i]=$lin; # Replace old line.
        $i=$#lin; # exit loop
        $found=1;
        }
    } # for i

if ($found==0) # If SUBVER not found
    {
    $s="$0 ERROR: SUBVER not found in $fn";
    debugpr($s);
    exit 2;
    }
# Now write out .pl file again.
$outfn='>'.$fn;
open(OUTFILE, $outfn) or die "$0: could not open $outfn for writing. $!";
foreach $t (@lin)
    {
    writeln($t);
    } # foreach
close(OUTFILE);

print "OLDVER=$oldn, NEWVER=$newn\n";

#$outfn=$ARGV[1].'/'.$fn;
#copy($fn,$outfn) or die "$0: ERROR from copy(). Could not copy $fn to $outfn: $!.";
#print "Copied $fn to $outfn. \nOLDVER=$oldn, NEWVER=$newn\n";

print "\n";
exit; # Main program
########################################################################
sub debugpr
{my($l)=@_;

print "DBG $l\n";

return; # debugpr
}
###########################################################################
# In: string to write
# Out: writes to log.txt
# This writes an entry to log.txt with several fields. The fields are
# sep by tabs and are: date and time<TAB>program file and ver<TAB>
# Text from $txt.
sub logentry
{my($txt)=@_;
my(@a,@b,$i,$j,$procname,$s,$t);
my($dt,$tfn);

$procname="logentry";

$txt=~s/\n//g;
$tfn="log.txt";
if (!(-e $tfn))
	{
	$outfn=">".$tfn;
	open LOGFILE, $outfn || die "Could not open $outfn.\n $!";
	@a=("Date","Program","Msg");
	@a=(@a,"Not fnd");
	$s=join($SEP,@a);
	print LOGFILE "$s\n";
	close(LOGFILE);
	}
$outfn = ">>".$tfn;
open LOGFILE, $outfn || die "Could not open $outfn.\n $!";
my($min,$hr,$day, $month, $year) = (localtime)[1,2,3,4,5];
$month = sprintf '%02d', $month+1;
$day   = sprintf '%02d', $day;
$dt= ($year+1900).'-'.$month.$day;
$dt.=" ".sprintf("%02d",$hr).":".sprintf("%02d",$min);
@a=($dt,$0.' '.$VER,$txt);
$s=join($SEP,@a);
print LOGFILE "$s\n";
close(LOGFILE);

return; # logentry
}
########################################################################
sub writeerr
{my($l)=@_;

print $ERRFILE "$l\n";
print "$l\n";

return; # writeerr
}
########################################################################

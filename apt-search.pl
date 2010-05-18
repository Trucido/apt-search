#!/usr/bin/perl

use strict;
use warnings;
use IO::Handle;
use Getopt::Long;
use Term::ANSIColor qw(:constants);
use Pod::Usage;
use Glib qw(TRUE FALSE);
use vars qw($VERSION $NAME $ID);

# $Format:Git ID: (%h) %ci$
$NAME    = "apt-search.pl";
$VERSION = "Beta 0815";

my (
    $help,    $man, $show,      $remove,  $install,
    $version, $new, $installed, $compact, $update
   ) = FALSE;
my @result;
my ($count, $flag) = undef;
my @size = split(/ /, qx(stty size));

sub version ()
{

    #$VERSION = join(' ', (split(' ', $ID))[1 .. 3]);
    #$VERSION =~ s/,v\b//;
    #$VERSION =~ s/(\S+)$/($1)/;
    die ' ', $VERSION, "\n\n";
}

GetOptions(
    'help|h'      => \$help,
    'man'         => \$man,
    'version'     => \$version,
    'new|N'       => \$new,
    'installed|I' => \$installed,
    'compact|c'   => \$compact,
    'show|s'      => \$show,
    'update|u'    => \$update,
    'install'     => \$install,
    'remove'      => \$remove,

          ) or pod2usage(-verbose => 0);

&version() if $version;
pod2usage(-verbose => 1) if $help;
pod2usage(-verbose => 2) if $man;
&show($ARGV[0]) if $show;

#pod2usage("$0: No packages given.") if ((@ARGV == 0) and not ($new == TRUE));
&update()           if $update;
&install('install') if $install;
&install('remove')  if $remove;

$flag = "'~n @ARGV'";
$flag = "'~N @ARGV'" if $new;
$flag = "~n *" if (@ARGV == 0) and not $new;

&print() if not $show;

sub print ()
{
    my $flag_color;
    @result =
      qx(aptitude -F "%s§%p§%V§%C§%A§%v§%a§%d" --disable-columns search $flag);
    foreach (@result)
    {
        my @a = split(/§/, $_);

        if ($a[6] ne " ")
        {
            $flag_color = RESET ' [', BOLD RED $a[6], RESET '] ', RESET;
        }
        else
        {
            $flag_color = BOLD GREEN ' * ', RESET;
        }

        if ($a[3] eq "installed")
        {
            print $flag_color, BOLD GREEN "$a[1]", RESET;
        }
        else
        {
            next if $installed;
            print $flag_color, BOLD "$a[1]", RESET;
        }

        if (!$compact)
        {
            print GREEN "\n\tVersions:", RESET "\t$a[2]\n";
            print GREEN "\tStatus:",     RESET "\t\t$a[3]";
            print " version: $a[5]" if $a[5] ne "<none>";
            print GREEN "\n\tAction:", RESET "\t\t$a[4]\n" if $a[4] ne "none";

            print GREEN "\n\tSection:",     RESET "\t$a[0]";
            print GREEN "\n\tDescription:", RESET "\t$a[7]\n";
        }
        else
        {
            print BOLD " $a[2]: ", RESET "$a[7]";

        }
        $count++;
    }
    if (@result)
    {
        print "Found " . $count . " matches.\n" if $count > 1;
    }
    else
    {
        print "No matches found.\n";
    }
}

sub show ()
{
    my ($pack) = @_;
    @result = qx(aptitude -q show $pack );

    foreach my $line (@result)
    {
        chomp($line);
        if ($line =~ /(.*?): (.*)/mg)
        {

            print GREEN "$1", RESET ":\r", RESET "\t\t\t$2\n";
        }
        else
        {
            print "\t\t\t$line\n";
        }
    }
}

sub update ()
{
    my ($line, $col);

    # system (@args);
    #  (@args) = qx(aptitude -q update );# or die "bla";
    $col = RESET;
    open(FOO, "aptitude -q update 2>&1 | ");

    while (<FOO>)
    {
        my $match = FALSE;
        chomp;
        $line = $_;

        if ($line =~ /(Hit )(http.*)/mg)
        {
            $col   = GREEN;
            $match = TRUE;
        }
        elsif ($line =~ /(Ign )(http.*)/mg)
        {
            $match = TRUE;
            $col   = RED;
        }
        elsif ($line =~ /(Get:[0-9]) (http.*)/mg)
        {
            $match = TRUE;
            $col   = BLUE;
        }
        elsif ($line =~ /(W: )(.*)/mg)
        {
            $match = TRUE;
            $col   = BOLD YELLOW;
        }

        print $col, "$1\r", RESET, "\t$2\n", RESET if $match;

        # else
        print "$line\n" if not $match;

        #}
    }
    close FOO;
    exit;
}

#print " " x ($size[1] - 5) , "Done\n";

sub install ($)
{
    my ($cmd) = @_;
    my ($line, $i);
    my $col = RESET;
    my $pid = open(KID_TO_READ, "aptitude $cmd @ARGV |");
    my (@tmp, @args);
    my @url;
    if ($install)
    {
     @tmp =  qx(apt-get -qq --print-uris install @ARGV);
     $i=0;
     foreach (@tmp)
        {
          chomp;
        @url = split(/ /,$_);
        next if not $url[0];
       print "$url[0] $url[1]\n";

       print "\n>>> Downloading (", BOLD YELLOW, $i, RESET,' of ', BOLD YELLOW,
       ( $#tmp + 1 ), RESET,  ")", BOLD GREEN,
       $ARGV[$i],RESET,"\n\n";
        @args = (
       "wget", $url[0],  
       "-c -t 5 -T 60 --passive-ftp",  
       "-O /var/cache/apt/archives/$url[1]");

        qx(@args);
        $i++;
   }
   # exit;    

    }
    
    if ($pid)
    {
      #gg KID_TO_READ->autoflush(1);
      # select KID_TO_READ; | = 1;

        while (<KID_TO_READ>)
        {
            my $match = FALSE;
            chomp;
            $line = $_;

            if ($line =~ /(.*\.\.\.)$/)
            {
                $match = TRUE;
                $col = BOLD BLUE, '[ ', BOLD GREEN, 'Done', BOLD BLUE ' ]',
                  RESET;
            }

            print BOLD GREEN ' * ', RESET, "$1",
              " " x ($size[1] - 11 - length($1)), $col, "\n", RESET
              if $match;
            print ">>> $line\r\n" if not $match;
        }
    close KID_TO_READ;
}
else
{    # child
        #  ($EUID, $EGID) = ($UID, $GID); # suid only
    exec("aptitude  $cmd @ARGV")
      || die "can't exec program: $!";

    exit;

     }
exit;
 }

sub process_one_line
{
    my $line = shift @_;
    print "$line\n";
}

__END__

=head1 NAME

apt-serch.pl colors your aptitude search request. 

=head1 VERSION

Beta 0815

=head1 AUTHOR

Sascha Bartuweit, E<lt>ir0n1e@freenet.deE<gt>.

=head1 COPYRIGHT

This program is distributed under GPLv2.

=head1 DESCRIPTION

B<apt-search.pl> colors aptitude search request.
The output of B<apt-search.pl> is similar to eix.

=head1 SYNOPSIS

B<apt-search.pl> 
[B<-help>] 
[B<-man>] 
[B<-version>] 
[B<package(s)>]

=head2 EXAMPLES

=over 2 

=item B<Serch package (Default)>

apt-search.pl <package>

=back

=cut

=head1 ARGUMENTS

=over 4

=item B<-u, -update>

Updates the list of available packages from the apt sources.

=item B<-I, -installed>

Shows installed packages.

=item B<-s, -show>

Shows detailed package informations.

=item B<-h, -help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-version>

Prints version.

=back

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2010 Sacha Bartuweit 'Ir0n1E' <ir0n1e@freenet.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=head1 DATE

Mai 18, 2010 09:44:05

=cut

# vi:ts=4:sw=4:ai:expandtab 

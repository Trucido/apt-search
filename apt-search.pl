#!/usr/bin/perl

use strict;
use warnings;

#use IO::Handle;
use IO::Pipe;
use IO::Prompt;
use Getopt::Long qw(:config no_ignore_case bundling);
use Term::ANSIColor qw(:constants);
use Pod::Usage;
use Glib qw(TRUE FALSE);
use POSIX ":sys_wait_h";

use vars qw($VERSION $NAME $ID);

$NAME = "apt-search.pl";
$ID   = q(Id: $Format:%t %ai %an$);

my (
    $help,    $man, $show,      $remove,  $install,
    $version, $new, $installed, $compact, $update
   ) = FALSE;
my @result;
my ($count, $flag) = undef;
my @size = split(/ /, qx(stty size));

sub version ()
{

    $VERSION = join(' ', (split(' ', $ID))[1 .. 3]);
    $VERSION =~ s/,v\b//;
    $VERSION =~ s/(\S+)$/($1)/;
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
    'install|i'   => \$install,
    'remove|r'    => \$remove,

          ) or pod2usage(-verbose => 0);

&version() if $version;
pod2usage(-verbose => 1) if $help;
pod2usage(-verbose => 2) if $man;
&show($ARGV[0]) if $show;

pod2usage("$0: No packages given.")
  if (    (@ARGV == 0)
      and not $show
      and not $update
      and not $installed
      and not $new);
&update()           if $update;
&install('install') if $install;
&install('remove')  if $remove;

$flag = "'~n @ARGV'";
$flag = "'~N @ARGV'" if $new;
$flag = "~n *" if (@ARGV == 0) and not $new;

&print() if not $show;

sub print ()
{
    my $count = 0;
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
            $flag_color = BOLD GREEN '  *  ', RESET;
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
            print RESET, '(', BOLD GREEN, $a[2], RESET, '): ', $a[7];

        }
        $count++;
    }
    print "Found " . $count . " matches.\n";    #if $count > 1;
}

sub show ()
{
    my ($pack) = @_;
    @result = qx(aptitude -q show $pack );

    foreach my $line (@result)
    {
        chomp($line);
        next if &check_error($line);
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

        next if &check_error($line);
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

        if ($line =~ /(.*\.\.\.)$/)
        {

            #$match = TRUE;
            $col = BOLD BLUE, '[ ', BOLD GREEN, 'Done', BOLD BLUE ' ]', RESET;
            print BOLD GREEN ' * ', RESET, "$1",
              " " x ($size[1] - 11 - length($1)), $col, "\n", RESET;
            next;
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

my $spin = TRUE;

sub install ($)
{
    my ($cmd) = @_;
    my ($size, $i, $x) = 0;
    my $col = RESET;
    my (@tmp,  @args, $match);
    my (@url,  $line, $yes, @flags);
    my (@list, @wget, @pkg);
    my $s_pid = fork();
    my $aptstring;
    if ($install || $remove)
    {
        $aptstring = 'autoremove' if $remove;
        $aptstring = 'install' if $install;

        if ($s_pid)
        {
            print GREEN,
              "\nThese are the packages that would be ". $aptstring."d, in order:",
              RESET, "\n\n";
            print "Calculating dependencies  ";
            my $check;
            do
            {
                $check = waitpid($s_pid, WNOHANG);
                &spinner();

            } until (($check));    # or ($count > 25));
        exit if $?;
            my $string = BOLD WHITE,
          "\n\nWould you like to $aptstring these packages?",
          RESET, " [", BOLD GREEN, "Yes", RESET, "/", BOLD RED, "No", RESET,
          "] ";
        if (!prompt($string, -tyn1s => 0.8))
        {
            print "\nQuitting.\n";
            exit;
        }
        }
        elsif (defined $s_pid)
        {
            @list = qx(apt-get -qq --print-uris install @ARGV 2>&1) if $install;
            @tmp  = qx(apt-get -qq --dry-run $aptstring  @ARGV 2>&1);
            my ($l, @p);
            if (@tmp)
            {

                ($i, $x) = 0;
                foreach (@tmp)
                {
                    chomp;

                    #$flags = undef;
                    next if &check_error($_);
                    chomp(@url = split(/ /, $_));
                    next if ($url[0] =~ /Conf.*/);
                    next if not $url[0];
                    $p[$i] = '^' . $url[1] . '$';
                    $url[2] =~ s/[\(\)]//;

                    $flags[$i] .= BOLD GREEN "I";
                    $pkg[$i] = BOLD GREEN, $url[1], RESET, "-$url[2]";
                    foreach (@list)
                    {
                        chomp;
                        my @l   = split(/ /, $_);
                        my @pck = split(/_/, $l[1]);
                        if ($url[1] eq $pck[0])
                        {
                            $flags[$i] .= BOLD YELLOW "D";
                            $size += $l[2];
                            $wget[$x++] = "$l[0]§$l[1]§$url[1]\n";
                        }

                    }

                    $i++;
                }

                $i = 0;

                my @size = qx(aptitude -F "%D" search @p);

                foreach (@pkg)
                {
                    chomp($size[$i]);
                    $line .= RESET "[  ", $flags[$i], RESET,
                      "  ] $pkg[$i] $size[$i] \n";
                    $i++;
                }

            }
                else 
                {
                    print "\bDone\n";
                    print STDERR "Nothing to $aptstring\n";
                    exit(1);
                }
            open FILE, ">/tmp/$0_db.txt" or die $!;
            print FILE @wget;
            close FILE;
            print "\bDone\n";
            print $line;
            printf(
                "\nTotal: %s Packages, Downloads: %s, Size of Downloads: %.3f kB\n",
                ($i),
                ($#wget + 1),
                ($size / 1024)
            );
            exit();
        }


        if (-e '/tmp/' . $0 . '_db.txt')
        {
            print "yes\n";
            my $dl;
            open FILE, "</tmp/$0_db.txt" or die $!;

            $dl++ while <FILE>;
            close FILE;

            open FILE, "</tmp/$0_db.txt" or die $!;
            $i = 0;
            foreach (<FILE>)
            {
                chomp;
                my @url = split(/§/, $_);
                print "\n>>> Downloading (", BOLD YELLOW, $i++, RESET, ' of ',
                  BOLD YELLOW,
                  $dl, RESET, ") ", BOLD GREEN,
                  $url[2], RESET, "\n\n";
                @args = (
                         "wget", $url[0],
                         "-c -t 5 -T 60 --passive-ftp",
                         "-O /var/cache/apt/archives/$url[1]"
                        );

                qx(@args);    # or die $!;

            }
            close FILE;

            #unlink ("/tmp/$0_db.txt");
        }
    }
    my $pid = open(KID_TO_READ, "-|");
    $| = 1;
    my $buffer;
    if ($pid)
    {
        while (sysread(KID_TO_READ, $line, 64_000) > 0)
        {
            $col = RESET;

            chomp($line);

            #$line = $_;
            $match = FALSE;
            chomp(my $buffer = $line);
            next if &check_error($buffer);
            if ($buffer =~ /(.*\.\.\.)$/)
            {
                $match = TRUE;

                #print "TREU\n";
                $col = BOLD BLUE, '[ ', BOLD GREEN, 'Done', BOLD BLUE ' ]',
                  RESET;
            }
            if ($buffer =~ /.* \.\.\./)
            {
                $col = ">>> ";
            }

            if ($buffer =~ /.*Reading database.*/)
            {
                print "\t$buffer\r", RESET;
                next;
            }

            print "\n", BOLD GREEN ' * ', RESET, "$1",
              " " x ($size[1] - 11 - length($1)), "$col"
              if $match;

            if (length($buffer) > 1)
            {
                print "\n", $col, " ", $buffer if not $match;
            }
            $| = 1;
        }
        print "\n";
        close KID_TO_READ;
    }
    else
    {    # child
            #  ($EUID, $EGID) = ($UID, $GID); # suid only
        exec("aptitude  -q $cmd @ARGV 2>&1") || die "can't exec program: $!";
        exit;

    }
    exit;
}

sub check_error ()
{
    my ($line) = @_;
    my $colo   = '';
    my $match  = FALSE;

    if ($line =~ /(W:\s)(.*)/mg)
    {
        $match = TRUE;
        $colo = BOLD YELLOW " * ", RESET "$2\n";
    }
    elsif ($line =~ /(E:\s)(.*)/mg)
    {
        $match = TRUE;
        $colo = BOLD RED, " * ", RESET, "$2\n";
    }
    if ($match)
    {
        $| = 1;
        my $es = $2;

        #$es =~ s/[\n|\s]+//g;
        print "$colo\n";
        return TRUE;
    }
}

sub root ()
{
    my $col = BOLD RED, ' * ';
    print STDERR $col, RESET,
      "Nothing was executed, because a heuristic shows that root permissions \n",
      RESET;
    print STDERR $col, RESET,
      "are required to execute everything successfully.\n", RESET;

    exit;
}
{
    my $i;

    sub spinner ()
    {
        $| = 1;
        my %spinner = (
                       '|'  => '/',
                       '/'  => '-',
                       '-'  => "\\",
                       "\\" => '|'
                      );

        $i = (!defined $i) ? '|' : $spinner{$i};

        #print $string;
        print "\b$i";
    }
}

__END__

=head1 NAME

apt-serch.pl colors your aptitude search request. 

=head1 VERSION

$Format:%t %ai %an$

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
[B<-compact>]
[B<-installed>]
[B<-compact>]
[B<package(s)>]

B<apt-search.pl> 
[B<-help>] 
[B<-man>] 
[B<-version>] 
[B<-remove|install|show>] 
[B<package(s)>]

B<apt-search.pl> 
[B<-help>] 
[B<-man>] 
[B<-version>] 
[B<-update>] 

=head2 EXAMPLES

=over 2 

=item B<Serch package (Default)>

apt-search.pl <package>

=item B<List all installed packages>

apt-search.pl -I -c

=back

=cut

=head1 ARGUMENTS

=over 4

=item B<-c, -compact>

Shows package information in one line.

=item B<-remove>

Removes a package.

Installs a package.

=item B<-install>

Installs a package.

=item B<-N, -new>

Prints all new packages in the packages list.

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

Mai 20, 2010 16:58:00

=cut

# vi:ts=4:sw=4:ai:expandtab 

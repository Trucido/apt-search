#!/usr/bin/perl

use Getopt::Long qw(:config no_ignore_case bundling);
use Term::ANSIColor qw(:constants);
use Pod::Usage;
use Glib qw(TRUE FALSE);
use POSIX ":sys_wait_h";

use FindBin qw($RealBin);
use lib $RealBin;

use Functions;

use strict;
use warnings;

use vars qw($VERSION $NAME $ID);

$NAME = "apt-search.pl";
$ID   = q(Id: $Format:%t %ai %an$);

my (
    $help, $man,       $show,    $remove, $install, $version,
    $new,  $installed, $compact, $update, $upgrade
   ) = FALSE;
my @result;
my ($count, $flag) = undef;

sub version ()
{

    $VERSION = join(' ', (split(' ', $ID))[1 .. 3]);
    $VERSION =~ s/,v\b//;
    $VERSION =~ s/(\S+)$/($1)/;
    die ' ', $VERSION, "\n\n";
}

GetOptions(
    'help|h'  => \$help,
    'man'     => \$man,
    'version' => \$version,
    'new|N'   => \$new,

    'upgrade|u'   => \$upgrade,
    'installed|I' => \$installed,
    'compact|c'   => \$compact,
    'show|s'      => \$show,
    'sync'        => \$update,
    'i|install'   => \$install,
    'r|remove'    => \$remove,

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
      and not $new
      and not $upgrade);
&update()           if $update;
&install('install') if $install;
&install('remove')  if $remove;


&print(FALSE) if not $show;

sub print ($)
{
    my ($sync) = @_;
    my ($flag_color, $pkg_string);
    my $count = 0;

    $flag = "'~n @ARGV'";
    $flag = "'~N @ARGV'" if $new;
    $flag = "~n " if (@ARGV == 0) and not $new;

    @result =
        qx(aptitude -F "%s§%p§%V§%C§%A§%v§%a§%d" --disable-columns search $flag 2>&1);

    foreach (@result)
    {
        my $match = FALSE;
        my ($inst, $nor, $act) = FALSE;
        my $buffer;
        my @a = split(/§/, $_);

        next if check_error(@a);

        if (@a)
        {
            my $version_string = $a[2];

            if (!$compact)
            {
                $buffer .= GREEN "\n\tVersions:", RESET "\t$a[2]\n";
                $buffer .= GREEN "\tStatus:",     RESET "\t\t$a[3]";
                $buffer .= " version: $a[5]" if $a[5] ne "<none>";
                $buffer .= GREEN "\n\tAction:", RESET "\t\t$a[4]"
                  if $a[4] ne "none";

                $buffer .= GREEN "\n\tSection:",     RESET "\t$a[0]";
                $buffer .= GREEN "\n\tDescription:", RESET "\t$a[7]\n\n";
            }
            else
            {
                $buffer = ' (' . $version_string . '): ' . $a[7];
            }

            if ($a[3] eq "installed")
            {
                $inst = TRUE;
                $pkg_string = BOLD GREEN $a[1], RESET;

                if ($a[2] gt $a[5])
                {
                    $match = TRUE;
                    $version_string = RESET $a[5] . ' -> ', CYAN $a[2], RESET;
                    $flag_color = RESET ' [', BOLD CYAN 'U', RESET '] ', RESET;

                }
                elsif ($a[2] lt $a[5])
                {
                    $match          = TRUE;
                    $version_string = RESET $a[5] . ' -> ', CYAN $a[2], RESET;
                    $flag_color     = RESET ' [', BOLD MAGENTA 'D', RESET '] ',
                      RESET;

                }
                else
                {
                    $flag_color = RESET ' [', BOLD GREEN 'I', RESET '] ', RESET;
                }
            }
            else
            {
                $version_string = $a[2];
                $pkg_string     = BOLD WHITE $a[1], RESET;
                $flag_color     = BOLD GREEN '  *  ', RESET;

                if ($a[6] ne " ")
                {
                    $match = TRUE;
                    $flag_color = RESET ' [', BOLD RED $a[6], RESET '] ', RESET
                      if $a[6] ne " ";

                }
            }

            if ($installed && $upgrade)
            {
                if ($inst && $match)
                {
                    print_info($flag_color . $pkg_string . $buffer . "\b");
                    $count++;
                    next;
                }
            }
            elsif ($installed)
            {
                if ($inst)
                {
                    print_info($flag_color . $pkg_string . $buffer . "\b");
                    $count++;
                    next;
                }
            }
            elsif ($upgrade)
            {
                if ($match)
                {
                    print_info($flag_color . $pkg_string . $buffer . "\b");
                    $count++;
                    next;
                }
            }
            else
            {
                print_info($flag_color . $pkg_string . $buffer . "\b");
                $count++;
            }
        }
    }
    print_info("New Packages: " . $count) if $sync;    
    print_info("Found " . $count . " matches.") if not $sync;    #if $count > 1;
}

sub show ()
{
    my ($pack) = @_;
    @result = qx(aptitude -q show $pack 2>&1);

    foreach my $line (@result)
    {
        chomp($line);
        
        next if check_error($line);
        
        $line =~ s/^\s//g;
        
        if ($line =~ /(.*?): (.*)/mg)
        {
            my $inf = $2;
            $inf =~ s/^\s//g;

            print_info(GREEN "$1", RESET ":\r"."\n\t\t\t$inf");
        }
        else
        {
            print_info("\t\t\t$line");
        }
    }
}

sub update ()
{
    my ($line, $color, $inf_line, $string);

    check_root();

    $color = RESET;
    open(UPDATE, "aptitude -q update 2>&1 | ");

    while (<UPDATE>)
    {
        my $match = FALSE;
        chomp;
        $line = $_;

        next if check_error($line);
        if ($line =~ /(Hit )(http.*)/mg)
        {
            $color   = GREEN $1, RESET;
            $match = TRUE;
        }
        elsif ($line =~ /(Ign )(http.*)/mg)
        {
            $match = TRUE;
            $color   = RED $1, RESET;;
        }
        elsif ($line =~ /(Get:[0-9]\+) (http.*)/mg)
        {
            $match = TRUE;
            $color   = BLUE $1, RESET;
        }

        if ($line =~ /(.*\.\.\.)$/)
        {
            print_ok($1);
            next;
        }
        $inf_line = $color."\t$2";
        print_info($inf_line) if $match;

        print_info("$line") if not $match;

    }
    close UPDATE;
    $new = TRUE;
    &print(TRUE);
    exit;
}

#print " " x ($size[1] - 5) , "Done\n";

sub install ($)
{

    check_root();
    my ($cmd) = @_;

    my ($size, $i, $x) = 0;
    my $col = RESET;
    my (@tmp,      $match);
    my (@url_list, $line, $yes, @flags);
    my (@wget,     @pkg_version);
    my $s_pid;
    my $aptstring;

    my ($l, @p);
    my @pkg_list;
        $aptstring = 'remove' if $remove;
        $aptstring = 'install'    if $install;
    @tmp = qx(apt-get -qq --dry-run $aptstring  @ARGV 2>&1);
    
    foreach (my @a = qx(apt-get  --dry-run $aptstring  @ARGV 2>&1))
    {
        if (check_error($_))
        {
            color_apt("apt-get --dry-run $aptstring", \@ARGV);
            exit;
        }
    
    }

        if ($s_pid = fork())
        {

            print GREEN "\n".'These are the packages that would be '
              . $aptstring
              . "d, in order:\n\n", RESET 'Calculating dependencies  ';

            @url_list = qx(apt-get -qq --print-uris install @ARGV 2>&1) if $install;
            @tmp = qx(apt-get -qq --dry-run $aptstring  @ARGV 2>&1);
            
            if (@tmp)
            {
                ($i, $x) = 0;
                foreach (@tmp)
                {
                    chomp;

                    next if check_error($_);
                    
                    chomp(my @string = split(/ /, $_));
                    
                    next if not $string[0] or ($string[0] =~ /Conf.*/);
                    
                    $pkg_list[$i] = $string[1];
                    $p[$i]        = '^' . $string[1] . '$';
                    $string[2] =~ s/[\[\]\(\)]//g;

                    $flags[$i] .= BOLD GREEN "N" if ($string[0] =~ /^Inst.*/);
                    $flags[$i] .= BOLD RED "R" if ($string[0] =~ /^Rem.*/);
                    $pkg_version[$i] = BOLD GREEN, $string[1], RESET,
                      "-$string[2]";

                    foreach (@url_list)
                    {
                        chomp;
                        my @l   = split(/ /, $_);
                        my @pkg = split(/_/, $l[1]);
                        if ($string[1] eq $pkg[0])
                        {
                            $flags[$i] .= BOLD YELLOW "D";
                            $size += $l[2];
                            $wget[$x++] = "$l[0]§$l[1]§$string[1]\n";
                        }

                    }

                    $i++;
                }
                $i = 0;
                my @size = qx(aptitude -F "%D" search @p 2>&1);

                foreach (@pkg_version)
                {
                    chomp($size[$i]);
                    $line .= RESET "[", BOLD YELLOW 'package ', RESET $flags[$i], RESET,
                      "  ] $pkg_version[$i] $size[$i] \n";
                    $i++;
                }

            }
            else
            {
                print "\bDone\n";
                print_warn("Nothing to $aptstring\n");

                kill('SIGTERM', $s_pid);
                exit(1);
            }
            kill('SIGTERM', $s_pid);
            print_info("\bDone\n\n$line") if $line;
            printf(
                "\n\nTotal: %s Packages, Downloads: %s, Size of Downloads: %.3f kB\n",
                ($i),
                ($#wget + 1),
                ($size / 1024)
            );

            ask_user("Would you like to $aptstring these packages?");
        }
        elsif (defined $s_pid)
        {
            spinner();
            exit();
        }
        if (@wget)
        {
            $i = 1;
            foreach (@wget)
            {
                chomp;
                my @url = split(/§/, $_);
                print "\n>>> Downloading (", BOLD YELLOW, $i++, RESET, ' of ',
                  BOLD YELLOW,
                  ($#wget + 1), RESET, ") ", BOLD GREEN,
                  $url[2], RESET, "\n\n";
                my @args = (
                            "wget", $url[0],
                            "-c -t 5 -T 60 --passive-ftp",
                            "-O /var/cache/apt/archives/$url[1]"
                           );

                qx(@args);
            }

        }
        color_apt("aptitude -y $aptstring",\@ARGV);

    exit;
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
[B<--help>] 
[B<--man>] 
[B<--version>] 
[B<--compact>]
[B<--installed>]
[B<--compact>]
[B<package(s)>]

B<apt-search.pl> 
[B<--help>] 
[B<--man>] 
[B<--version>] 
[B<--remove|install|show>] 
[B<package(s)>]

B<apt-search.pl> 
[B<--help>] 
[B<--man>] 
[B<--version>] 
[B<--update>] 

=head2 EXAMPLES

=over 2 

=item B<Serch package (Default)>

apt-search.pl <package>

=item B<List all installed packages>

apt-search.pl -Ic

=back

=cut

=head1 ARGUMENTS

=over 4

=item B<-c, -compact>

Shows package information in one line.

=item B<-remove>

Removes a package.

Installs a package.

=item B<--install>

Installs a package.

=item B<-N, --new>

Prints all new packages in the packages list.

=item B<-u, --update>

Updates the list of available packages from the apt sources.

=item B<-I, --installed>

Shows installed packages.

=item B<-s, --show>

Shows detailed package informations.

=item B<-u, --update>

Shows all packages with aktive aktion Flag.

=item B<-h, --help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--version>

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

Mai 26, 2010 06:09:16

=cut
# vi:ts=4:sw=4:ai:expandtab 

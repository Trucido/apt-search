NAME
    apt-serch.pl colors your aptitude search request.

VERSION
    $Format:%t %ai %an$

AUTHOR
    Sascha Bartuweit, <ir0n1e@freenet.de>.

COPYRIGHT
    This program is distributed under GPLv2.

DESCRIPTION
    apt-search.pl colors aptitude search request. The output of
    apt-search.pl is similar to eix.

SYNOPSIS
    apt-search.pl [--help] [--man] [--version] [--compact] [--installed]
    [--compact] [package(s)]

    apt-search.pl [--help] [--man] [--version] [--remove|install|show]
    [package(s)]

    apt-search.pl [--help] [--man] [--version] [--update]

  EXAMPLES
    Serch package (Default)
      apt-search.pl <package>

    List all installed packages
      apt-search.pl -Ic

ARGUMENTS
    -c, -compact
        Shows package information in one line.

    -remove
        Removes a package.

        Installs a package.

    --install
        Installs a package.

    -N, --new
        Prints all new packages in the packages list.

    -u, --update
        Updates the list of available packages from the apt sources.

    -I, --installed
        Shows installed packages.

    -s, --show
        Shows detailed package informations.

    -u, --update
        Shows all packages with aktive aktion Flag.

    -h, --help
        Print a brief help message and exits.

    --man
        Prints the manual page and exits.

    --version
        Prints version.

LICENCE AND COPYRIGHT
    Copyright (C) 2010 Sacha Bartuweit 'Ir0n1E' <ir0n1e@freenet.de>

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2 of the License, or (at your
    option) any later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
    Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

DATE
    Mai 22, 2010 23:50:48


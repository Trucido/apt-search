apt-serch.pl: colors your aptitude search requests  
    with output similar to the gentoo commands:  
    ``emerge --search`` and ``eix``  
  
Forked on May 7, 2017 since the original author has not updated it and was is missing a proper readme for dependencies and installation.   
  
Dependencies:  
    •perl (Seems to still work with perl 5.24)  
    •Functions.pm (included in src directory)  
    •Other perl stuff? When I find any other deps I'll update this readme  
  
Installation:  
    •Simply copy both apt-search.pl and Functions.pm to a directory in your PATH such as ~/bin/ or /usr/local/bin/  
    •chmod +x apt-search.pl as well.  
  
Usage:  
    •See below, but the script will work without any arguments also.  
    •Syntax is similar to ``eix``  
  
Other info:  
    •This script will show virtual packages, as well as real ones.  
    •Since it has not been updated in quite some time, be careful using any functionality it might have that could write or modify data on your system.  
   
TODO:  
    •Write most of this in a proper readme and man page  
    •Find all required dependencies  
    •Fix the formatting slightly, since it seems to add some extra unnecessary empty lines between search items.  
    
Updated example image:
![alt text](https://cloud.githubusercontent.com/assets/5420611/25785451/a6687020-334e-11e7-947d-ed22bb6c76d8.png)

====================== Original README.md below: ==========================

[![Alt text for your video](https://img.youtube.com/vi/RCsjAzDWPW0/0.jpg)](https://www.youtube.com/watch?v=RCsjAzDWPW0)

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


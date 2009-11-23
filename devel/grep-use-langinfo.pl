#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Perl6::Slurp;
use File::Locate::Iterator;

use FindBin;
my $progname = $FindBin::Script;

my $verbose = 0;

my $it = File::Locate::Iterator->new (globs => [# '*.t',
                                                '*.pm',
                                                '*.pl',
                                                #'/usr/lib/perl/5.10.1/I18N/Langinfo.pm'
                                               ]);
print "$progname: $it->{'regexp'}\n";
my $count = 0;

while (defined (my $filename = $it->next)) {
  open my $in, '<', $filename or next;
  if ($verbose) { print "$filename\n"; }
  $count++;

 OUTER: for (;;) {
    my $line = <$in> // last;
    if ($line =~ /use I18N::Langinfo(;|\s+[0-9])/) {

      for (;;) {
        $line = <$in> // last OUTER;
        if ($line =~ /(I18N::Langinfo::)?langinfo\s*\(/ && ! $1) {
          print "$filename:$.:1:\n  $line";
          last;
        }
      }
    }
  }
  close $in or die;
}
print "count $count\n";
exit 0;

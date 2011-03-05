#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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

# egrep -nH -ire '[^[a-z-]-[a-ln-z0-9][a-z0-9]*::' /usr/share/perl/5.10
# /usr/share/perl/5.10/Math/Complex.pm:712:	    -CORE::exp(CORE::log(-$z)/3) :
# /usr/share/perl/5.10/Math/Complex.pm:1043:	my $v = -CORE::log($alpha + CORE::sqrt($alpha*$alpha-1));


# XML::RSS::TimingBot \cm\cj lower case

use 5.005;
use strict;
use warnings;
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;
use Text::Tabs ();

my $verbose = 0;

my $l = MyLocatePerl->new;
while (my ($filename, $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }

  # if ($str =~ /^__END__/m) {
  #   substr ($str, $-[0], length($str), '');
  # }

  # strip comments
  #  $str =~ s/#.*//mg;

  while ($str =~ /((^|[^>A-Za-z])\w+
                    ([ \t]*(\#[^\n]*)?\n)+
                    [ \t]*=>
                  )/sgx) {
    my $pos2 = pos($str);
    my $pos = $pos2 - length($1);

    my ($line, $col) = MyStuff::pos_to_line_and_column ($str, $pos);
    my $s1 = MyStuff::line_at_pos($str, $pos);
    my $s2 = MyStuff::line_at_pos($str, $pos2);

    # substr($s,0,$col) =~ /q[qx]|"/ or next;

    print "$filename:$line:$col:\n$s1$s2";
  }
}

exit 0;

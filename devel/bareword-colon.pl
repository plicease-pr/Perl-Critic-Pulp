#!/usr/bin/perl

# Copyright 2010 Kevin Ryde

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


use strict;
use warnings;

sub make {
  return "make: @_";
}

{
  package Math;
  sub Complex { return "foo"; }
}
{
  my $c = make Math::Complex 1, 2;
  print $c,"\n";
}
require Math::Complex;
{
  my $c = make Math::Complex:: 3,4;
  print $c,"\n";
}

print $Math::{'Complex::'},"\n";
print $Math::{Complex::},"\n";

{
  package Foo::Bar::Quux;
  sub blah { return "blah"; }
}
print $Foo::{'Bar::Quux::'}||'undef',"\n";
print $Foo::Bar::{'Quux::'},"\n";
print $Foo::Bar::{'Quux'}||'undef',"\n";

#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements;
use Test::More tests => 18;
use Perl::Critic;

my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'ValuesAndExpressions::ProhibitNullStatements');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitNullStatements');
}

my $want_version = 14;
ok ($Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements::VERSION >= $want_version, 'VERSION variable');
ok (Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements->VERSION  >= $want_version, 'VERSION class method');
Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements->VERSION($want_version);


foreach my $data (## no critic (RequireInterpolationOfMetachars)
                  [ 1, ';' ],
                  [ 1, 'use Foo;;' ],
                  [ 1, 'if (1) {};' ],
                  [ 0, 'for (;;) { }' ],
                  [ 0, 'map {; $_, 123} @some_list;' ],
                  [ 0, 'map { ; $_, 123} @some_list;' ],
                  [ 0, 'map { # fdjks
                              ; $_, 123} @some_list;' ],
                  [ 1, 'map {;; $_, 123} @some_list;' ],
                  [ 1, 'map { ; ; $_, 123} @some_list;' ],
                  [ 1, 'map { ; # fjdk
                              ; $_, 123} @some_list;' ],
                  [ 0, 'grep {# this is a block
                              ;
                              length $_ and $something } @some_list;' ],
                  ## use critic
                 ) {
  my ($want_count, $str) = @$data;
  {
    my @violations = $critic->critique (\$str);
    foreach (@violations) {
      diag ($_->description);
    }
    my $got_count = scalar @violations;
    is ($got_count, $want_count, "str: $str");
  }
}


{ my ($p) = $critic->policies;
  $p->{'_allow_perl4_semihash'} = 1;
}
foreach my $data ([ 0, ';# a comment' ],
                  [ 0, "\n;# a comment" ],
                  [ 1, '  ;# but only at the start of a line' ],
                  [ 1, '; # no whitespace between' ],
                 ) {
  my ($want_count, $str) = @$data;
  {
    my @violations = $critic->critique (\$str);
    foreach (@violations) {
      diag ($_->description);
    }
    my $got_count = scalar @violations;
    is ($got_count, $want_count, "str: $str");
  }
}


exit 0;

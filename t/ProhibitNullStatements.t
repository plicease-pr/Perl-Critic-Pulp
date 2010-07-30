#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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


use 5.006;
use strict;
use warnings;
use Test::More tests => 22;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements;


#-----------------------------------------------------------------------------
my $want_version = 41;
is ($Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements::VERSION, $want_version, 'VERSION variable');
is (Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements->VERSION, $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements$');
my @policies = $critic->policies;
is (scalar @policies, 1, 'single policy ProhibitNullStatements');

my $policy = $policies[0];
ok (eval { $policy->VERSION($want_version); 1 },
    "VERSION object check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { $policy->VERSION($check_version); 1 },
    "VERSION object check $check_version");

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


$policy->{'_allow_perl4_semihash'} = 1;

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

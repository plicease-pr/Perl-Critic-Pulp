#!/usr/bin/perl

# Copyright 2010 Kevin Ryde

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
use Test::More tests => 18;

BEGIN {
 SKIP: { eval 'use Test::NoWarnings; 1'
           or skip 'Test::NoWarnings not available', 1; }
}

require Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon;

#-----------------------------------------------------------------------------
my $want_version = 37;
is ($Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon::VERSION, $want_version, 'VERSION variable');
is (Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon->VERSION, $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'ValuesAndExpressions::ProhibitBarewordDoubleColon');

{ my @p = $critic->policies;
  is (scalar @p, 1,
     'single policy ProhibitBarewordDoubleColon');

  my $policy = $p[0];
  is ($policy->VERSION, $want_version, 'VERSION object method');
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

my $policy = ($critic->policies)[0];

foreach my $data (## no critic (RequireInterpolationOfMetachars)

                  [ 1, 'my $x = Foo::' ],
                  [ 1, 'my $x = Foo::Bar::' ],
                  [ 0, 'my $x = FooBar' ],
                  [ 0, 'my $x = Foo::Bar' ],

                  [ 0, 'my $x = "Foo::"' ],
                  [ 0, 'my $x = \'Foo::\'' ],

                  # barewords in hash keys are subject to the same rules
                  [ 1, '$x{Foo::}' ],

                  [ 0, 'new Foo:: 1,2,3', {_allow_indirect_syntax => 1} ],
                  [ 1, 'new Foo:: 1,2,3', {_allow_indirect_syntax => 0} ],

                  ## use critic
                 ) {
  my ($want_count, $str, $options) = @$data;
  $policy->{'_allow_indirect_syntax'} = 0; # default

  my $name = "str: '$str'";
  foreach my $key (keys %$options) {
    $name .= " $key=$options->{$key}";
    $policy->{$key} = $options->{$key};
  }

  my @violations = $critic->critique (\$str);
  foreach (@violations) {
    diag ($_->description);
  }
  my $got_count = scalar @violations;
  is ($got_count, $want_count, $name);
}

exit 0;

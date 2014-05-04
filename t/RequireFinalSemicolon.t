#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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
use Test::More tests => 68;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon;

#-----------------------------------------------------------------------------
my $want_version = 83;
is ($Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon::VERSION, $want_version, 'VERSION variable');
is (Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon->VERSION, $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
     'single policy RequireFinalSemicolon');

  my $policy = $p[0];
  is ($policy->VERSION, $want_version, 'VERSION object method');
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (# no critic (RequireInterpolationOfMetachars)

                  [ 0, "map { \$x\n } \@y" ],
                  [ 0, "map {; q{a},1\n } \@y" ],
                  [ 0, "map {; q{a},1,q{b},2\n } \@y" ],

                  [ 0, "return \\ { a=>2 \n }" ], # ref to hashref

                  [ 0, "{ a => 1 \n}" ], # hash constructor
                  [ 1, "{ a,1 \n}" ],     # code block
                  [ 1, "{; a => 1 \n}" ], # code block

                  # hashrefs
                  [ 0, "\{ a => 1\n}" ],
                  [ 0, "\$x = { 1 => 2\n}" ],
                  [ 0, "\$x = \\{ a=>2,a=>2\n}" ], # ref to hashref

                  [ 0, "Foo->new({ %args,\n})" ],
                  [ 0, "foo({ %args,\n })" ],
                  [ 1, "sub { %args,\n}" ],
                  [ 1, "sub foo { %args,  \n }" ],
                  [ 0, "\$x = { %args,  \n }" ],
                  [ 0, "bless { 1 => 2\n}, \$_[0];" ],

                  # the prototype on first() is not recognised, as yet
                  [ 0, "List::Util::first { 123,\n } \@args" ],

                  [ 0, 'sub foo' ],
                  [ 0, 'sub foo { }' ],
                  [ 0, "sub foo {\n}" ],
                  [ 0, "do {\n}" ],
                  [ 0, "do {\n} while(1)" ],
                  [ 0, "sub foo {;}" ],
                  [ 0, "sub foo {;\n}" ],
                  [ 0, "sub foo {;\n__END__" ],
                  [ 0, "BEGIN {}" ],
                  [ 0, "BEGIN {\n}" ],
                  [ 0, "BEGIN { MYLABEL: { print 123 }\n}" ],
                  [ 0, "sub foo { if (1) { print; }\n}" ],
                  [ 0, "sub foo { while (1) { print; }\n}" ],
                  [ 0, "sub foo { until (1) { print; }\n}" ],
                  [ 0, "sub foo { if (1) { print; } else { print; }\n}" ],
                  [ 0, "sub foo { if (1) { print 1; } elsif (2) { print 2; }\n}" ],
                  [ 0, "sub foo { return bless { 1 => 2\n}, \$_[0] }" ],
                  [ 0, "sub foo { \$x = bless { 1 => 2\n}, \$_[0] }" ],
                  [ 0, "sub foo { \$x = { 1 => 2\n} }" ],
                  [ 0, "grep { defined\n } \@y" ],
                  [ 1, "sub { defined\n }" ],

                  [ 0, "sub foo { 123 }" ],
                  [ 0, "sub foo { 123; }" ],
                  [ 0, "sub foo { 123;\n}" ],
                  [ 1, "sub foo { 123\n}" ],
                  [ 1, "sub foo { 123 # x \n }" ],
                  [ 0, "sub foo { return 123;\n}" ],
                  [ 1, "sub foo { return 123\n}" ],
                  [ 0, "sub foo { return {};\n}" ],
                  [ 1, "sub foo { return {}\n}" ],
                  # unterminated
                  [ 1, "sub foo { 123" ],
                  [ 1, "sub foo { 123 # x" ],

                  [ 0, "do { 123 }" ],
                  [ 0, "do { 123\n}" ],
                  [ 0, "do { 123 # x \n }" ],
                  # unterminated
                  [ 0, "do { 123" ],
                  [ 0, "do { 123 # x" ],

                  [ 0, "do { 123 } until (\$condition)" ],
                  [ 1, "do { 123\n} until (\$condition)" ],
                  [ 1, "do { 123 # x \n } until (\$condition)" ],

                  [ 0, "do { 123 } while (\$condition)" ],
                  [ 1, "do { 123\n} while (\$condition)" ],
                  [ 1, "do { 123 # x \n } while (\$condition)" ],

                  ## use critic
                 ) {
  my ($want_count, $str) = @$data;

  my @violations = $critic->critique (\$str);

  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: $str");

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ($_->description);
    }
  }
}

exit 0;

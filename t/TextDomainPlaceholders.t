#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

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
use Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders;
use Test::More tests => 23;
use Perl::Critic;

my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'Miscellanea::TextDomainPlaceholders');
{ my @p = $critic->policies;
  is (scalar @p, 1);
}

ok ($Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders::VERSION >= 8);
ok (Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders->VERSION  >= 8);


foreach my $data (## no critic (RequireInterpolationOfMetachars)
                  [ 0, '__x("")' ],
                  [ 0, '__x(\'\')' ],
                  [ 0, '__x(\'{foo}\', foo => 123)' ],
                  [ 0, '__x(\'{foo}\', \'foo\' => 123)' ],
                  [ 0, '__x(\'{foo}\', "foo" => 123)' ],

                  [ 1, '__x(\'{foo}\')' ],
                  [ 1, '__x(\'\', foo => 123)' ],
                  [ 2, '__x(\'{foo}\', bar => 123)' ],

                  [ 1, '__x(\'$x\', foo => 123)' ],
                  [ 0, '__x("$x", foo => 123)' ],

                  [ 0, '__x(\'{foo}\', $x => 123)' ],
                  [ 1, '__x(\'{foo}\', $x => 123, bar => 456)' ],

                  [ 0, '__x(<<HERE, foo => 123)
{foo}
HERE' ],
                  [ 1, '__x(<<HERE, foo => 123)
{foo} {bar}
HERE' ],
                  [ 0, '__x(<<HERE, foo => 123)
$x
HERE' ],
                  [ 1, '__x(<<\'HERE\', foo => 123)
$x
HERE' ],

                  [ 0, '__x(\'{foo}\' . \'{bar}\',
                            foo => 123, bar => 456)' ],

                  [ 1, 'Locale::TextDomain::__x(\'{foo}\')' ],
                  [ 0, '__x(\'{foo}\', @args)' ],
                  [ 1, '__x(\'{foo}\', bar => 123, @args)' ],

                 ) {
  my ($want_count, $str) = @$data;
  my @violations = $critic->critique (\$str);
  my $got_count = scalar @violations;
  is ($got_count, $want_count, "$str");
}

exit 0;

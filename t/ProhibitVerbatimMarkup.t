#!/usr/bin/perl -w

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
use Test::More tests => 12;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings(1);

require Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup;


#------------------------------------------------------------------------------
my $want_version = 39;
is ($Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitVerbatimMarkup');

  my $policy = $p[0];
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (
                  [ 1, "=pod\n\n    Some C<markup>" ],
                  [ 1, "=pod\n\n    E<gt>" ],
                  [ 1, "=pod\n\n    J<< something >>" ],
                  [ 1, "=pod\n\n    I<italic>" ],
                  [ 1, "=pod\n\n    bold\n\n    B<bold>" ],

                 ) {
  my ($want_count, $str) = @$data;
  $str = "$str";

  my @violations = $critic->critique (\$str);
  foreach (@violations) {
    diag ($_->description);
  }
  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: '$str'");
}

exit 0;

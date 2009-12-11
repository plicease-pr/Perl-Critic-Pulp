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
use Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy;
use Test::More tests => 23;
use Perl::Critic;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

#------------------------------------------------------------------------------
my $want_version = 25;
cmp_ok ($Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy::VERSION, '>=', $want_version, 'VERSION variable');
cmp_ok (Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy->VERSION,  '>=', $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
my $critic;
eval {
  $critic = Perl::Critic->new
    ('-profile' => '',
     '-single-policy' => 'Compatibility::PerlMinimumVersionAndWhy',
    );
};
my $have_perl_minimumversion = eval { require Perl::MinimumVersion };
{
  my $want_count = ($have_perl_minimumversion ? 1 : 0);
  my @p;
  if ($critic) { @p = $critic->policies; }
  is (scalar @p, $want_count,
      'single policy PerlMinimumVersionAndWhy');
}

SKIP: {
  0 # $critic
    or skip 'Perl::MinimumVersion not available', 17;

  my ($policy) = $critic->policies;
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  foreach my $data (
                    ## no critic (RequireInterpolationOfMetachars)

                    # _my_perl_5010_qr_m_working_properly
                    #
                    [ 1, 'use 5.008; qr/^x$/m' ],
                    [ 0, 'use 5.010; qr/^x$/m' ],
                    [ 1, 'use 5.006; my $re = qr/pattern/m;' ],
                    [ 0, 'use 5.010; my $re = qr/pattern/m;' ],
                    #
                    # plain patterns ok, only qr// bad
                    [ 0, '$str =~ /^foo$/m' ],
                    [ 0, '$str =~ m{^foo$}m' ],
                    #
                    # with other modifiers
                    [ 1, 'use 5.008; qr/^x$/im' ],
                    [ 1, 'use 5.008; qr/^x$/ms' ],
                    #
                    # other modifiers
                    [ 0, 'use 5.006; my $re = qr/pattern/s;' ],
                    [ 0, 'use 5.006; my $re = qr/pattern/i;' ],
                    [ 0, 'use 5.006; my $re = qr/pattern/x;' ],
                    [ 0, 'use 5.006; my $re = qr/pattern/o;' ],


                    # _perl_5010_operators__fix
                    #
                    [ 1, "1 // 2" ],
                    [ 1, "use 5.008; 1 // 2" ],
                    [ 0, "use 5.010; 1 // 2" ],

                   ) {
    my ($want_count, $str) = @$data;
    $str = "$str";

    my @violations = $critic->critique (\$str);
    foreach (@violations) {
      diag ($_->description);
    }
    my $got_count = scalar @violations;
    is ($got_count, $want_count, "str: $str");
  }
}

exit 0;

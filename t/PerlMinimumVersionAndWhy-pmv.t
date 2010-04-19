#!/usr/bin/perl

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


use strict;
use warnings;
use Test::More;
use Perl::Critic;

my $critic;
eval {
  $critic = Perl::Critic->new
    ('-profile' => '',
     '-single-policy' => 'Compatibility::PerlMinimumVersionAndWhy',
    );
  1;
}
  or plan skip_all => "cannot create Critic object -- $@";

my @policies = $critic->policies;
if (@policies == 0) {
  plan skip_all => "due to policy not initializing";
}

plan tests => 47;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

is (scalar @policies, 1, 'single policy PerlMinimumVersionAndWhy');
my $policy = $policies[0];
diag "Perl::MinimumVersion ", Perl::MinimumVersion->VERSION;

{
  my $want_version = 34;
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

foreach my $data (
                  ## no critic (RequireInterpolationOfMetachars)

                  # _my_perl_5006_delete_array_elem
                  [ 1, 'use 5.005; delete $x[0]' ],
                  [ 0, 'use 5.006; delete $x[0]' ],
                  [ 1, 'use 5.005; delete($x[1])' ],
                  [ 0, 'use 5.005; delete $x[0]',
                    { _skip_checks => '_my_perl_5006_delete_array_elem'} ],

                  # _my_perl_5006_exists_array_elem
                  [ 1, 'use 5.005; exists $x[0]' ],
                  [ 0, 'use 5.006; exists $x[0]' ],
                  [ 0, 'use 5.005; exists($x[1])',
                    { _skip_checks => '_my_perl_5006_delete_array_elem _my_perl_5006_exists_array_elem'} ],

                  # _my_perl_5006_exists_sub
                  [ 1, 'use 5.005; exists &foo' ],
                  [ 0, 'use 5.006; exists &foo' ],
                  [ 1, 'use 5.005; exists(&foo)' ],

                  # _my_perl_5005_bareword_colon_colon
                  [ 1, 'use 5.004; foo(Foo::Bar::)' ],
                  [ 0, 'use 5.005; foo(Foo::Bar::)' ],

                  # _my_perl_5004_pack_format
                  [ 1, 'use 5.002; pack "w", 123' ],
                  [ 0, 'use 5.004; pack "w", 123' ],
                  [ 0, 'use 5.002; pack "$w", 123' ],
                  [ 1, "use 5.002; pack 'i'.<<HERE, 123
w
HERE
" ],
                  [ 1, "use 5.002; pack w => 123" ],
                  [ 1, 'use 5.002; unpack "i".w => $bytes' ],
                  [ 0, "use 5.002; pack MYFORMAT(), 123" ],
                  [ 0, "use 5.002; pack MYFORMAT, 123" ],

                  # _my_perl_5006_pack_format
                  [ 1, 'use 5.005; pack ("Z", "hello")' ],
                  [ 0, 'use 5.006; pack ("Z", "hello")' ],
                  [ 1, 'use 5.005; pack ("Z#comment", "hello")' ],
                  [ 0, 'use 5.006; pack ("Z#comment", "hello")' ],

                  # _my_perl_5008_pack_format
                  [ 1, 'use 5.006; pack ("F", 1.5)' ],
                  [ 0, 'use 5.008; pack ("F", 1.5)' ],

                  # _my_perl_5010_pack_format
                  [ 1, 'use 5.008; unpack ("i<", $bytes)' ],
                  [ 0, 'use 5.010; unpack ("i<", $bytes)' ],


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
  my ($want_count, $str, $options) = @$data;
  $policy->{'_skip_checks'} = ''; # default

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

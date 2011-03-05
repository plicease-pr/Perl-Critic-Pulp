#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Test::More;
use Perl::Critic;

my $critic;
eval {
  $critic = Perl::Critic->new
    ('-profile' => '',
     '-single-policy' => '^Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy$');
  1;
}
  or plan skip_all => "cannot create Critic object -- $@";

my @policies = $critic->policies;
if (@policies == 0) {
  plan skip_all => "due to policy not initializing";
}

plan tests => 76;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

is (scalar @policies, 1, 'single policy PerlMinimumVersionAndWhy');
my $policy = $policies[0];
diag "Perl::MinimumVersion ", Perl::MinimumVersion->VERSION;

{
  my $want_version = 48;
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

my $have_pulp_bareword_double_colon
  = exists $Perl::MinimumVersion::CHECKS{_Pulp__bareword_double_colon};
diag "pulp bareword double colon: ",($have_pulp_bareword_double_colon||0);

my $have_pulp_5010_magic_fix
  = exists $Perl::MinimumVersion::CHECKS{_Pulp__5010_magic__fix};
diag "pulp magic fix: ",($have_pulp_5010_magic_fix||0);

foreach my $data (
                  ## no critic (RequireInterpolationOfMetachars)

                  # _Pulp__fat_comma_across_newline
                  [ 0, "return (foo =>\n123)" ],
                  [ 1, "return (foo\n=>\n123)" ],
                  [ 1, "return (foo\t\n\t=>\n123)" ],
                  [ 1, "return (foo # foo\n=>\n123)" ],
                  [ 1, "return (foo # foo\n\n=>\n123)" ],
                  [ 1, "return (foo # 'comment'\n \n # 'comment'\n=>\n123)" ],
                  # method calls
                  [ 0, "return (Foo->bar => 123" ],
                  [ 0, "return (Foo->bar \n => 123" ],
                  [ 0, "return (Foo -> bar \n => 123" ],

                  # _Pulp__arrow_coderef_call
                  [ 1, '$coderef->()' ],
                  [ 1, '$coderef->(1,2,3)' ],
                  [ 1, '$hashref->{code}->()' ],
                  [ 1, '$hashref->{code}->(1,2,3)' ],
                  [ 0, 'use 5.004; $coderef->()' ],

                  # _Pulp__for_loop_variable_using_my
                  [ 1, 'foreach my $i (1,2,3) { }' ],
                  [ 0, 'use 5.004; foreach my $i (1,2,3) { }' ],
                  [ 0, 'foreach $i (1,2,3) { }' ],
                  [ 0, 'foreach (1,2,3) { }' ],
                  [ 1, 'for my $i (1,2,3) { }' ],
                  [ 0, 'use 5.004; for my $i (1,2,3) { }' ],
                  [ 0, 'for $i (1,2,3) { }' ],
                  [ 0, 'for (1,2,3) { }' ],

                  # _Pulp__use_version_number
                  [ 1, 'use 5' ],
                  [ 1, 'use 5.003' ],
                  [ 0, 'use 5.004' ],
                  #
                  # these are ok if Foo is using Exporter.pm ...
                  # [ 1, 'require 5.003; use Foo 1.0' ],
                  # [ 0, 'require 5.004; use Foo 1.0' ],
                  # [ 0, 'use Foo 1.0, 2.0' ],  # args not ver num

                  # _Pulp__special_literal__PACKAGE__
                  [ 1, 'require 5.003; my $str = __PACKAGE__;' ],
                  [ 0, 'use 5.004; my $str = __PACKAGE__;' ],
                  [ 0, 'require 5.003; my %hash = (__PACKAGE__ => 1);' ],
                  [ 1, 'require 5.003; my %hash = (__PACKAGE__,   1);' ],
                  [ 0, 'require 5.003; my $elem = $hash{__PACKAGE__};' ],

                  # _Pulp__delete_array_elem
                  [ 1, 'use 5.005; delete $x[0]' ],
                  [ 0, 'use 5.006; delete $x[0]' ],
                  [ 1, 'use 5.005; delete($x[1])' ],
                  [ 0, 'use 5.005; delete $x[0]',
                    { _skip_checks => '_Pulp__delete_array_elem'} ],

                  # _Pulp__exists_array_elem
                  [ 1, 'use 5.005; exists $x[0]' ],
                  [ 0, 'use 5.006; exists $x[0]' ],
                  [ 0, 'use 5.005; exists($x[1])',
                    { _skip_checks => '_Pulp__delete_array_elem _Pulp__exists_array_elem'} ],

                  # _Pulp__exists_sub
                  [ 1, 'use 5.005; exists &foo' ],
                  [ 0, 'use 5.006; exists &foo' ],
                  [ 1, 'use 5.005; exists(&foo)' ],

                  # _Pulp__bareword_double_colon
                  [ ($have_pulp_bareword_double_colon ? 1 : 0),
                    'use 5.004; foo(Foo::Bar::)' ],
                  [ 0, 'use 5.005; foo(Foo::Bar::)' ],

                  #
                  # pack(), unpack()
                  #

                  # _Pulp__5004_pack_format
                  [ 1, 'require 5.002; pack "w", 123' ],
                  [ 0, 'use 5.004; pack "w", 123' ],
                  [ 0, 'require 5.002; pack "$w", 123' ],
                  [ 1, "require 5.002; pack 'i'.<<HERE, 123
w
HERE
" ],
                  [ 1, "require 5.002; pack w => 123" ],
                  [ 1, 'require 5.002; unpack "i".w => $bytes' ],
                  [ 0, "require 5.002; pack MYFORMAT(), 123" ],
                  [ 0, "require 5.002; pack MYFORMAT, 123" ],

                  # _Pulp__5006_pack_format
                  [ 1, 'use 5.005; pack ("Z", "hello")' ],
                  [ 0, 'use 5.006; pack ("Z", "hello")' ],
                  [ 1, 'use 5.005; pack ("Z#comment", "hello")' ],
                  [ 0, 'use 5.006; pack ("Z#comment", "hello")' ],

                  # _Pulp__5008_pack_format
                  [ 1, 'use 5.006; pack ("F", 1.5)' ],
                  [ 0, 'use 5.008; pack ("F", 1.5)' ],

                  # _Pulp__5010_pack_format
                  [ 1, 'use 5.008; unpack ("i<", $bytes)' ],
                  [ 0, 'use 5.010; unpack ("i<", $bytes)' ],


                  # _Pulp__5010_qr_m_working_properly
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


                  # _Pulp__5010_magic__fix
                  # _Pulp__5010_operators__fix
                  #
                  [ ($have_pulp_5010_magic_fix ? 1 : 0), "1 // 2" ],
                  [ ($have_pulp_5010_magic_fix ? 1 : 0), "use 5.008; 1 // 2" ],
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

  # only the Pulp ones, not any Perl::MinimumVersion itself might gain
  @violations = grep {$_->description =~ /^_Pulp_/} @violations;

  foreach my $violation (@violations) {
    diag ('violation: ', $violation->description);
  }
  my $got_count = scalar @violations;
  is ($got_count, $want_count, $name);
}

exit 0;

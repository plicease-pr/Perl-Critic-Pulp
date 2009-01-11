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
use Perl::Critic::Policy::Compatibility::ConstantPragmaHash;
use Test::More tests => 106;
use Perl::Critic;

my $single_policy = 'Compatibility::ConstantPragmaHash';
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => $single_policy);
{ my @p = $critic->policies;
  is (scalar @p, 1,
      "single policy $single_policy");
}

my $want_version = 13;
ok ($Perl::Critic::Policy::Compatibility::ConstantPragmaHash::VERSION >= $want_version, 'VERSION variable');
ok (Perl::Critic::Policy::Compatibility::ConstantPragmaHash->VERSION  >= $want_version, 'VERSION class method');
Perl::Critic::Policy::Compatibility::ConstantPragmaHash->VERSION($want_version);

#-----------------------------------------------------------------------------
# _include_module_version()

foreach my $data ([ 'use foo', undef ],

                  [ 'use foo 1', 1 ],
                  [ 'use foo 1;', 1 ],
                  [ 'no foo 1', 1 ],
                  [ 'no foo 1;', 1 ],

                  [ 'use foo 1.5', 1.5 ],
                  [ 'use foo 1.5;', 1.5 ],
                  [ 'no foo 1.5', 1.5 ],
                  [ 'no foo 1.5;', 1.5 ],

                  [ 'use foo 1,2', undef ],
                  [ 'use foo 1, ;', undef ],
                  [ 'use foo \'1\';', undef ],
                  [ 'use foo "1";', undef ],
                  [ 'use foo q{1};', undef ],

                  # trailing comma is ok at end of file, and it's not a
                  # version number
                  [ 'use foo 1,', undef ],

                  # this is a syntax error, but let's suppose that if it
                  # worked it's an arglist not a version
                  [ 'use foo 5 => 6', undef ],

                  # this is a syntax error, but the func still interprets it
                  # the same as "use" or "no"
                  [ 'require foo 5', 5 ],

                 ) {
  my ($str, $want) = @$data;

  foreach my $suffix ('', ';') {
    $str .= $suffix;

    my $document = PPI::Document->new (\$str)
      or die "oops, no parse: $str";
    my $incs = ($document->find ('PPI::Statement::Include')
                || $document->find ('PPI::Statement::Sub')
                || die "oops, no target statement in '$str'");
    my $inc = $incs->[0] or die "oops, no Include element";
    my $ver = Perl::Critic::Policy::Compatibility::ConstantPragmaHash::_include_module_version ($inc);
    is (defined $ver ? $ver->content : undef,
        $want,
        "str: $str");
  }
}

#-----------------------------------------------------------------------------
# _include_module_first_arg()

foreach my $data ([ 'use foo',   undef ],
                  [ 'use foo;',  undef ],
                  [ 'use foo 1', undef ],

                  [ 'use foo 123,456',     123 ],
                  [ 'use foo 123,',        123 ],
                  [ 'use foo 123,{x=>1}',  '123' ],
                  [ 'use foo 1.03 {x=>1}', '{x=>1}' ],
                  [ 'use foo {x=>1}',      '{x=>1}' ],

                 ) {
  foreach my $suffix ('', ';') {

    my ($str, $want) = @$data;
    $str .= $suffix;

    my $document = PPI::Document->new (\$str)
      or die "oops, no parse: $str";
    my $incs = ($document->find ('PPI::Statement::Include')
                || $document->find ('PPI::Statement::Sub')
                || die "oops, no target statement in '$str'");
    my $inc = $incs->[0] or die "oops, no Include element";
    my $elem = Perl::Critic::Policy::Compatibility::ConstantPragmaHash::_include_module_first_arg ($inc);
    diag "elem class ",ref($elem);
    is ($elem ? "$elem" : undef, $want, "str: $str");
  }
}

#-----------------------------------------------------------------------------
# _use_constant_is_multi()

foreach my $data ([ 'use constant', 0 ],
                  [ 'use constant 1.03', 0 ],

                  [ 'use constant FOO, 123', 0 ],
                  [ 'use constant FOO => 123', 0 ],
                  [ 'use constant qw(FOO 123)', 0 ],

                  [ 'use constant {x=>1}', 1 ],
                  [ 'use constant { qw(x 1) }', 1 ],

                 ) {

  foreach my $suffix ('', ';') {
    foreach my $ver ('', ' 1.03') {

      my ($str, $want) = @$data;
      $str .= $suffix;
      $str =~ s/constant/constant$ver/;

      my $document = PPI::Document->new (\$str)
        or die "oops, no parse: $str";
      my $incs = ($document->find ('PPI::Statement::Include')
                  || $document->find ('PPI::Statement::Sub')
                  || die "oops, no target statement in '$str'");
      my $inc = $incs->[0] or die "oops, no Include element";
      my $ret = Perl::Critic::Policy::Compatibility::ConstantPragmaHash::_use_constant_is_multi ($inc);
      is ($ret?1:0, $want, "str: $str");
    }
  }
}

#-----------------------------------------------------------------------------
# the policy

foreach my $data (
                  # from the pod
                  [ 1, 'use constant { AA => 1, BB => 2};' ],
                  [ 0, 'use 5.008;
                        use constant { CC => 1, DD => 2};' ],
                  [ 0, 'use constant 1.03;
                        use constant { EE => 1, FF => 2};' ],
                  [ 0, 'use constant 1.03 { GG => 1, HH => 2};' ],

                  [ 0, 'use 5.010;
                        use constant { CC => 1, DD => 2};' ],
                  [ 0, 'use constant 1.04;
                        use constant { EE => 1, FF => 2};' ],

                  # multi-constant before version num
                  [ 1, 'use constant { CC => 1, DD => 2};
                        use 5.010;' ],
                  [ 1, 'use constant { EE => 1, FF => 2};
                        use constant 1.04;' ],

                  [ 2, 'use constant { A => 1, B => 2};
                        use constant { C => 1, D => 2};
                        use constant 1.04;
                        use constant { E => 1, F => 2};' ],

                  [ 2, 'use constant { A => 1, B => 2};
                        use constant { C => 1, D => 2};
                        use 5.010;
                        use constant { E => 1, F => 2};' ],

                  [ 1, 'use constant { CC => 1, DD => 2};
                        require 5.010;' ],
                  [ 1, 'require 5.010;
                        use constant { CC => 1, DD => 2};' ],
                  [ 0, 'BEGIN { require 5.010 }
                        use constant { CC => 1, DD => 2};' ],
                  [ 1, 'BEGIN { require 5.005 }
                        use constant { CC => 1, DD => 2};' ],
                  [ 0, 'BEGIN { { require 5.010; } }
                        use constant { CC => 1, DD => 2};' ],
                  [ 0, 'BEGIN { foo(); { require 5.010 } }
                        use constant { CC => 1, DD => 2};' ],
                  [ 1, 'use constant { CC => 1, DD => 2};
                        BEGIN { require 5.010 }' ],

                  [ 0, 'use constant CC => 1;
                        use constant DD => 2;' ],

                  [ 1, 'use constant 1.02 { GG => 1, HH => 2};' ],
                  [ 1, 'use constant 1.02;
                        use constant { GG => 1, HH => 2};' ],
                  [ 0, 'use constant 1000.9 { GG => 1, HH => 2};' ],
                  [ 0, 'use constant 1000.9;
                        use constant { GG => 1, HH => 2};' ],

                  # bogus version number forms don't count as a version
                  # declaration, so policy should fire
                  [ 1, 'use constant \'1.03\';
                        use constant { EE => 1, FF => 2};' ],
                  [ 1, 'use constant "1.03";
                        use constant { EE => 1, FF => 2};' ],

                  # this is a syntax error, but shouldn't tickle the policy
                  [ 0, 'use constant \'1.02\' { GG => 1, HH => 2};' ],

                 ) {
  my ($want_count, $str) = @$data;

  my @violations = $critic->critique (\$str);
  foreach (@violations) {
    diag ($_->description);
  }
  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: $str");
}

exit 0;

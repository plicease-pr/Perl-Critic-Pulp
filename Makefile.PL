#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

# This file is part of Perl-Critic-Pulp.

# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

WriteMakefile
  (NAME         => 'Perl-Critic-Pulp',
   ABSTRACT     => 'Some add-on policies for Perl::Critic.',
   VERSION_FROM => 'lib/Perl/Critic/Pulp.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.006',

   PREREQ_PM    => {
                    # 1.082 or some such for new style parameter specs
                    'Perl::Critic' => '1.082',
                    # parts of Perl::Critic, used so name them explicitly
                    'Perl::Critic::Utils' => 0,
                    'Perl::Critic::Utils::PPIRegexp' => 0,
                    'Perl::Critic::Violation' => 0,

                    # Required by Perl::Critic itself anyway.
                    # 1.02 for avoiding leaks in perl 5.8 (probably
                    # something even newer has more merit though)
                    'IO::String' => '1.02',

                    # Builtin in recent perl anyway.
                    'List::Util' => 0,
                    'Test::More' => 0,

                    # Required by Perl::Critic itself anyway,
                    # and comes with perl 5.10 anyway too.
                    'version' => 0,

                   },
   clean     => { FILES => [ 'TAGS' ] },

   EXTRA_META => strip_comments(<<'HERE'),
optional_features:
    maximum_policies:
        description: Have the policies check as much as possible.
        requires:
            Perl::MinimumVersion: 0
    maximum_tests:
        description: Have "make test" do as much as possible.
        requires:
            Perl::MinimumVersion: 0
            Test::NoWarnings: 0
            Test::Pod: 1.00
            Test::YAML::Meta: 0
            YAML: 0
            YAML::Syck: 0
            YAML::Tiny: 0
            YAML::XS: 0
    maximum_devel:
        description: Stuff used variously for development.
        requires:
            Perl6::Slurp: 0
no_index:
    package:
        # use of "package Perl::MinimumVersion" hack for fixes there
        - Perl::MinimumVersion
    directory:
        - devel
        - inc
        - t
resources:
    homepage: http://user42.tuxfamily.org/perl-critic-pulp/index.html
    license: http://www.gnu.org/licenses/gpl.html
HERE
  );

sub strip_comments {
  my ($str) = @_;
  $str =~ s/^\s*#.*\n//mg;
  $str
}

#------------------------------------------------------------------------------
package MY;
sub postamble {
  my ($makemaker) = @_;
  return MyMakeMakerExtras::postamble ($makemaker);
}

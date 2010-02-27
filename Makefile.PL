#!/usr/bin/perl

# Copyright 2008, 2009, 2010 Kevin Ryde

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

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Perl-Critic-Pulp',
   ABSTRACT     => 'Some add-on policies for Perl::Critic.',
   VERSION_FROM => 'lib/Perl/Critic/Pulp.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.006',

   PREREQ_PM    => {
                    # 1.208 for PPI::Token::QuoteLike::Regexp get_modifiers()
                    'PPI' => '1.208',

                    # 1.082 or some such for new style parameter specs
                    # 1.084 for highest_explicit_perl_version() method
                    'Perl::Critic' => '1.084',
                    # parts of Perl::Critic, used so name them explicitly
                    'Perl::Critic::Policy' => '1.084',
                    'Perl::Critic::Utils' => 0,
                    'Perl::Critic::Utils::PPI' => 0,
                    'Perl::Critic::Violation' => 0,

                    # Required by Perl::Critic itself anyway.
                    # 1.02 for avoiding leaks in perl 5.8 (probably
                    # something even newer has more merit though)
                    'IO::String' => '1.02',

                    # Also used by Perl::Critic itself.  Maybe should
                    # require 0.24 for various XS bugfixes.
                    'List::MoreUtils' => 0,

                    # Builtin in recent perl anyway.
                    'List::Util' => 0,
                    'Test::More' => 0,
                    'Scalar::Util' => 0,

                    # Required by Perl::Critic itself anyway,
                    # and comes with perl 5.10 anyway too.
                    'version' => 0,

                   },

   META_MERGE
   => { resources
        => { homepage
             => 'http://user42.tuxfamily.org/perl-critic-pulp/index.html',
           },
        optional_features
        => { maximum_policies
             => { description => 'Have the policies check as much as possible.',
                  requires => { 'Perl::MinimumVersion' => 0,
                              },
                },
             maximum_tests
             => { description => 'Have "make test" do as much as possible.',
                  requires => { 'Test::NoWarnings' => 0,
                                'Perl::MinimumVersion' => 0,
                              },
                },
             maximum_devel
             => { description => 'Stuff used variously for development.',
                  requires => { 'PPI::Document' => 0,
                                'Perl::MinimumVersion' => 0,
                                'Encode' => 0,
                                'Perl6::Slurp' => 0,
                                'Regexp::Common' => 0,
                                'Devel::Mallinfo' => 0,
                                'IO::Uncompress::AnyInflate' => 0,
                                'lib::abs' => 0,
                                'IO::String' => 0,
                                'Digest::MD5' => 0,
                                'I18N::Langinfo' => 0,
                                'Locale::TextDomain' => 0,
                                'File::Locate' => 0,

                                'File::Locate::Iterator' => 0, # mine
                                # parts of File::Locate::Iterator
                                'Iterator::Simple' => 0,
                                'Iterator::Simple::Locate' => 0,
                              },
                },
           },

        # "package Perl::MinimumVersion" hack for fixes there
        no_index => { package => [ 'Perl::MinimumVersion' ] },
      },

   MY_NO_HTML => 1,
  );

#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
use Test::More tests => 15;

# use lib 't';
# use MyTestHelpers;
# BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::Modules::ProhibitModuleShebang;

#-----------------------------------------------------------------------------
my $want_version = 59;
is ($Perl::Critic::Policy::Modules::ProhibitModuleShebang::VERSION,
    $want_version, 'VERSION variable');
is (Perl::Critic::Policy::Modules::ProhibitModuleShebang->VERSION,
    $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::Modules::ProhibitModuleShebang->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::Modules::ProhibitModuleShebang->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'Modules::ProhibitModuleShebang');
my $policy;
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy ProhibitModuleShebang');

  $policy = $p[0];
  is ($policy->VERSION, $want_version, 'VERSION object method');
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

my $dir = File::Temp->newdir;

foreach my $data ([ 1, 'Foo.pm', '#!/usr/bin/perl -w' ],
                  [ 1, 'Foo.pm', '#!perl' ],

                  [ 0, 'Foo.pm', '#!/bin/false',
                    _allow_bin_false => 1 ],
                  [ 1, 'Foo.pm', '#!/bin/false',
                    _allow_bin_false => 0 ],

                  [ 0, 'Foo.pm', "some code()  #!/usr/bin/perl -w" ],
                  [ 0, 'Foo.pm', "some code()\n#!/usr/bin/perl -w" ],
                  [ 0, 'Foo.pl', '#!/usr/bin/perl -w' ],

                  ## use critic
                 ) {
  my ($want_count, $filename, $str, %parameters) = @$data;
  %$policy = (%$policy,
              _allow_bin_false => 1,
              %parameters);

  $filename = File::Spec->catdir ($dir, $filename);
  diag $filename;
  open my $fh, '>', $filename or die;
  print $fh $str or die;
  close $fh or die;

  my @violations = $critic->critique ($filename);

  # foreach (@violations) {
  #   diag ($_->description);
  # }

  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: $str\n_allow_bin_false=$policy->{'_allow_bin_false'}");

  unlink $filename  or die;
}

exit 0;

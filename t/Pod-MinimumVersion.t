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
use Pod::MinimumVersion;
use Test::More tests => 50;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

#------------------------------------------------------------------------------
{
  my $want_version = 26;
  cmp_ok ($Pod::MinimumVersion::VERSION,
          '>=', $want_version, 'VERSION variable');
  cmp_ok (Pod::MinimumVersion->VERSION,
          '>=', $want_version, 'VERSION class method');
  {
    ok (eval { Pod::MinimumVersion->VERSION($want_version); 1 }, "VERSION class check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { Pod::MinimumVersion->VERSION($check_version); 1 }, "VERSION class check $check_version");
  }
  { my $pmv = Pod::MinimumVersion->new;
    cmp_ok ($pmv->VERSION, '>=', $want_version, 'VERSION object method');
    ok (eval { $pmv->VERSION($want_version); 1 },
        "VERSION object check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { $pmv->VERSION($check_version); 1 },
        "VERSION object check $check_version");
  }
}

#------------------------------------------------------------------------------
foreach my $data (
                  [ 0, "=pod\n\nS<C<foo>C<bar>>" ],

                  # doubles
                  [ 1, "=pod\n\nC<< foo >>" ],
                  [ 0, "=pod\n\nC<foo>" ],
                  [ 1, "=pod\n\nL< C<< foo >> >" ],

                  # Pod::MultiLang
                  [ 0, "=pod\n\nJ<< ... >>" ],

                  # links
                  [ 0, "=pod\n\nL<foo>" ],
                  [ 0, "=pod\n\nL<Foo::Bar>" ],

                  # links - alt text
                  [ 1, "=pod\n\nL<foo|bar>" ],
                  [ 0, "=pod\n\nL<foo|bar>", above_version => '5.005' ],
                  [ 2, "=pod\n\nL<C<< foo >>|S<< bar >>>" ],
                  [ 3, "=pod\n\nL<C<< foo >>|S<< bar >>>",
                    want_reports => 'alll' ],

                  # links - url
                  [ 1, "=pod\n\nL<http://www.foo.com/index.html>" ],
                  [ 1, "=pod\n\nL<http://www.foo.com/index.html>",
                    above_version => '5.006' ],
                  [ 0, "=pod\n\nL<http://www.foo.com/index.html>",
                    above_version => '5.008' ],

                  [ 0, "=pos\n\nE<lt>\n" ],
                  [ 0, "=pos\n\nE<gt>\n" ],
                  [ 0, "=pos\n\nE<quot>\n" ],
                  # E<apos>
                  [ 1, "=pos\n\nE<apos>\n" ],
                  [ 0, "=pos\n\nE<apos>\n", above_version => '5.008' ],
                  # E<sol>
                  [ 1, "=pos\n\nE<sol>\n" ],
                  [ 0, "=pos\n\nE<sol>\n", above_version => '5.008' ],
                  # E<verbar>
                  [ 1, "=pos\n\nE<verbar>\n" ],
                  [ 0, "=pos\n\nE<verbar>\n", above_version => '5.008' ],

                  # =head3
                  [ 1, "=head3\n" ],
                  [ 0, "=head3\n", above_version => '5.008' ],
                  # =head4
                  [ 1, "=head4\n" ],
                  [ 0, "=head4\n", above_version => '5.008' ],

                  # =encoding
                  [ 1, "=encoding\n" ],
                  [ 1, "=encoding\n", above_version => '5.008' ],
                  [ 0, "=encoding\n", above_version => '5.010' ],

                  # =for
                  [ 1, "=for foo\n" ],
                  [ 1, "=for foo\n", above_version => '5.003' ],
                  [ 0, "=for foo\n", above_version => '5.004' ],
                  # =begin
                  [ 1, "=begin foo\n" ],
                  [ 1, "=begin foo\n", above_version => '5.003' ],
                  [ 0, "=begin foo\n", above_version => '5.004' ],
                  # =end
                  [ 1, "=end foo\n" ],
                  [ 1, "=end foo\n", above_version => '5.003' ],
                  [ 0, "=end foo\n", above_version => '5.004' ],

                 ) {
  my ($want_count, $str, @options) = @$data;
  # diag "POD: $str";

  my $pmv = Pod::MinimumVersion->new (string => $str,
                                      @options);
  my @reports = $pmv->reports;

  # diag explain $pmv;
  foreach my $report (@reports) { diag "-- ", $report->as_string; }
  # diag explain \@reports;

  my $got_count = scalar @reports;
  require Data::Dumper;
  is ($got_count, $want_count,
      Data::Dumper->new([$str],['str'])->Indent(0)->Useqq(1)->Dump
      . Data::Dumper->new([\@options],['options'])->Indent(0)->Dump);
}

foreach my $data (
                  [ undef,   "" ],
                  [ '5.005', "=for Pod::MinimumVersion use 5.005" ],
                  [ '5.005', "=for\t\tPod::MinimumVersion\t\tuse\t\t5.005" ],
                 ) {
  my ($want_version, $str, @options) = @$data;
  # diag "POD: $str";
  my $pmv = Pod::MinimumVersion->new (string => $str,
                                     @options);
  my @reports = $pmv->analyze;
  my $got_version = $pmv->{'for_version'};
  is ($got_version, $want_version,
      '=for Pod::MinimumVersion use 5.005');
}

exit 0;

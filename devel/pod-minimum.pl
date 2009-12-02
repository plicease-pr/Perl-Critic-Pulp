#!/usr/bin/perl

# Copyright 2009 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
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

use strict;
use warnings;
use FindBin;
use File::Spec;
use Pod::MinimumVersion;
use Data::Dumper;

my $script_filename = File::Spec->catfile ($FindBin::Bin, $FindBin::Script);

{
  require Perl::Critic;
  print "Perl::Critic version ", Perl::Critic->VERSION, "\n";
  my $critic = Perl::Critic->new ('-profile' => '',
                                  '-single-policy' => 'PodMinimumVersion');
  require Perl::Critic::Violation;
  Perl::Critic::Violation::set_format("%f:%l:%c:\n %P\n %m\n %r\n");

  my $filename = $script_filename;
  my @violations;
  if (! eval { @violations = $critic->critique ($filename); 1 }) {
    print "Died in \"$filename\": $@\n";
    exit 1;
  }
  foreach my $violation (@violations) {
    print Data::Dumper->new ([\$violation],['violation'])->Maxdepth(2)->Dump,"\n";
    print $violation;
    print "viol filename ", $violation->filename,"\n";
    my $loc = $violation->location;
    print Data::Dumper->new ([\$loc],['loc'])->Indent(0)->Dump,"\n";
  }
  if (my $exception = Perl::Critic::Exception::Parse->caught) {
    print "Caught exception in \"$filename\": $exception\n";
  }
  exit 0;
}

{
  my $pmv = Pod::MinimumVersion->new
    (
     # string => "use 5.010; =encoding\n",
     # string => "=pod\n\nC<< foo >>",
     # filename => $script_filename,
     # filehandle => do { require IO::String; IO::String->new("=pod\n\nE<sol> E<verbar>") },
      string => "=pod\n\nL<foo|bar>",
     one_report_per_version => 1,
     above_version => '5.005',
    );

  print Dumper($pmv);
  print "min ", $pmv->minimum_version, "\n";
  print Dumper($pmv);

  my @reports = $pmv->reports;
  foreach my $report (@reports) {
    my $loc = $report->PPI_location;
    print $report->as_string,"\n";
    print Data::Dumper->new ([\$loc],['loc'])->Indent(0)->Dump,"\n";
  }
}

use 5.002;

__END__

=encoding utf-8

=head1 NAME

x

=head1 DESCRIPTION

=head1 Heading

J<< C<< x >> >>
C<< double >>
S<< double >>
L<C<Foo>|Footext>

=begin foo

text meant only for foo ...

=end foo

=cut

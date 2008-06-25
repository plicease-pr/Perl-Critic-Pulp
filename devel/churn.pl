#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

use Perl::Critic;
use Perl::Critic::Utils;
use Perl::Critic::Violation;

my @dirs = @ARGV;
if (! @dirs) {
  @dirs = ('/usr/share/perl5', </usr/share/perl/*.*.*>);
}
print "Directories:\n";
foreach (@dirs) {
  print "  ",$_,"\n";
}

my @files = map { -d $_ ? Perl::Critic::Utils::all_perl_files($_) : $_ } @dirs;
print "Files: ",scalar(@files),"\n";


my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => 'ValuesAndExpressions::ConstantBeforeLt');

$critic->add_policy (-policy => 'ValuesAndExpressions::ProhibitNullStatements',
                     -params => { allow_perl4_semihash => 1 });

Perl::Critic::Violation::set_format ("%f:%l:%c:\n %P\n %m\n");

foreach my $file (@files) {
  eval {
    my @violations = $critic->critique ($file);
    print @violations;
  };
  if ( my $exception = Perl::Critic::Exception::Parse->caught() ) {
    print "Warning in \"$file\": $EVAL_ERROR\n";
  } elsif ($@) {
    print "Error in \"$file\": $EVAL_ERROR\n";
  }
}

exit 0;

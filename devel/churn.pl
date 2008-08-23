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


# Usage: churn.pl [--const] [--not] [--diag] [directories...]
#
# Run the pulp tests over all files under the given directories, or by
# default over /usr/share/perl (core and add-ons).
#
# The options select just one of the policies.
#

use strict;
use warnings;
use Perl::Critic;
use Perl::Critic::Utils;
use Perl::Critic::Violation;

my $option_single_policy;
if (($ARGV[0]||'') eq '--const') {
  shift @ARGV;
  $option_single_policy = 'ValuesAndExpressions::ConstantBeforeLt';
}
if (($ARGV[0]||'') eq '--not') {
  shift @ARGV;
  $option_single_policy = 'ValuesAndExpressions::NotWithCompare';
}
if (($ARGV[0]||'') eq '--null') {
  shift @ARGV;
  $option_single_policy = 'ValuesAndExpressions::ProhibitNullStatements';
}
if (($ARGV[0]||'') eq '--special') {
  shift @ARGV;
  $option_single_policy = 'ValuesAndExpressions::LiteralSpecialLiteral';
}

my @dirs = @ARGV;
if (! @dirs) {
  @dirs = ('/usr/share/perl5', glob('/usr/share/perl/*.*.*'));
}
print "Directories:\n";
foreach (@dirs) {
  print "  ",$_,"\n";
}

my @files = map { -d $_ ? Perl::Critic::Utils::all_perl_files($_) : $_ } @dirs;
print "Files: ",scalar(@files),"\n";


my $critic;
if ($option_single_policy) {
  $critic = Perl::Critic->new ('-profile' => '',
                               '-single-policy' => $option_single_policy);
} else {
  $critic = Perl::Critic->new ('-profile' => '',
                               '-theme' => 'pulp');
}
#   $critic->add_policy
#     (-policy => 'ValuesAndExpressions::ProhibitNullStatements',
#      -params => { allow_perl4_semihash => 1 });

print "Policies:\n";
foreach my $p ($critic->policies) {
  print "  ",$p->get_short_name,"\n";
}


# "%f:%l:%c:" is good for emacs compilation-mode
Perl::Critic::Violation::set_format ("%f:%l:%c:\n %P\n %m\n");

foreach my $file (@files) {
  print "$file\n";
  my @violations;
  if (! eval { @violations = $critic->critique ($file); 1 }) {
    print "Died in \"$file\": $@\n";
  } else {
    print @violations;
    if (my $exception = Perl::Critic::Exception::Parse->caught) {
      print "Caught exception in \"$file\": $exception\n";
    }
  }
}

exit 0;

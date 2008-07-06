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

use strict;
use warnings;
use Perl::Critic;
use Perl::Critic::Utils;
use Perl::Critic::Violation;

my $option_const = 0;
if (($ARGV[0]||'') eq '--const') {  # ConstantBeforeLt policy only
  shift @ARGV;
  $option_const = 1;
}
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
if (! $option_const) {
  $critic->add_policy
    (-policy => 'ValuesAndExpressions::ProhibitNullStatements',
     -params => { allow_perl4_semihash => 1 });
}
print "Policies:\n";
foreach my $p ($critic->policies) {
  print "  ",$p->get_short_name,"\n";
}


# "%f:%l:%c:" is good for emacs compilation-mode
Perl::Critic::Violation::set_format ("%f:%l:%c:\n %P\n %m\n");

foreach my $file (@files) {
  print "$file\n";
  eval {
    my @violations = $critic->critique ($file);
    print @violations;
  };
  if (my $exception = Perl::Critic::Exception::Parse->caught) {
    print "Warning in \"$file\": $exception\n";
  } elsif ($@) {
    print "Error in \"$file\": $@\n";
  }
}

exit 0;

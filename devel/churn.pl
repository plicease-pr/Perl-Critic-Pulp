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
use Getopt::Long;
use Perl::Critic;
use Perl::Critic::Utils;
use Perl::Critic::Violation;

my @option_policies;
my $option_t_files = 0;

GetOptions
  (require_order => 1,
   const => sub {
     push @option_policies, 'ValuesAndExpressions::ConstantBeforeLt';
   },
   not => sub {
     push @option_policies, 'ValuesAndExpressions::NotWithCompare';
   },
   null => sub {
     push @option_policies, 'ValuesAndExpressions::ProhibitNullStatements';
   },
   literals => sub {
     push @option_policies, 'ValuesAndExpressions::UnexpandedSpecialLiteral';
   },
   commas => sub {
     push @option_policies, 'ValuesAndExpressions::ProhibitEmptyCommas';
   },
   gtk2 => sub {
     push @option_policies, 'Modules::Gtk2Version';
   },
   lastpod => sub {
     push @option_policies, 'Documentation::RequireEndBeforeLastPod';
   },
   qrm => sub {
     push @option_policies, 'Compatibility::RegexpQrm';
   },
   morelike => sub {
     push @option_policies, 'Compatibility::TestMoreLikeModifiers';
     $option_t_files = 1;
   },
  );

my @dirs = @ARGV;
if (! @dirs) {
  if ($option_t_files) {
    @dirs = split /\n/, `locate '*.t'`;
  } else {
    @dirs = ('/bin',
             '/usr/bin',
             '/usr/share/perl5',
             glob('/usr/share/perl/*.*.*'));
  }
}
print "Directories:\n";
foreach (@dirs) {
  print "  ",$_,"\n";
}

my @files = map { -d $_ ? Perl::Critic::Utils::all_perl_files($_) : $_ } @dirs;
@files = uniq_by_func (\&stat_dev_ino, @files);
print "Files: ",scalar(@files),"\n";

sub stat_dev_ino {
  my ($filename) = @_;
  my ($dev, $ino) = stat ($filename);
  return "$dev,$ino";
}
sub uniq_by_func {
  my $func = shift;
  my %seen;
  return grep { $seen{$func->($_)}++ == 0 } @_;
}


my $critic;
if (@option_policies) {
  $critic = Perl::Critic->new ('-profile' => '',
                               '-single-policy' => shift @option_policies);
  foreach my $policy (@option_policies) {
    $critic->add_policy (-policy => $policy);
  }
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
    next;
  }
  print @violations;
  if (my $exception = Perl::Critic::Exception::Parse->caught) {
    print "Caught exception in \"$file\": $exception\n";
  }
}

exit 0;

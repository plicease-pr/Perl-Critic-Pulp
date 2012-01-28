#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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
use Perl6::Slurp;

use lib::abs '.';
use MyLocatePerl;
use MyStuff;

# uncomment this to run the ### lines
#use Smart::Comments;


my $verbose = 0;

my $l = MyLocatePerl->new (include_pod => 1);
my $p = MyParser->new;
my $filename;

{
  $filename = "$FindBin::Bin/$FindBin::Script";
  if ($verbose) { print "look at $filename\n"; }
  my $str = Perl6::Slurp::slurp ($filename);
  $p->parse_from_string ($str);
}

my $count = 0;
while (($filename, my $str) = $l->next) {
  if ($verbose) { print "look at $filename\n"; }
  $p->parse_from_string ($str);
  $count++;
}
print "total $count\n";

exit 0;

package MyParser;
use base 'Perl::Critic::Pulp::PodParser';
sub begin_pod {
  my ($self) = @_;
  ### begin_input() ...
  $self->{'last_text'} = '';
  $self->{'last_command'} = '';
}
sub command {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### command(): $command

  if ($command eq 'for') {
    ### ignore ...
    return;
  }

  # my $this_level = $command_level{$command} || 0;
  # my $prev_level = $command_level{$self->{'last_command'}} || 0;

  if ($command eq 'item' && $self->{'last_command'} eq 'item') {

  } elsif ($command eq 'over'
           || $command eq 'back') {

  } else {
    _check_last($self);
  }
  $self->{'last_text'} = '';
  $self->{'last_command'} = $command;
}
sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock(): $text
  if (! defined $text) {
    $text = '';
  }
  $self->{'last_linenum'} = $linenum;
  $self->{'last_text'} = $text;
}
sub verbatim {
  my ($self, $text, $linenum, $paraobj) = @_;
  $self->{'last_text'} = '';
}
sub end_pod {
  my ($self) = @_;
  _check_last($self);
}
sub _check_last {
  my ($self) = @_;
  ### _check_last(): $self->{'last_text'}
  if ($self->{'last_text'} =~ /,\s*$/s) {
    print "$filename:$self->{'last_linenum'}:1: end comma\n";
  }
}

=pod

=head1 ONE

Using pages like,

=for Finance_Quote_Grab symbols MNG

=over 4

blah

=back

=head1 TWO

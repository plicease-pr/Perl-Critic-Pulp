# Copyright 2012, 2013, 2014 Kevin Ryde

# This file is part of Perl-Critic-Pulp.

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


# perlcritic -s RequireFinalCut RequireFinalCut.pm
# perlcritic -s RequireFinalCut /usr/share/perl5/Class/InsideOut.pm


package Perl::Critic::Policy::Documentation::RequireFinalCut;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 89;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOWEST;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### RequireFinalCut on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::RequireFinalCut->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::RequireFinalCut;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub new {
  my $class = shift;
  my $self = $class->SUPER::new (@_);
  $self->parseopts(-process_cut_cmd => 1);
  return $self;
}

# Pod::Parser doesn't hold the current line number except in a local
# variable, so have to note it here for use in end_input().
#
sub begin_input {
  my $self = shift;
  $self->SUPER::begin_input(@_);
  $self->{'last_linenum'} = 0;
}
sub preprocess_line {
  my ($self, $line, $linenum) = @_;
  ### preprocess_line(): "linenum=$linenum"
  $self->{'last_linenum'} = $linenum;
  return $line;
}

sub end_input {
  my $self = shift;
  $self->SUPER::begin_input(@_);
  if ($self->{'in_pod'}) {
    $self->violation_at_linenum_and_textpos
      ("POD doesn't end with =cut directive",
       $self->{'last_linenum'} + 1, # end of file as the position
       '',
       0);
  }
}

sub command {
  my $self = shift;
  $self->SUPER::command(@_);
  my ($command, $text, $linenum, $paraobj) = @_;
  ### $command

  if ($command eq 'cut') {
    $self->{'in_pod'} = 0;

  } elsif ($command eq 'end' || $command eq 'for') {

  } elsif ($command eq 'pod') {
    $self->{'in_pod'} = 1;

  } else {
    unless ($self->{'in_begin'}) {
      $self->{'in_pod'} = 1;
    }
  }
  ### now in_pod: $self->{'in_pod'}
  return '';
}

sub verbatim {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### verbatim ...

  # ignore entirely whitespace runs of blank lines
  return '' if $text =~ /^\s*$/;

  unless ($self->{'in_begin'}) {
    $self->{'in_pod'} = 1;
  }
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock ...

  unless ($self->{'in_begin'}) {
    $self->{'in_pod'} = 1;
  }
  return '';
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::RequireFinalCut - end POD with =cut directive

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you to end POD with a C<=cut> directive at the end of a
file.

    =head1 DOCO

    Some text.

    =cut             # ok

The idea is to have a definite end indication for human readers.  Perl and
the POD processors don't require a final C<=cut>.  On that basis this policy
is lowest priority and under the "cosmetic" theme (see L<Perl::Critic/POLICY
THEMES>).

If there's no POD in the file then a C<=cut> is not required.  Or if the POD
is not at the end of file then final C<=cut> at the end is not required.

    =head2 About foo

    =cut

    sub foo {
    }              # ok, file ends with code not POD

If there's POD at end of file but consists only of C<=begin/=end> blocks
then a C<=cut> is not required.  It's reckoned the C<=end> is enough in this
case.

    =begin wikidoc

    Entire document in wiki style.

    =end wikidoc          # ok, =cut not required

If you've got a mixture of POD and C<=begin> blocks then a C<=cut> is still
required.  The special allowance is when the only text an C<=begin> block,
presumably destined for some other markup system.

=head2 Disabling

If you don't care about a final C<=cut> you can disable C<RequireFinalCut>
from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::RequireFinalCut]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

L<Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod>,
L<Perl::Critic::Policy::Documentation::RequirePodAtEnd>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2012, 2013, 2014 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

=cut

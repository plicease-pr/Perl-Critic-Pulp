# Copyright 2009, 2010 Kevin Ryde

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


package Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 39;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOWEST;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  my $parser = Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup::Parser->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup::Parser;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  ### command: $command
  ### $text

  if ($command eq 'head1') {
    $self->{'in_NAME'} = ($text =~ /^NAME\s*$/ ? 1 : 0);
  }
  ### in_NAME now: $self->{'in_NAME'}
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock
  return $self->interpolate ($text, $linenum);
}

sub interior_sequence {
  my ($self, $command, $arg, $seq_obj) = @_;
  ### interior: $command
  ### $arg
  ### $seq_obj
  ### seq raw_text: $seq_obj->raw_text
  ### seq left_delimiter: $seq_obj->left_delimiter
  ### seq outer: do {my $outer=$seq_obj->nested; $outer&&$outer->cmd_name}

  if ($self->{'in_NAME'} && $command eq 'C') {
    my ($filename, $linenum) = $seq_obj->file_line;

    $self->violation_at_linenum
      ('C<> markup in NAME section is bad for "apropos".',
       $linenum);
  }
  return '';
}

1;
__END__

=for stopwords addon builtin Ryde nroff

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup - don't use CE<lt>E<gt> markup in a NAME section

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to write CE<lt>E<gt> markup in the NAME section of
the POD because it comes out badly in man's "apropos" database.  For
example,

=for ProhibitVerbatimMarkup allow next

    =head1 NAME

    foo - like the C<bar> program     # bad

C<pod2man> formats "CE<lt>E<gt>" using nroff macros which "man-db"'s
C<lexgrog> program doesn't expand, resulting in unattractive description
lines from C<apropos> like

    foo - like the *(C`bar*(C' program

Man's actual formatted output is fine, and the desired text is in there,
just surrounded by *(C bits.  On that basis this policy is lowest priority
and under the "cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).

The NAME section is everything from "=head1 NAME" to the next "=head1".
Other markup like "BE<lt>E<gt>", "IE<lt>E<gt>" and "FE<lt>E<gt>" are allowed
because C<pod2man> uses builtin "\fB" etc directives for them, which
C<lexgrog> recognises.

=head2 Disabling

If want markup in the NAME line, perhaps if printed output is more important
than C<apropos>, then you can always disable from your F<.perlcriticrc> in
the usual way,

    [-Documentation::ProhibitBadAproposMarkup]

As of C<Perl::Critic> 1.108 a C<## no critic (ProhibitBadAproposMarkup)>
works if the NAME part is before an C<__END__> token (but not after it, and
after it is quite common).

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::Documentation::RequirePackageMatchesPodName>,
L<Perl::Critic::Policy::Documentation::RequirePodSections>,
L<Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup>

L<man(1)>, L<apropos(1)>, L<lexgrog(1)>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2009, 2010 Kevin Ryde

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

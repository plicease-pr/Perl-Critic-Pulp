# Copyright 2012 Kevin Ryde

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


package Perl::Critic::Policy::Documentation::RequireFinalCut;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 70;

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
  return $class->SUPER::new (last_linenum => 0,
                             @_);
}

# Pod::Parser doesn't hold the current line number except in a local
# variable, so have to note it here for use in end_input().
#
sub preprocess_line {
  my ($self, $line, $linenum) = @_;
  ### preprocess_line(): "linenum=$linenum"
  $self->{'last_linenum'} = $linenum;
  return $line;
}

sub end_input {
  my ($self) = @_;
  unless ($self->cutting) {
    $self->violation_at_linenum_and_textpos
      ("POD doesn't end with =cut directive",
       $self->{'last_linenum'} + 1, # end of file as the position
       '',
       0);
  }
}

1;
__END__

=for stopwords addon Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::RequireFinalCut - end POD with =cut directive

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you to end POD with a C<=cut> directive at the end of a
file.

    =head1 DOCO

    Some text.

    =cut             # ok

The idea is to have a definite end of file indication.  This is just for
human use since Perl and the POD processors don't require a final C<=cut>.
On that basis this policy is lowest priority and under the "cosmetic" theme
(see L<Perl::Critic/POLICY THEMES>).

If there's no POD in the file then a C<=cut> is not required.  After a final
C<=cut> there can be further code or data.  A C<=cut> is mandatory in this
case of course.

    =head2 About foo

    =cut

    sub foo {    # ok
    }

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

Copyright 2012 Kevin Ryde

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

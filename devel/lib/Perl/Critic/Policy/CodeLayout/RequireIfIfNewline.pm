# Copyright 2013 Kevin Ryde

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


# /usr/share/perl5/Pod/Simple.pm          with return preceding
# /usr/share/perl5/Tk/AbstractCanvas.pm   two ifs one line
# 
# newline or label between all compound statements


# ModifierStatement
# RequireNewlineBetweenStatements
# RequireNewlineBeforeNonModifierStatement
# RequireNonModifierStatementNewline

# perlsyn
#     if EXPR
#     unless EXPR
#     while EXPR
#     until EXPR
#     when EXPR
#     for LIST
#     foreach LIST
# if (1) {
# } if (1) {
# }
# if (1) {
# } unless (1) {
# }
# if (1) {
# } while (1) {
# }
# if (1) {
# } until (1) {
# }
# if (1) {
# } for (1) {
# }
# if (1) {
# } foreach (1) {
# }

package Perl::Critic::Policy::CodeLayout::RequireIfIfNewline;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';

our $VERSION = 77;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant supported_parameters => ();
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp bugs);
use constant applies_to       => ('PPI::Statement::Compound');

my %type_is_if = (if     => 1,
                  unless => 1);

sub violates {
  my ($self, $elem, $document) = @_;
  ### elem: "$elem"

  $type_is_if{$elem->type}
    or return;   # some other compound such as "while"

  if (_elems_any_separator ($elem->child(0), $elem->schild(0))) {
    ### leading whitespace in elem itself, so ok ...
    return;
  }

  my $prev = $elem->sprevious_sibling || return;
  ($prev->isa('PPI::Statement::Compound') && $type_is_if{$prev->type})
    or return;

  if (_elems_any_separator ($prev->next_sibling, $elem)) {
    ### whitespace after prev, so ok ...
    return;
  }

  return $self->violation
    ('Put a newline in "} if (x)" so it doesn\'t look like \"elsif\" might have been intended',
     '',
     $elem);
}

sub _elems_any_separator {
  my ($from, $to) = @_;
  for (;;) {
    if ($from == $to) {
      return 0;
    }
    if ($from =~ /\n/
        || $from->isa('PPI::Statement::Null')) {
      return 1;
    }
    $from = $from->next_sibling || return 0;
  }
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireIfIfNewline - newline between consecutive if statements

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you to put a newline before a statement which would look
like a statement modifier.

    if ($x) {
      ...
    } if ($y) {       # bad
      ...
    }

The idea is that the layout C<} if () {> looks like it was meant to be
C<elsif>.

    if ($x) {
      ...
    } elsif ($y) {    # was it meant to be "elsif" like this ?
      ...
    }

An C<if> or C<elsif> may have a subtly different meaning and on that basis
this policy is under the "bugs" theme and medium severity (see
L<Perl::Critic/POLICY THEMES>).

An C<unless> statement is the same, since Perl allows C<elsif> with
C<unless>, though whether writing that is a good idea is another matter.

    unless ($x) {
      ...
    } if ($y) {       # bad
      ...
    }

    unless ($x) {
      ...
    } elsif ($y) {    # was it meant to be "elsif" like this ?
      ...
    }

Two C<if> statements written on the same line will trigger the policy.
Perhaps there should be an option for this, or an exception for the
preceding statement being all one line, or some such.

    if (1) { one; } if (2) { two; }      # bad

=head2 Statement Modifiers

This policy only applies to a statement followed by a statement.  An C<if>
etc as a "statement modifier" is allowed, and in fact putting a modifier on
the same line is generally clearest.

    do {
      ...
    } if ($x);        # ok, statement modifier

=head2 Disabling

If you don't care about this then you can disable
C<RequireIfIfNewline> from your F<.perlcriticrc> in the usual
way (see L<Perl::Critic/CONFIGURATION>),

    [-CodeLayout::RequireIfIfNewline]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2013 Kevin Ryde

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

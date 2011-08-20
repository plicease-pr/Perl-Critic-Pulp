# Copyright 2011 Kevin Ryde

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


# eg.
# perlcritic -s ProhibitArrayAssignAref /usr/lib/perl5/Template/Test.pm


package Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref;
use 5.006;
use strict;
use warnings;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Perl::Critic::Pulp;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 64;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => ('PPI::Token::Symbol',
                                      'PPI::Token::Cast');

sub violates {
  my ($self, $elem, $document) = @_;

  ($elem->isa('PPI::Token::Cast') ? $elem->content : $elem->raw_type)
    eq '@' or return;
  ### ProhibitArrayAssignAref: $elem->content

  my $thing = 'Array';
  for (;;) {
    $elem = $elem->snext_sibling || return;
    last if $elem->isa('PPI::Token::Operator');
    ### skip: ref $elem

    # @foo[1,2] gives the [1,2] as a PPI::Structure::Subscript
    # @{foo()}[1,2] gives the [1,2] as a PPI::Structure::Constructor
    # the latter is probably wrong (as of PPI 1.215)
    if ($elem->isa('PPI::Structure::Subscript')
       || $elem->isa('PPI::Structure::Constructor')) {
      if ($elem->start eq '[') {
        $thing = 'Array slice';
      } elsif ($elem->start eq '{') {
        $thing = 'Hash slice';
      }
    }
  }
  ### $thing
  ### operator: $elem->content
  $elem eq '=' or return;

  $elem = $elem->snext_sibling || return;
  ($elem->isa('PPI::Structure::Constructor') && $elem->start eq '[')
    or return;

  return $self->violation
    ("$thing assigned a [] arrayref, should it be a () list ?",
     '', $elem);
}

1;
__END__

=for stopwords addon Ryde arrayref parens Derefs

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref - don't assign an anonymous arrayref to an array

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to assign an anonymous arrayref to an array

    @array = [ 1, 2, 3 ];       # bad

The idea is that it's a rather unclear whether an arrayref is intended, or
might have meant a list like

    @array = ( 1, 2, 3 );

For the chance the C<[]> is a mistake and since it will make anyone reading
it wonder, this policy is under the "bugs" theme (see L<Perl::Critic/POLICY
THEMES>).

It's perfectly good to assign a single arrayref to an array, but put parens
to make it clear,

    @array = ( [1,2,3] );       # ok

Derefs and array and hash slices (see L<perldata/Slices>) are recognised and
treated likewise,

    @$ref = [1,2,3];            # bad to deref
    @{$ref} = [1,2,3];          # bad to deref
    @x[1,2,3] = ['a','b','c'];  # bad to array slice
    @x{'a','b'} = [1,2];        # bad to hash slice

=head2 List Assignment Parens

There's no blanket requirement for C<()> parens on an array assignment here
since it's normal and unambiguous to have a function call or C<grep> etc.

    @array = foo();
    @array = grep {/\.txt$/} @array;

The only likely problem from lack of parens is that the C<,> comma operator
has lower precedence than C<=> (see L<perlop>), so something like

    @array = 1,2,3;   # not a list

means

    @array = (1);
    2;
    3;

Normally the remaining literals in void context provoke a compile time
warning.

An intentional single element assignment is quite common though, as a
statement, for instance

    @ISA = 'My::Parent::Class';

For reference the range operator precedence is high enough,

    @array=1..10;              # fine

though of course parens are needed if concatenating some disjoint ranges
with the comma operator,

    @array = (1..5, 10..15);   # parens needed

The C<qw> form gives a list too

    @array = qw(a b c);        # fine

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2011 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses>.

=cut

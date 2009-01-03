# Copyright 2008 Kevin Ryde

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


package Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral;
use strict;
use warnings;
use List::Util qw(min max);

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities
                           is_perl_builtin
                           is_perl_builtin_with_no_arguments
                           precedence_of);

our $VERSION = 12;


sub supported_parameters { return (); }
sub default_severity     { return $SEVERITY_MEDIUM;       }
sub default_themes       { return qw(pulp bugs);          }
sub applies_to           { return 'PPI::Token::Word'; }

my %specials = ('__FILE__'    => 1,
                '__LINE__'    => 1,
                '__PACKAGE__' => 1);

sub violates {
  my ($self, $elem, $document) = @_;
  $specials{$elem} or return;

  if (is_left_of_big_comma ($elem)) {
    return $self->violation
      ("$elem is the literal string '$elem' on the left of a =>",
       '', $elem);
  }
  if (is_solo_subscript ($elem)) {
    return $self->violation
      ("$elem is the literal string '$elem' in a hash subscript",
       '', $elem);
  }
  return;
}

# Perl::Critic::Utils::is_hash_key() does a similar this to the following
# tests, identifying something on the left of "=>", or in a "{}" subscript.
# But here want to distinguish those two cases since the subscript is only a
# violation if $elem also has no siblings.  (Separate cases allow a custom
# error message too.)
#

# { __FILE__ => 123 }
# ( __FILE__ => 123 )
#
sub is_left_of_big_comma {
  my ($elem) = @_;

  my $next = $elem->snext_sibling
    || return 0;  # nothing following
  return ($next->isa('PPI::Token::Operator') && $next->content eq '=>');
}

# $hash{__FILE__}
#
#   PPI::Structure::Subscript   { ... }
#       PPI::Statement::Expression
#           PPI::Token::Word        '__PACKAGE__'
#
# and not multi subscript like $hash{__FILE__,123}
#
#   PPI::Structure::Subscript   { ... }
#     PPI::Statement::Expression
#       PPI::Token::Word        '__PACKAGE__'
#       PPI::Token::Operator    ','
#       PPI::Token::Number      '123'
#
sub is_solo_subscript {
  my ($elem) = @_;

  # must be sole elem
  if ($elem->snext_sibling) { return 0; }
  if ($elem->sprevious_sibling) { return 0; }

  my $parent = $elem->parent || return 0;
  $parent->isa('PPI::Statement::Expression') || return 0;

  my $grandparent = $parent->parent || return 0;
  return $grandparent->isa('PPI::Structure::Subscript');
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral - specials like __PACKAGE__ used literally

=head1 DESCRIPTION

This policy is part of the Perl::Critic::Pulp addon.  It picks up some cases
where the special literals C<__FILE__>, C<__LINE__> and C<__PACKAGE__> (see
L<perldata/Special Literals>) are used with C<< => >> or as a hash subscript
and so don't expand to the respective filename, line number or package name.

    my $seen = { __FILE__ => 1 };          # bad
    return ('At:'.__LINE__ => 123);        # bad
    $obj->{__PACKAGE__}->{myextra} = 123;  # bad

In each case you get a string C<"__FILE__">, C<"__LINE__"> or
C<"__PACKAGE__">, like

    my $seen = { '__FILE__' => 1 };
    return ('At:__LINE__' => 123);
    $obj->{'__PACKAGE__'}->{'myextra'} = 123;

where you almost certainly meant it to expand to the filename etc.  On that
basis this policy is under the "bugs" theme (see L<Perl::Critic/POLICY
THEMES>).

Expression forms like

    'MyExtra::'.__PACKAGE__ => 123    # bad

are still bad because the word immediately to the left of any C<< => >> is
quoted even when the word is part of an expression.

If you really do want a string C<"__FILE__"> etc then the suggestion is to
write the quotes, even if you're not in the habit of using quotes in hash
constructors etc.  It'll pass this policy and make it clear to everyone that
you really did want the literal string.

=head2 Class Data

C<< $obj->{__PACKAGE__} >> can arise when you're trying to hang extra data
on an object with your package name hopefully avoiding clashes with the
object's native fields.  An unexpanded C<__PACKAGE__> is a mistake you'll
probably only make once; after that the irritation of writing extra parens
or similar will keep it fresh in your mind!

As usual there's more than one way to do it when adding extra data to an
object.  As a crib here are some ways,

=over 4

=item Subhash C<< $obj->{(__PACKAGE__)}->{myfield} >>

The extra parens ensure expansion, and you get a sub-hash (or sub-array or
whatever) to yourself.  It's easy to delete the single entry from C<$obj>
if/when you later want to cleanup.

=item Subscript C<< $obj->{__PACKAGE__,'myfield'} >>

This makes entries in C<$obj>, with the C<$;> separator emulating
multidimensional arrays/hashes (see L<perlvar/$;>).

=item Concated key C<< $obj->{__PACKAGE__.'--myfield'} >>

Again entries in C<$obj>, but key formed by concatenation and an explicit
unlikely separator.  The advantage over C<,> is that the key is a constant
(after constant folding), instead of a C<join> on every access (for possible
new C<$;>).

=item Separate C<Tie::HashRef::Weak>

Use the object as a hash key and the value whatever data you want to
associate.  Keeps completely out of the object's hair.

=item Inside-Out C<Hash::Util::FieldHash>

Similar to HashRef with object as key and any value you want as the data,
outside the object, hence the jargon "inside out".  If you're not into OOP
you'll have to read a few times to understand what's going on!

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>, L<perldata/"Special Literals">

=head1 HOME PAGE

L<http://www.geocities.com/user42_kevin/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see L<http://www.gnu.org/licenses>.

=cut

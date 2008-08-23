# Copyright 2008 Kevin Ryde

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


package Perl::Critic::Policy::ValuesAndExpressions::LiteralSpecialLiteral;
use strict;
use warnings;
use List::Util qw(min max);

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities
                           is_perl_builtin
                           is_perl_builtin_with_no_arguments
                           precedence_of);

our $VERSION = 7;


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

  if (_is_left_of_big_comma ($elem)) {
    return $self->violation
      ("$elem is the literal string '$elem' on the left of a =>",
       '', $elem);
  }
  if (_is_solo_subscript ($elem)) {
    return $self->violation
      ("$elem is the literal string '$elem' in a hash subscript",
       '', $elem);
  }
  return;
}

# There's some similar stuff in Perl::Critic::Utils::is_hash_key(), but here
# want to distinguish => from subscript, and to check for a solitary word as
# the subscript or constructor.
#
# { __FILE__ => 123 }
# ( __FILE__ => 123 )
#
sub _is_left_of_big_comma {
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
sub _is_solo_subscript {
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

Perl::Critic::Policy::ValuesAndExpressions::LiteralSpecialLiteral - specials like __PACKAGE__ used literally

=head1 DESCRIPTION

This policy is part of the Perl::Critic::Pulp addon.  It picks up some cases
where the special literals C<__FILE__>, C<__LINE__> and C<__PACKAGE__> are
used with C<< => >> or as a hash subscript and don't expand to the
respective filename, line number or package name.

    my $seen = { __FILE__ => 1 };        # bad
    $obj->{__PACKAGE__}{myextra} = 123;  # bad

Here you end up with the string C<"__FILE__"> or C<"__PACKAGE__">, like

    my $seen = { '__FILE__' => 1 };
    $obj->{'__PACKAGE__'}->{'myextra'} = 123;

whereas you almost certainly wanted to expand to the filename or package
name.  On that basis this policy is under the "bugs" theme (see
L<Perl::Critic/POLICY THEMES>).

C<< $obj->{__PACKAGE__} >> can arise when you're trying to hang extra data
on an object, using your package name to hopefully avoid clashes with the
object's native fields.  An unexpanded C<__PACKAGE__> like this is a mistake
you'll probably only make once, after that the irritation of writing extra
parens or similar will keep it fresh in your mind!

    $obj->{(__PACKAGE__)}->{myfield}  # good
    $obj->{__PACKAGE__.'.myfield'}    # good

Don't forget that it's any time a word is immediately to the left of a
C<< => >> that it's quoted, so even in expressions like the following
C<__FILE__> and C<__PACKAGE__> are still not expanded,

    my $hash = { 'Foo'.__FILE__ => 123 };     # bad
    return ('MyExtra::'.__PACKAGE__ => 123);  # bad

If you really do want the string C<"__FILE__"> etc then the suggestion is to
write the quotes, even if you're not in the habit of using quotes in hash
constructors.  It'll pass this policy and make it clear to everyone that you
really did want the string, not an expanded name.

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

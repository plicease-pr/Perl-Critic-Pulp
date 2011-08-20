# Copyright 2009, 2010, 2011 Kevin Ryde

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


package Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline;
use 5.006;
use strict;
use warnings;
use List::Util;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_function_call is_method_call);

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 64;

use constant supported_parameters =>
  ({ name           => 'except_function_calls',
     description    => 'Don\'t demand a trailing comma in function call argument lists.',
     behavior       => 'boolean',
     default_string => '0',
   });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes   => qw(pulp cosmetic);
use constant applies_to       => qw(PPI::Structure::List
                                    PPI::Structure::Constructor);

sub violates {
  my ($self, $elem, $document) = @_;
  ### elem: ref($elem)
  ### content: "$elem"

  if ($self->{'_except_function_calls'}) {
    my $prev;
    if (($prev = $elem->sprevious_sibling)
        && $prev->isa('PPI::Token::Word')
        && (is_function_call($prev) || is_method_call($prev))) {
      ### is_function_call: !! is_function_call($prev)
      ### is_method_call: !! is_method_call($prev)
      return;
    }
  }

  my @children = $elem->children;
  @children = map {$_->isa('PPI::Statement') ? $_->children : $_} @children;
  ### children: "@children"

  if (_is_list_single_expression($elem)) {
    ### an expression not a list as such
    return;
  }

  my $newline = 0;
  my $after;
  foreach my $child (reverse @children) {
    if ($child->isa('PPI::Token::Whitespace')
        || $child->isa('PPI::Token::Comment')) {
      ### HWS ...
      $newline ||= ($child->content =~ /\n/);
      ### $newline
      $after = $child;
    } else {
      if ($newline && ! _elem_is_comma_operator($child)) {
        return $self->violation
          ('Put a trailing comma at last of a list ending with a newline',
           '',
           $after);
      }
      last;
    }
  }

  return;
}

sub _is_list_single_expression {
  my ($elem) = @_;
  $elem->isa('PPI::Structure::List')
    or return 0;

  if (List::Util::first {_elem_is_comma_operator($_)} $elem->schildren) {
    ### contains comma operator, so not an expression
    return 0;
  }

  if (my $prev = $elem->sprevious_sibling) {
    if ($prev->isa('PPI::Token::Word')
        && (is_function_call($prev) || is_method_call($prev))) {
      ### function or method call, so not an expression
      return 0;
    }

    if ($prev->isa('PPI::Token::Operator')
        && $prev eq '='
        && _is_preceded_by_array($prev)) {
      ### array assignment, so not an expression
      return 0;
    }
  }

  ### no commas, not a call, so is an expression
  return 1;
}

# $elem is a PPI::Element, return true if it's a comma operator "," or "=>"
sub _elem_is_comma_operator {
  my ($elem) = @_;
  return ($elem->isa('PPI::Token::Operator')
          && $Perl::Critic::Pulp::Utils::COMMA{$elem->content});
}

sub _is_preceded_by_array {
  my ($elem) = @_;
  ### _is_preceded_by_array: "$elem"

  my $prev = $elem->sprevious_sibling || return 0;
  while ($prev->isa('PPI::Structure::Subscript')
         || $prev->isa('PPI::Structure::Block')) {
    ### skip: ref $prev
    $prev = $prev->sprevious_sibling || return 0;
  }
  ### prev: ref $prev
  if ($prev->isa('PPI::Token::Symbol')) {
    my $cast;
    if (($cast = $prev->sprevious_sibling)
        && $cast->isa('PPI::Token::Cast')) {
      return ($cast->content eq '@');
    }
    ### raw_type: $prev->raw_type
    return ($prev->raw_type eq '@');
  }
  if ($prev->isa('PPI::Token::Cast')) {
    return ($prev->content eq '@');
  }
  return 0;
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline - comma at end of list at newline

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you to put a comma at the end of a list etc ending with a
newline,

    @array = ($one,
              $two     # bad
             );

    @array = ($one,
              $two,    # ok
             );

This makes no difference to how the code runs, so this policy is under the
"cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).

The idea is to make it easier when editing the code -- you don't have to
remember a new comma when adding an item or cutting and pasting lines to
re-arrange.

If the closing bracket is on the same line as the last element then no comma
is required.  A comma can be used if desired, but it's not required.

    $hashref = { abc => 123,
                 def => 456 };   # ok

Parens around an expression are not a list, so

    $foo = (1
            + 2
            + 3        # ok
           );

A single element paren expression is only considered a list when it's an
array assignment or a function or method call.

=head2 Disabling

As always if you don't care about this you can disable
C<RequireTrailingCommaAtNewline> from F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-CodeLayout::RequireTrailingCommaAtNewline]

=head2 Other Ways to Do It

This policy is a variation of C<CodeLayout::RequireTrailingCommas>.  That
policy doesn't apply to function calls or hashref constructors, and you may
find its requirement for a trailing comma in even one-line lists like
C<@x=(1,2,)> too much.

=head1 CONFIGURATION

=over 4

=item C<except_function_calls> (boolean, default false)

If true then function calls and method calls are not checked, allowing for
instance

    foo (
      1,
      2     # ok under except_function_calls
    );

The idea is that if C<foo()> takes only two arguments then you don't want to
write a trailing comma as it might suggest something more could be added.

Whether you write calls spread out this way is a matter of personal
preference.  If you do then enable C<except_function_calls> with the
following in your F<.perlcriticrc> file,

    [CodeLayout::RequireTrailingCommaAtNewline]
    except_function_calls=1

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::CodeLayout::RequireTrailingCommas>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011 Kevin Ryde

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

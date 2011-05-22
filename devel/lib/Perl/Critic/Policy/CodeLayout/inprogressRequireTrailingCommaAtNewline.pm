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


package Perl::Critic::Policy::CodeLayout::inprogressRequireTrailingCommaAtNewline;
use 5.006;
use strict;
use warnings;
use List::Util;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_function_call is_method_call);

use constant supported_parameters =>
  ({ name           => 'check_function_calls',
     description    => 'Whether to check trailing commas in function calls.',
     behavior       => 'boolean',
     default_string => '1',
   });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes   => qw(pulp cosmetic);
use constant applies_to       => qw(PPI::Structure::List
                                    PPI::Structure::Constructor);

sub violates {
  my ($self, $elem, $document) = @_;

  if (! $self->{'_check_function_calls'}
      and my $prev = $elem->sprevious_sibling) {
    if (is_function_call($prev) || is_method_call($prev)) {
      return;
    }
  }

  my @children = $elem->children;
  @children = map {$_->isa('PPI::Statement') ? $_->children : $_} @children;
  ### children: "@children"
  # print ref($child)," $child\n";

  if (! List::Util::first {_elem_is_comma_operator($_)} @children) {
    ### no commas, assuming not a list
    return;
  }

  my $newline = 0;
  my $after;
  foreach my $child (reverse @children) {
    if ($child->isa('PPI::Token::Whitespace')
        || $child->isa('PPI::Token::Comment')) {
      $newline ||= ($child->content =~ /\n/);
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

my %comma = (','  => 1,
             '=>' => 1);
sub _elem_is_comma_operator {
  my ($elem) = @_;
  return ($elem->isa('PPI::Token::Operator')
          && $comma{$elem->content});
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::CodeLayout::inprogressRequireTrailingCommaAtNewline - comma at end of list if newline

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to put a comma at the end of a list or anonymous
hash if there's a newline before the closing bracket.

    @array = ($one,
              $two     # bad
             );

    @array = ($one,
              $two,    # ok
             );

A trailing comma makes no difference to how the code runs, so this this
policy is under the "cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).

The idea is to make it easier when editing the code -- you don't have to
remember to insert a comma when adding a new item or when cutting and
pasting lines to re-order the items.

If the closing bracket is on the same line as the last element then you
don't have to put a comma.  You can if you want, but it's not required by
this policy.

    $hashref = { abc => 123
                 def => 456 };   # ok

This policy is a subset of C<CodeLayout::RequireTrailingCommas>, except that
policy doesn't look into hashref constructors.

=head2 Disabling

As always though you can disable C<inprogressRequireTrailingCommaAtNewline> from
your F<.perlcriticrc> in the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-CodeLayout::inprogressRequireTrailingCommaAtNewline]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

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

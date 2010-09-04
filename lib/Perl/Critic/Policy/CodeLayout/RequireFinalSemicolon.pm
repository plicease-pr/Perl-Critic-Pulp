# Copyright 2010 Kevin Ryde

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

package Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon;
use 5.006;
use strict;
use warnings;
use List::Util;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Perl::Critic::Pulp;
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 42;

use constant supported_parameters
  => ({ name           => 'except_same_line',
        description    => 'Whether to allow no semicolon at the end of blocks with the } closing brace on the same line as the last statement.',
        behavior       => 'boolean',
        default_string => '1',
      },
      { name           => 'except_expression_blocks',
        description    => 'Whether to allow no semicolon at the end of do{} expression blocks.',
        behavior       => 'boolean',
        default_string => '1',
      });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes   => qw(pulp cosmetic);
use constant applies_to       => 'PPI::Structure::Block';

sub violates {
  my ($self, $elem, $document) = @_;
  ### RequireFinalSemicolon elem: $elem->content

  if (_block_is_hash_constructor($elem)) {
    ### hash constructor, ok
    return;
  }

  my $block_last = $elem->schild(-1) || return;   # if empty
  ### block_last: ref($block_last),$block_last->content
  $block_last->isa('PPI::Statement') || do {
    ### last in block is not a PPI-Statement
    return;
  };
  if (_elem_statement_no_need_semicolon($block_last)) {
    return;
  }

  {
    my $bstat_last = $block_last->schild(-1)
      || return;   # statement shouldn't be empty, should it?
    ### bstat_last in statement: ref($bstat_last),$bstat_last->content

    if (_elem_is_semicolon($bstat_last)) {
      ### has final semicolon, ok
      return;
    }
  }

  if ($self->{'_except_expression_blocks'}) {
    if (_block_is_expression($elem)) {
      ### do expression, ok
      return;
    }
    ### not a do{} expression
  }

  # if don't have final brace then this option doesn't apply as there's no
  # final brace to be on the same line
  if ($self->{'_except_same_line'} && $elem->complete) {
    if (! _newline_in_following_sibling($block_last)) {
      ### no newline before close, ok
      return;
    }
  }

  my $report_at = $block_last->next_sibling || $block_last;
  return $self->violation
    ('Put semicolon ; on last statement in a block',
     '',
     $report_at);
}

# return true if $elem is a PPI::Statement subclass which doesn't require a
# terminating ";"
sub _elem_statement_no_need_semicolon {
  my ($elem) = @_;
  return ($elem->isa('PPI::Statement::Compound')  # for(){} etc
          || $elem->isa('PPI::Statement::Sub')    # nested named sub
          || $elem->isa('PPI::Statement::Given')
          || $elem->isa('PPI::Statement::When')
          || $elem->isa('PPI::Statement::End')    # __END__
          || $elem->isa('PPI::Statement::Null')   # ;
          || $elem->isa('PPI::Statement::UnmatchedBrace') # stray }
         );
}

# $elem is a PPI::Structure::Block.
#
# PPI 1.212 tends to be give PPI::Structure::Block for various things which
# are actually anon hash constructors and ought to be
# PPI::Structure::Constructor.  For example,
#
#     return bless { x => 123 };
#
# _block_is_hash_constructor() tries to recognise some of those blocks which
# are actually hash constructors, so as not to apply the final semicolon
# rule to hash constructors.
#
my %word_is_block = (sub => 1,
                     do => 1);
sub _block_is_hash_constructor {
  my ($elem) = @_;
  ### _block_is_hash_constructor(): ref($elem), "$elem"

  if (my $prev = $elem->sprevious_sibling) {
    ### prev: ref($prev), "$prev"
    if (! $prev->isa('PPI::Token::Word')) {
      ### anything except a word assumed an operator etc so hash constructor
      return 1;
    }
    if ($word_is_block{$prev}) {
      # "sub { ... }"
      # "do { ... }"
      ### do{}/sub{} is a block
      return 0;
    }

    if (! ($prev = $prev->sprevious_sibling)) {
      # "bless { ... }"
      # "return { ... }" etc
      # ENHANCE-ME: notice List::Util first{} and other prototyped things
      ### nothing else preceding assume pessimistically a hash
      return 1;
    }
    ### prev prev: "$prev"

    if ($prev eq 'sub') {
      # "sub foo {}"
        ### named sub not a hash
        return 0;
    }
    # "word bless { ... }"
    # "word return { ... }" etc
    ### other word preceding assume pessimistically to be a hash
    return 1;
  }

  my $parent = $elem->parent || do {
    ### umm, toplevel, is a block
    return 0;
  };

  if ($parent->isa('PPI::Statement::Compound')
      && ($parent = $parent->parent)
      && $parent->isa('PPI::Structure::List')) {
    # "func({ %args })"
    ### in a list, is a hashref
    return 1;
  }

  return 0;
}

sub _elem_is_semicolon {
  my ($elem) = @_;
  return ($elem->isa('PPI::Token::Structure') && $elem eq ';');
}

# $elem is a PPI::Node
# return true if any following sibling (not $elem itself) contains a newline
sub _newline_in_following_sibling {
  my ($elem) = @_;
  while ($elem = $elem->next_sibling) {
    if ($elem =~ /\n/) {
      return 1;
    }
  }
  return 0;
}

my %postfix_loops = (while => 1, until => 1);

my %prefix_expressions = (do => 1, map => 1, grep => 1);

# $block is a PPI::Structure::Block
# return true if it's "do{}" expression, and not a "do{}while" or "do{}until"
# loop
sub _block_is_expression {
  my ($elem) = @_;
  ### _block_is_expression(): "$elem"

  if (my $next = $elem->snext_sibling) {
    if ($next->isa('PPI::Token::Word')
        && $postfix_loops{$next}) {
      ### {}while or {}until, not an expression
      return 0;
    }
  }

  ### do{} or map{} or grep{}, are expressions
  my $prev = $elem->sprevious_sibling;
  return ($prev
          && $prev->isa('PPI::Token::Word')
          && $prefix_expressions{$prev});
}

1;
__END__

=for stopwords addon boolean hashref eg Ryde

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon - require a semicolon at the end of code blocks

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you to put a semicolon C<;> on the final statement of a
subroutine or block.

    sub foo {
      do_something();      # ok
    }
    sub bar {
      do_something()       # bad
    }

This is only a matter of style since the code runs the same either way, and
on that basis this policy is low priority and under the "cosmetic" theme
(see L<Perl::Critic/POLICY THEMES>).

The advantage of a semicolon is that if your add more code you don't have to
notice the previous line needs a terminator.  It's also more C-like, if you
consider C-like to be a virtue.

=head2 Exceptions

By default (see L</CONFIGURATION> below) a semicolon is not required when
the closing brace is on the same line as the last statement.  This is good
for constants and one-liners.

    sub foo { 'my-constant-value' }   # ok

    sub bar { return $x ** 2 }        # ok

Nor is a semicolon required in places where the last statement is an
expression giving a value, which currently means a C<do>, C<grep> or C<map>
block.

    map { some_thing();
          $_+123             # ok
        } @values;

    do {
      foo();
      1+2+3                  # ok
    }

However a C<do {} while> or C<do {} until> loop still requires a semicolon
like ordinary blocks.

    do {
      foo()                  # bad
    } until ($condition);

The last statement of a C<sub{}> is not considered an "expression" like a
C<do>.  Perhaps there could be an option to excuse all one-statement subs or
even all subs and have the policy just for nested code and control blocks.
For now the suggestion is that if a sub is big enough to need a separate
line for its result expression then write an actual C<return> statement for
maximum clarity.

=head2 Disabling

If you don't care about this you can always disable from your
F<.perlcriticrc> file in the usual way,

    [-CodeLayout::RequireFinalSemicolon]

=head1 CONFIGURATION

=over 4

=item C<except_same_line> (boolean, default true)

If true (the default) then don't demand a semicolon if the closing brace is
on the same line as the final statement.

    sub foo { return 123 }     # ok  if "except_same_line=yes"
                               # bad if "except_same_line=no"

=item C<except_expression_blocks> (boolean, default true)

If true (the default) then don't demand a semicolon at the end of an
expression block, which currently means C<do>, C<grep> and C<map>.

    # ok under "except_expression_blocks=yes"
    # bad under "except_expression_blocks=no"
    do { 1+2+3 }               
    map { $_+1 } @array
    grep {defined} @x

In the future this might also apply to C<first> from C<List::Util> and the
like, probably a hard-coded list of common things and perhaps configurable
extras.

=back

=head1 BUGS

It's very difficult to distinguish a code block from an anonymous hashref
constructor if there might be a function prototype in force, eg.

    foo { abc => 123 };

C<PPI> tends to assume it's code, C<RequireFinalSemicolon> instead assumes
hashref so as to avoid false violations.  Perhaps particular functions with
prototypes could be recognised, but in general this sort of thing is another
good reason to avoid prototypes.

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::CodeLayout::RequireTrailingCommas>,
L<Perl::Critic::Policy::Subroutines::RequireFinalReturn>,
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2010 Kevin Ryde

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

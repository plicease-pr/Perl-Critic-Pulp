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


package Perl::Critic::Policy::CodeLayout::inprogressProhibitFatCommaAfterNewline;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';

# uncomment this to run the ### lines
#use Smart::Comments;

use constant supported_parameters => ();
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp bugs);
use constant applies_to       => ('PPI::Token::Operator');

sub violates {
  my ($self, $elem, $document) = @_;

  $elem->content eq '=>'
    or return; # some other operator

  # skip preceding comments and whitespace like sprevious_sibling(), but
  # note whether a newline is seen
  my $saw_newline = 0;
  my $prev = $elem;
  for (;;) {
    $prev = $prev->previous_sibling || return;
    if ($prev->isa('PPI::Token::Comment')) {
      $saw_newline = 0;
    } elsif ($prev->isa ('PPI::Token::Whitespace')) {
      $saw_newline ||= ($prev->content =~ /\n/);
    } else {
      last;
    }
  }
  ### prev: $prev->content

  if (! $saw_newline) {
    ### "foo =>" with no newline is ok
    return;
  }

  if (! $prev->isa('PPI::Token::Word')) {
    ### not a word, => acts as a plain comma, ok
    return;
  }

  # PPI 1.213 gives a word "-print" where it should be a negate of a
  # print(), watch out for that
  my $word = $prev->content;
  (my $word_sans_dash = $word) =~ s/^-//;

  return $self->violation
    ((Perl::Critic::Utils::is_perl_builtin ($word)
      || Perl::Critic::Utils::is_perl_builtin ($word_sans_dash))
     ? "Fat comma after newline doesn't quote Perl builtin \"$word_sans_dash\""
     : "Fat comma after newline doesn't always quote a preceding bareword",
     '',
     $elem);
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::CodeLayout::inprogressProhibitFatCommaAfterNewline - new enough Test::More for its functions

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to put a newline between a fat comma and a bareword
it's meant to quote.

    my %h = (foo       # bad
             => 123);

In Perl 5.6 and earlier such a C<foo> is not quoted, instead being a
function call.

Or in Perl 5.8 and up builtins like C<print> there are not quoted, instead
executing as an expression.

    my %h = (print     # bad, "print" executes
             =>
             '123');
    # h is key "1" value 123

For reference, a "-foo" of a Perl builtin unquoted too, the "-" which
otherwise quotes a bareword doesn't affect Perl builtins,

    my %h = (-print    # bad, "print" execute and negate
             =>
             '123');
    # h is key "-1" value 123

=head2 Avoiding Problems

The idea of this policy is to avoid problems by keeping the C<=E<gt>> on the
same line as the word.

    my %h = (foo =>    # ok
             123);

If you do want a newline then a string or expression can be used

    my %h = ('foo'     # ok
             =>
             123);

Or if it really is a function call you wanted (and implicitly get in 5.6 and
earlier), then parens in the usual way ensure that.

    my %h = (foo()     # ok
             =>
             123);

In Perl 5.6, C<use strict> (strict "subs") will throw an error for an
unquoted bareword C<foo>, but if you've got a function or constant called
C<foo> then it will execute, probably giving the wrong result.  One way that
can go wrong is an accidental redefinition of a constant,

    use constant FOO => 'something';

    # makes a constant subr called something()
    use constant FOO
      => 'some value';

If C<FOO> is a number or other invalid name for a subr then new enough
versions of the C<constant> module will pick it up at runtime, but a word
like "something" here quietly expands.

Perl 5.8 up looks ahead across newlines for a C<=E<gt>> quoting a bareword
before reckoning it a function call, which means most barewords are fine.
But the same is not done for Perl builtins like C<print>, they instead
execute and many will do so successfully, or silently, leaving a return
value instead of the presumably intended word string.

=head2 Disabling

As always if you don't care about this then you can disable
C<inprogressProhibitFatCommaAfterNewline> from your F<.perlcriticrc> in the usual
way (see L<Perl::Critic/CONFIGURATION>),

    [-CodeLayout::inprogressProhibitFatCommaAfterNewline]

Perhaps this policy could report only cases where C<=E<gt>> doesn't quote,
so in 5.8 up most words are ok, only report unquoted builtins.  But
currently it's a blanket prohibition

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>, L<perlop>

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
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

=cut

# toke.c comment /* not a keyword */


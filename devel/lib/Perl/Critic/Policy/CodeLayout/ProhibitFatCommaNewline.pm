# Copyright 2009, 2010, 2011, 2013 Kevin Ryde

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


package Perl::Critic::Policy::CodeLayout::ProhibitFatCommaNewline;
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
use constant applies_to       => ('PPI::Token::Operator');

sub violates {
  my ($self, $elem, $document) = @_;

  $elem->content eq '=>'
    or return; # some other operator

  my $prev = $elem->sprevious_sibling || return;
  if (! $prev->isa('PPI::Token::Word')) {
    ### previous not a word, so => acts as a plain comma, ok ...
    return;
  }
  if (! _elems_any_newline_between ($prev, $elem)) {
    ### no newline before =>, ok ...
    return;
  }

  # PPI 1.213 gives a word "-print" where it should be a negate of a
  # print(), so check "sans dash"
  my $word = $prev->content;
  if (Perl::Critic::Utils::is_perl_builtin(_sans_dash($word))) {
    return $self->violation
      ("Fat comma after newline doesn't quote Perl builtin \"$word\"",
       '',
       $elem);
  } else {
    return $self->violation
      ("Fat comma after newline doesn't always quote a preceding bareword",
       '',
       $elem);
  }
}

# return $str stripped of a leading "-", if it has one
sub _sans_dash {
  my ($str) = @_;
  $str =~ s/^-//;
  return $str;
}

# $from and $to are PPI::Element
# Return true if there's a "\n" newline anywhere in between those elements,
# not including either $from or $to themselves.
sub _elems_any_newline_between {
  my ($from, $to) = @_;
  if ($from == $to) { return 0; }
  for (;;) {
    $from = $from->next_sibling || return 0;
    if ($from == $to) { return 0; }
    if ($from =~ /\n/) { return 1; }
  }
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::CodeLayout::ProhibitFatCommaNewline - keep a fat comma on the same line as its quoted word

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you not to put a newline between a fat comma and the
bareword it's meant to quote.

    my %h = (foo          # bad
             => 123);

This is bad if "foo" is a Perl builtin such as C<print> since it will
execute rather than be quoted.  And in Perl 5.6 such a C<foo> was never
quoted, instead executing as a named function.

    my %h = (print        # bad, "print" executes
             => '123');
    # h is key "1" value "123"

On this basis this policy is under the "bugs" theme (see
L<Perl::Critic/POLICY THEMES>), and medium severity.

The same applies to dashed barewords such as "-print" since as Perl builtins
they're also not quoted if there's a newline before the fat comma,

    my %h = (-print       # bad, "print" execute and negate result
             => '123');
    # h is key "-1" value "123"

C<-print> like this is the "-" negate operator and the C<print> builtin.
A fat comma on the same line quotes it, but not a fat comma after a newline.

=head2 Avoiding Problems

The idea of this policy is to keep the C<=E<gt>> on the same line as the
word to avoid any problems with whether it's a builtin, or a future edit
might make it a builtin, and in ccase it might be run on older Perl.

    my %h = (foo =>       # ok
             123);

If for layout purposes you do want a newline then the suggestion is to give
a string or expression, since that doesn't rely on the C<=E<gt>> quoting.

    my %h = ('foo'        # ok
             =>
             123);

If a function call is in fact what's intended then parens is in the usual
way ensure it's a call.

    my %h = (foo()        # ok
             =>
             123);

Perl will sometimes detect unquoted barewords like this itself.  In Perl 5.6
with C<use strict> (for strict "subs") an error is thrown for an unquoted
bareword C<foo> if there's no function or constant C<foo>.  One way that can
go wrong is an accidental redefinition of a constant,

    use constant FOO => 'blah';

    use constant FOO       # makes a constant subr called blah
      => 'some value';     # when run in Perl 5.6

If C<FOO> is a number or other name which C<constant.pm> considers invalid
then new enough versions of that module will detect it at runtime, but a
name like "blah" here quietly expands.

Perl 5.8 up looks ahead across newlines for a C<=E<gt>> quoting a bareword
before reckoning it a function call, which means most barewords are fine.
But the same is not done for Perl builtins like C<print>, they instead
execute and many will do so successfully, or silently, leaving a return
value instead of the presumably intended word string.

=head2 Disabling

As always if you don't care about this then you can disable
C<ProhibitFatCommaNewline> from your F<.perlcriticrc> in the usual
way (see L<Perl::Critic/CONFIGURATION>),

    [-CodeLayout::ProhibitFatCommaNewline]

Perhaps this policy could report only cases where C<=E<gt>> doesn't quote,
so in 5.8 up most words are ok, only report unquoted builtins.  But
currently it's a blanket prohibition

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>, L<perlop>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2011, 2013 Kevin Ryde

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

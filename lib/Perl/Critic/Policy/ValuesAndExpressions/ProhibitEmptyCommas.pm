# Copyright 2008, 2009, 2010 Kevin Ryde

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


package Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Perl::Critic::Pulp::Utils;

our $VERSION = 41;


sub supported_parameters { return; }
sub default_severity { return $Perl::Critic::Utils::SEVERITY_LOW; }
sub default_themes   { return qw(pulp cosmetic);      }
sub applies_to       { return 'PPI::Token::Operator'; }

sub violates {
  my ($self, $elem, $document) = @_;

  $Perl::Critic::Pulp::Utils::COMMA{$elem} or return;

  my $prev = $elem->sprevious_sibling;
  if ($prev && ! ($prev->isa('PPI::Token::Operator')
                  && $Perl::Critic::Pulp::Utils::COMMA{$prev})) {
    # have a previous element and it's not a comma operator
    return;
  }

  # A statement like
  #
  #     return bless({@_}, $class)
  #
  # is parsed by PPI as
  #
  #     PPI::Structure::List        ( ... )
  #       PPI::Statement::Compound
  #         PPI::Structure::Block   { ... }
  #           PPI::Statement
  #             PPI::Token::Magic   '@_'
  #       PPI::Statement::Expression
  #         PPI::Token::Operator    ','
  #         PPI::Token::Symbol      '$class'
  #
  # so the "{@_}" bit is not an immediate predecessor of the "," operator.
  # If our $elem has no $prev then also look outwards to see if it's at the
  # start of an expression which is in a list and there's something
  # preceding in the list.
  #
  if (! $prev) {
    my $parent = $elem->parent;
    if ($parent->isa('PPI::Statement::Expression')
        && $parent->parent->isa('PPI::Structure::List')
        && $parent->sprevious_sibling) {
      return;
    }
  }

  # $prev is either nothing or a comma operator
  return $self->violation ('Empty comma operator',
                           '',
                           $elem);
}

1;
__END__

=for stopwords addon Ryde

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas - disallow empty consecutive commas

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It prohibits empty comma operators C<,> or C<=E<gt>> meaning either
consecutive commas or a comma at the start of a list or expression.

    print 'foo',,'bar';      # bad
    @a = (,1,2);             # bad
    foo (x, => 123);         # bad
    a =>=> 456;              # bad
    for (; $i++<10; $i++,,)  # bad
    func (,)                 # bad

Extra commas like this are harmless and simply collapse out when the program
runs (see L<perldata/List value constructors>), so this policy is only under
the "cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).  Usually this sort
of thing is just a stray, or leftover from cut and paste, or perhaps some
over-enthusiastic column layout.  Occasionally it can be something more
dubious,

    # did you mean 1..6 range operator?
    @a = (1,,6);        # bad

    # this is two args, did you want three?
    foo (1, , 2);       # bad

    # this is three args, probably you forgot a value
    bar (abc => ,       # bad
         def => 20);

A comma at the end of a list or call is allowed.  That's quite usual and can
be a good thing when cutting and pasting lines (see C<RequireTrailingCommas>
to mandate them!).

    @b = ("foo",
          "bar",  # ok
         );

If you use multiple commas in some systematic way for code layout you can
always disable C<ProhibitEmptyCommas> from your F<.perlcriticrc> file in the
usual way,

    [-ValuesAndExpressions::ProhibitEmptyCommas]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>,
L<Perl::Critic::Policy::CodeLayout::RequireTrailingCommas>,
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitCommaSeparatedStatements>,
L<Perl::Critic::Policy::Tics::ProhibitManyArrows>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2008, 2009, 2010 Kevin Ryde

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

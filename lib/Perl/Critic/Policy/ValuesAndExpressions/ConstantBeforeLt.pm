# Copyright 2008, 2009 Kevin Ryde

# This file is part of Perl-Critic-Pulp.

# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see
# <http://www.gnu.org/licenses/>.


package Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities
                           is_included_module_name
                           is_method_call
                           is_perl_builtin_with_no_arguments
                           split_nodes_on_comma);

our $VERSION = 16;

# set this to 1 for some diagnostic prints
use constant DEBUG => 0;

#
# Incidentally "require Foo < 123" is a similar sort of problem in all Perls
# (or at least up to 5.10.0) with "<" being taken to be a "< >".  But since
# it always provokes a warning when run it doesn't really need perlcritic,
# or if it does then leave it to another policy to address.
#

sub supported_parameters { return ();               }
sub default_severity     { return $SEVERITY_MEDIUM; }
sub default_themes       { return qw(pulp bugs);    }
sub applies_to           { return 'PPI::Document';  }

sub violates {
  my ($self, $document) = @_;

  my @violations;
  my %constants;
  my $constants = \%constants;
  $document->find
    (sub {
       my ($document, $elem) = @_;
       @constants{ _use_constants($elem) } = 1;  # hash slice
       push @violations, _one_violate ($self, $elem, $constants);
       return 0;  # no-match, and continue
     });
  return @violations;
}

sub _one_violate {
  my ($self, $elem, $constants) = @_;
  if (! $elem->isa ('PPI::Token::Word')) { return; }

  # eg. "use constant FOO => 123; if (FOO < 456) {}" is ok, for a constant
  # defined at the point in question
  if (exists $constants->{$elem->content}) { return; }

  # eg "time < 123" is ok
  if (is_perl_builtin_with_no_arguments ($elem)) { return; }

  # eg. "bar" in "$foo->bar < 123" is ok
  if (is_method_call ($elem)) { return; }

  # eg. "Foo" in "require Foo" is not a constant
  if (is_included_module_name ($elem)) { return; }


  # must be followed by "<" like "MYBAREWORD < 123"
  my $lt = $elem->snext_sibling or return;
  $lt->isa('PPI::Token::Operator') or return;
  $lt->content eq '<' or return;

  # if a ">" somewhere later like "foo <...>" then it's probably a function
  # call on a readline or glob
  #
  my $after = $lt;
  for (;;) {
    $after = $after->snext_sibling or last;
    if ($after->content eq '>') {
      return;
    }
  }

  return $self->violation ('Bareword constant before "<"',
                           '', $elem);
}

# $elem is any element.  If it's a "use constants" or a "sub foo () { ...}"
# then return the name or names of the constants so created.  Otherwise
# return an empty list.
#
# Perl::Critic::StricterSubs::Utils::find_declared_constant_names() does
# some similar stuff, but it crunches the whole document at once, instead of
# just one statement.
#
sub _use_constants {
  my ($elem) = @_;

  if ($elem->isa ('PPI::Statement::Sub')) {
    if ($elem->prototype eq '()') {
      if (my $name = $elem->name) {
        return $name;
      }
    }
    # anonymous sub or without prototype
    return;
  }

  if (! $elem->isa ('PPI::Statement::Include')) { return; }
  if ($elem->type ne 'use') { return; }
  if (($elem->module || '') ne 'constant') { return; }

  $elem = $elem->schild(2) or return; # could be "use constant" alone
  if (DEBUG) { print "  start at ",$elem->content,"\n"; }

  my $single = 1;
  if ($elem->isa ('PPI::Structure::Constructor')) {
    # multi-constant "use constant { FOO => 1, BAR => 2 }"
    #
    # PPI::Structure::Constructor         { ... }
    #   PPI::Statement
    #     PPI::Token::Word        'foo'
    #
    $single = 0;
    # multiple constants
    $elem = $elem->schild(0)
      or return;  # empty on "use constant {}"
    goto SKIPSTATEMENT;

  } elsif ($elem->isa ('PPI::Structure::List')) {
    # single constant in parens "use constant (FOO => 1,2,3)"
    #
    # PPI::Structure::List        ( ... )
    #   PPI::Statement::Expression
    #     PPI::Token::Word        'Foo'
    #
    $elem = $elem->schild(0)
      or return;  # empty on "use constant {}"

  SKIPSTATEMENT:
    if ($elem->isa ('PPI::Statement')) {
      $elem = $elem->schild(0) or return;
    }
  }

  # split_nodes_on_comma() handles oddities like "use constant qw(FOO 1)"
  #
  my @nodes = _elem_and_ssiblings ($elem);
  my @arefs = split_nodes_on_comma (@nodes);

  if (DEBUG >= 2) {
    require Data::Dumper;
    print Data::Dumper::Dumper(\@arefs);
  }

  if ($single) {
    $#arefs = 0;  # first elem only
  }
  my @constants;
  for (my $i = 0; $i < @arefs; $i += 2) {
    my $aref = $arefs[$i];
    if (@$aref == 1) {
      my $name_elem = $aref->[0];
      if (! $name_elem->isa ('PPI::Token::Structure')) {  # not final ";"
        push @constants, ($name_elem->can('string')
                          ? $name_elem->string
                          : $name_elem->content);
        next;
      }
    }
    if (DEBUG) {
      require Data::Dumper;
      print "ConstantBeforeLt: skip non-name constant: ",
        Data::Dumper::Dumper($aref);
    }
  }
  return @constants;
}

sub _elem_and_ssiblings {
  my ($elem) = @_;
  my @ret;
  while ($elem) {
    push @ret, $elem;
    $elem = $elem->snext_sibling;
  }
  return @ret;
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt - disallow bareword before <

=head1 DESCRIPTION

This policy is part of the Perl::Critic::Pulp addon.  It prohibits a
bareword before a C<E<lt>> to keep you out of trouble with autoloaded or
unprototyped constant subs since a C<E<lt>> in that case is interpreted as
the start of a C<E<lt>..E<gt>> glob or readline instead of a less-than.
This policy is under the C<bugs> theme (see L<Perl::Critic/POLICY THEMES>).

    use POSIX;
    DBL_MANT_DIG < 32   # bad, perl 5.8 thinks <>

    func <*.c>          # ok, actual glob
    time < 2e9          # ok, builtins parse ok

    use constant FOO => 16;
    FOO < 32            # ok, your own const

    sub BAR () { 64 }
    BAR < 32            # ok, your own prototyped sub

The fix for something like C<DBL_MANT_DIG E<lt> 10> is parens either around
or after, like

    (DBL_MANT_DIG) < 10  # ok
    DBL_MANT_DIG() < 10  # ok

whichever you think is less worse.  The latter emphasises it's really a sub.

The key is whether the constant sub in question is defined and has a
prototype at the time the code is compiled.  ConstantBeforeLt makes the
pessimistic assumption that anything except C<use constant> and prototyped
subs in your own file shouldn't be relied on.

In practice the most likely problems are with the C<POSIX> module constants
of Perl 5.8.x and earlier, since they were unprototyped.  The default code
generated by C<h2xs> (as of Perl 5.10.0) is similar autoloaded unprototyped
constants so modules using the bare output of that suffer too.

If you're confident the modules you use don't play tricks with their
constants (including only using POSIX on Perl 5.10.0 or higher) then you
might find ConstantBeforeLt too pessimistic.  It normally triggers rather
rarely anyway, but you can always disable it altogether in your
F<.perlcriticrc> file,

    [-ValuesAndExpressions::ConstantBeforeLt]

=head1 OTHER NOTES

Bareword file handles might be misinterpreted by this policy as constants,
but in practice "<" doesn't get used with anything taking a bare filehandle.

A constant used before it's defined, like

    if (FOO < 123) { ... }   # bad
    ...
    use constant FOO => 456;

is reported by ConstantBeforeLt since it might be an imported constant sub,
even if it's much more likely to be a simple mis-ordering, which C<use
strict> picks up anyway when it runs.

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

=head1 HOME PAGE

L<http://www.geocities.com/user42_kevin/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see L<http://www.gnu.org/licenses/>.

=cut

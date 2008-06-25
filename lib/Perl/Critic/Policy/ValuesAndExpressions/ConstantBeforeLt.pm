# Copyright 2008 Kevin Ryde

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

our $VERSION = 1;

# set this to 1 for some diagnostic prints
use constant DEBUG => 0;

#
# Incidentally "require Foo < 123" is a similar sort of problem in all Perls
# (or at least up to 5.10.0) with "<" being taken to be a "< >".  But since
# it always provokes a warning when run it doesn't really need perlcritic,
# or if it does then leave it to another policy to address.
#


sub supported_parameters { return ();                 }
sub default_severity     { return $SEVERITY_MEDIUM;   }
sub default_themes       { return qw(bugs);           }
sub applies_to           { return 'PPI::Document'; }

sub violates {
  my ($self, $document) = @_;

  # no problem in perl 5.10 and up
  my $version = $document->highest_explicit_perl_version;
  if ($version && $version >= 'v5.10.0') {
    return;
  }

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

# Return a list of constants defined, if $elem is a "use constants", or
# return an empty list if it's something else.
#
# Perl::Critic::StricterSubs::Utils::find_declared_constant_names() does
# some similar stuff, but it crunches the whole document at once, instead of
# the way we want to look progressively to know what's defined so far at a
# given point.
#
sub _use_constants {
  my ($elem) = @_;
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
      my $elem = $aref->[0];
      if (! $elem->isa ('PPI::Token::Structure')) {  # not final ";"
        push @constants, ($elem->can('string')
                          ? $elem->string
                          : $elem->content);
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

This policy is part of the Perl-Critic-Pulp addon.  It prohibits a bareword
before a C<E<lt>> to keep you out of trouble on Perl prior to 5.10.0, where
such an C<E<lt>> is interpreted as the start of a C<E<lt>..E<gt>> readline
or glob, instead of a less-than.  On that basis this policy is under the
C<bugs> theme.

    use POSIX;
    DBL_MANT_DIG < 32   # bad, perl 5.8 thinks <>

    func <*.c>          # ok, actual glob
    time < 2e9          # ok, builtins parse ok

    use constant FOO => 16;
    FOO < 32            # ok on own constant

The fix for something like C<DBL_MANT_DIG E<lt> 10> is parens either around
or after, like C<(DBL_MANT_DIG) E<lt> 10> or C<DBL_MANT_DIG() E<lt> 10>,
whichever you think is less awful.

If you've got an explicit C<use> of Perl 5.10 or higher the policy is
skipped, since there's no problem there.

    use 5.010;
    DBL_MANT_DIG < 10    # ok in perl 5.10

If you only use Perl 5.10 but don't bother putting that in your sources then
disable this policy in your F<.perlcriticrc> file in the usual way

    [-ValuesAndExpressions::ConstantBeforeLt]

=head1 OTHER NOTES

Bareword file handles might be misinterpreted by this policy as constants,
but in practice a "<" doesn't get used with anything taking a bare
filehandle.

PPI version 1.203 doesn't parse v-strings like C<use v5.10.0>, so that won't
be recognised as a 5.10 to suppress this policy.  Use C<use 5.010> style
instead.

=head1 SEE ALSO

L<Perl::Critic>

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

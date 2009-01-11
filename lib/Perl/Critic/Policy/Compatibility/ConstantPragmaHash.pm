# Copyright 2008, 2009 Kevin Ryde

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


package Perl::Critic::Policy::Compatibility::ConstantPragmaHash;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities);
use version;

our $VERSION = 13;

use constant DEBUG => 0;


sub supported_parameters { return; }
sub default_severity { return $SEVERITY_MEDIUM; }
sub default_themes   { return qw(pulp compatibility); }
sub applies_to       { return 'PPI::Document';  }

my $perl_ok_version = version->new('5.008');
my $constant_ok_version = version->new('1.03');

sub violates {
  my ($self, $elem, $document) = @_;

  my @violations;
  my $perlver; # a "version" object
  my $modver;  # a "version" object

  my $aref = $document->find ('PPI::Statement::Include');
  foreach my $inc (@$aref) {

    $inc->type eq 'use'
      || ($inc->type eq 'require' && _in_BEGIN($inc))
        || next;

    if (my $ver = $inc->version) {
      # "use 5.008" etc perl version
      $ver = version->new ($ver);
      if (! defined $perlver || $ver > $perlver) {
        $perlver = $ver;

        if ($perlver >= $perl_ok_version) {
          # adequate perl version demanded, stop here
          last;
        }
      }
      next;
    }

    ($inc->module||'') eq 'constant' || next;

    if (my $ver = _include_module_version ($inc)) {
      $ver = version->new ($ver);
      if (! defined $modver || $ver > $modver) {
        $modver = $ver;

        if ($modver >= $constant_ok_version) {
          # adequate "constant" version demanded, stop here
          last;
        }
      }
    }

    if (_use_constant_is_multi ($inc)) {
      push @violations, $self->violation
        ("'use constant' with multi-constant hash requires perl 5.8 or constant 1.03 (at this point have "
         . (defined $perlver ? "perl $perlver" : "no perl version")
         . (defined $modver ? ", constant $modver)" : ", no constant version)"),
         '',
         $inc);
    }
  }

  return @violations;
}

# $inc is a PPI::Statement::Include with type "use" and module "constant".
# Return true if it has a multi-constant hash as its argument like
# "use constant { X => 1 };"
#
# The plain "use constant { x=>1 }" comes out as
#
#   PPI::Statement::Include
#     PPI::Token::Word    'use'
#     PPI::Token::Word    'constant'
#     PPI::Structure::Constructor         { ... }
#       PPI::Statement
#         PPI::Token::Word        'x'
#         PPI::Token::Operator    '=>'
#         PPI::Token::Number      '1'
#
# Or as of PPI 1.203 with a version number "use constant 1.03 { x=>1 }" is
# different
#
#   PPI::Statement::Include
#     PPI::Token::Word    'use'
#     PPI::Token::Word    'constant'
#     PPI::Token::Number::Float   '1.03'
#     PPI::Structure::Block       { ... }
#       PPI::Statement
#         PPI::Token::Word        'x'
#         PPI::Token::Operator    '=>'
#         PPI::Token::Number      '1'
#
sub _use_constant_is_multi {
  my ($inc) = @_;
  my $arg = _include_module_first_arg ($inc)
    || return 0; # empty "use constant" or version "use constant 1.05"
  return ($arg->isa('PPI::Structure::Constructor') # without version number
          || $arg->isa('PPI::Structure::Block'));  # with version number
}


# $inc is a PPI::Statement::Include.
# If it has a version number for a module "use" or "no" then return that
# element.  As of PPI 1.203 there's no v-number parsing, so the version
# element is always a PPI::Token::Number.
#
# A "require" is treated the same as "use" and "no", though a module version
# number like "require Foo::Bar 1.5" is actually a syntax error.
#
# A module version is a literal number following the module name, with
# either nothing else after it, or with no comma for the arglist.
#
sub _include_module_version {
  my ($inc) = @_;
  defined ($inc->module) || return undef;
  my $ver = $inc->schild(2) || return undef;
  $ver->isa('PPI::Token::Number') || return undef;
  my $after = $ver->snext_sibling;
  if ($after
      && $after->isa('PPI::Token::Operator')
      && ($after eq ',' || $after eq '=>')) {
    return undef;
  }
  return $ver;
}

# $inc is a PPI::Statement::Include.
# Return the element which is the start of the first argument to its "use"
# import or "no" unimport.
#
# A "require" is treated the same as "use" and "no", though arguments to it
# like "require Foo::Bar '-init';" is in fact a syntax error.
#
sub _include_module_first_arg {
  my ($inc) = @_;
  defined ($inc->module) || return undef;
  my $arg;
  if (my $ver = _include_module_version ($inc)) {
    $arg = $ver->snext_sibling;
  } else {
    # eg. "use Foo 'xxx'"
    $arg = $inc->schild(2);
  }
  # don't return terminating ";"
  if ($arg
      && $arg->isa('PPI::Token::Structure')
      && $arg->content eq ';'
      && ! $arg->snext_sibling) {
    return undef;
  }
  return $arg;
}

# return true if $elem is somewhere within a BEGIN block
sub _in_BEGIN {
  my ($elem) = @_;
  while ($elem = $elem->parent) {
    if ($elem->isa('PPI::Statement::Scheduled')) {
      return ($elem->type eq 'BEGIN');
    }
  }
  return 0;
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::Compatibility::ConstantPragmaHash - new enough "constant" module for multiple constants

=head1 DESCRIPTION

This policy is part of the C<Perl::Critic::Pulp> addon.  It requires that
when you use the hash style multiple constants with C<use constant> you
explicitly declare either Perl 5.8 or C<constant> 1.03, or higher.

    use constant { AA => 1, BB => 2 };       # bad

    use 5.008;
    use constant { CC => 1, DD => 2 };       # ok

    use constant 1.03;
    use constant { EE => 1, FF => 2 };       # ok

    use constant 1.03 { GG => 1, HH => 2 };  # ok

The idea is to keep you from using the multi-constant feature in code which
might run on Perl 5.6 or might in principle still run there.  On that basis
this policy is under the "compatibility" theme (see L<Perl::Critic/POLICY
THEMES>).

If you declare C<constant 1.03> then the code can still run on Perl 5.6 and
perhaps earlier if the user gets a suitably newer C<constant> module from
CPAN.  Or of course for past compatibility just don't use the hash style at
all!

=head2 Details

A version declaration must be before the first multi-constant, so it's
checked before the multi-constant is attempted (and gives an obscure error).

    use constant { X => 1, Y => 2 };       # bad
    use 5.008;

A C<require> for the perl version is not adequate since the C<use constant>
is at C<BEGIN> time, before plain code.

    require 5.008;
    use constant { X => 1, Y => 2 };       # bad

But a C<require> within a C<BEGIN> block is ok (an older style, still found
occasionally).

    BEGIN { require 5.008 }
    use constant { X => 1, Y => 2 };       # ok

    BEGIN {
      require 5.008;
      and_other_setups ...;
    }
    use constant { X => 1, Y => 2 };       # ok

Currently ConstantPragmaHash pays no attention to any conditionals within
the C<BEGIN>, it assumes any C<require> there always runs.  It could be
tricked by some obscure tests but hopefully anything like that is rare.

A quoted version number like

    use constant '1.03';    # no good

is no good, only a bare number is recognised by C<use> and acted on by
ConstantPragmaHash.  A string like that goes through to C<constant> as if a
name to define (which you'll see it objects to as soon as you try run it).

=head2 Drawbacks

Explicitly adding version numbers to your code can be irritating if other
modules you're using only run on 5.8 anyway.  But declaring what your own
code wants is accurate, it allows maybe for backports of those other things,
and explicit versions can be grepped out to create or check F<Makefile.PL>
or F<Build.PL> prereqs.

As always if you don't care about this and in particular if you only ever
use Perl 5.8 anyway then you can disable C<ConstantPragmaHash> from your
F<.perlcriticrc> in the usual way,

    [-Compatibility::ConstantPragmaHash]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>,
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma>,
L<Perl::Critic::Policy::Modules::RequirePerlVersion>

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
Perl-Critic-Pulp.  If not, see L<http://www.gnu.org/licenses>.

=cut

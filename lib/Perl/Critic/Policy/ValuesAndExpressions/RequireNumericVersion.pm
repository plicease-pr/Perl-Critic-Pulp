# Copyright 2011 Kevin Ryde

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


package Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion;
use 5.006;
use strict;
use warnings;
use Scalar::Util;
use version ();

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils 'precedence_of';
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant supported_parameters => ();
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp bugs);
use constant applies_to       => ('PPI::Token::Symbol');

my $perl_510 = version->new('5.10.0');
my $assignment_precedence = precedence_of('=');

our $VERSION = 63;

sub violates {
  my ($self, $elem, $document) = @_;
  ### NumericVersion violates()

  ### canonical: $elem->canonical
  $elem->canonical eq '$VERSION' ## no critic (RequireInterpolationOfMetachars)
    or return;

  {
    my $package = Perl::Critic::Pulp::Utils::elem_package($elem)
      || return; # not in a package, not a module $VERSION
    if ($package->namespace eq 'main') {
      return; # explicit "package main", not a module $VERSION
    }
  }

  my $assign = $elem->snext_sibling || return;
  ### assign: "$assign"
  $assign eq '=' or return;

  my $value = $assign->snext_sibling || return;
  ### value: "$value"
  if (! $value->isa('PPI::Token::Quote')) {
    ### an expression not a string
    return;
  }

  if (_following_expression ($value)) {
    ### can't check an expression ...
    return;
  }

  my $str = $value->string;
  if ($value->isa ('PPI::Token::Quote::Double')
      || $value->isa ('PPI::Token::Quote::Interpolate')) {
    ### double quote, check only up to an interpolation
    $str =~ s/[\$\@].*//;
  }

  # float number strings like "1e6" rejected by version.pm
  # they work in 5.8.x but not in 5.10.x, disallow them always
  #
  if (! defined(Perl::Critic::Pulp::Utils::version_if_valid($str))) {
    return $self->violation
      ('Non-numeric VERSION string (not recognised by version.pm)',
       '',
       $value);
  }
  my $got_perl = $document->highest_explicit_perl_version;
  if (defined $got_perl && $got_perl >= $perl_510) {
    # for 5.10 up only need to satisfy version.pm
    return;
  }

  # for 5.8 or unspecified version must be plain number, not "1.2.3" etc
  if (! Scalar::Util::looks_like_number($str)) {
    return $self->violation ('Non-numeric VERSION string',
                             '',
                             $value);
  }
  return;
}

sub _following_expression {
  my ($elem) = @_;
  my $after = $elem->snext_sibling
    or return 0;

  if ($after->isa('PPI::Token::Structure')) {
    return 0;
  } elsif ($after->isa('PPI::Token::Operator')) {
    if (precedence_of($after) >= $assignment_precedence) {
      return 0;
    }
    if ($after eq '.') {
      return 0;
    }
  }
  return 1;
}


1;
__END__

=for stopwords addon toplevel ie CPAN pre-release args exponentials multi-dots v-nums YYYYMMDD Ryde

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion - $VERSION a plain number

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It ask you to use a plain number in a module C<$VERSION> so that
Perl's builtin version works.  This policy is under the C<bugs> theme (see
L<Perl::Critic/POLICY THEMES>).

Any literal number is fine, or a string which is a number, and for Perl 5.10
up the extra forms of the C<version> module too,

    $VERSION = 123;           # ok
    $VERSION = '1.5';         # ok
    $VERSION = 1.200_001;     # ok
    $VERSION = '1.200_001';   # ok for 5.10 up

But a non-numeric string is not allowed,

    $VERSION = '1.2alpha';    # bad

A number is needed for version checking like

    use Foo 1.0;
    Foo->VERSION(1);

and it's highly desirable so applications can do compares like

    if (Foo->VERSION >= 1.234) {

In each case a non-numeric string in C<$VERSION> provokes warnings, and may
end up appearing as a lesser version than intended.

    Argument "1.2.alpha" isn't numeric in subroutine entry

If you've loaded the C<version.pm> module, then a C<$VERSION> not accepted
by C<version.pm> will in fact croak

    use version ();
    print "version ",Foo->VERSION,"\n";
    # croaks "Invalid version format ..." if $Foo::VERSION is bad

=head2 Scripts

This policy only looks at C<$VERSION> in modules.  C<$VERSION> in a script
can be anything, as it won't normally have a C<use> checks etc.  A script
C<$VERSION> is anything outside any C<package> statement scope, or under an
explicit C<package main>.

    package main;
    $VERSION = '1.5.prerelease';  # ok, script

=head2 Underscores in Perl 5.8 and Earlier

In Perl 5.8 and earlier a string like "1.200_333" is truncated to the
numeric part, ie. 1.200, and can thus fail to satisfy

    $VERSION = '1.222_333';   # bad
    $VERSION = 1.222_333;     # ok

    use Foo 1.222_331;  # unsatisfied by $VERSION='string' form

A number literal with an "_" is allowed.  Underscores in literals are
stripped out (see L<perldata>), but not in the automatic string to number
conversion so a string like C<$VERSION = '1.222_333'> provokes a warning and
stops at 1.222.

On CPAN an underscore in a distribution version number is rated a developer
pre-release.  But don't put it in module C<$VERSION> strings due to the
problems above.  The suggestion is to either omit the underscore or make it
a number literal not a string,

    $VERSION = 1.002003;      # ok
    $VERSION = 1.002_003;     # ok

If using C<ExtUtils::MakeMaker> then it may be necessary to put an explicit
C<VERSION> in F<Makefile.PL> to get the underscore in the dist name, since
C<VERSION_FROM> a module file takes both the above to be 1.002003.

=head2 C<version> module in Perl 5.10 up

In Perl 5.10 the C<use> etc module version checks parse C<$VERSION> with the
C<version.pm> module.  This policy allows the C<version> module forms if
there's an explicit C<use 5.010> or higher in the file.

    use 5.010;
    $VERSION = '1.222_333';   # ok for 5.10
    $VERSION = '1.2.3';       # ok for 5.10

But this is still undesirable, as an application check like

    if (Foo->VERSION >= 1.234) {

gets the raw string from C<$VERSION> and thus a non-numeric warning and
truncation.  Perhaps applications should let C<UNIVERSAL.pm> do the check
with say

    if (eval { Foo->VERSION(1.234) }) {

or apply C<version-E<gt>new()> to one of the args.  (Maybe another policy to
not explicitly compare C<$VERSION>, or perhaps an option to tighten this
policy to require numbers even in 5.10?)

=head2 Exponential Format

Exponential format strings like "1e6" are disallowed.  Exponential number
literals are fine.

    $VERSION = '2.125e6';   # bad
    $VERSION = 1e6;         # ok

Exponential strings don't work in Perl 5.10 because they're not recognised
by the C<version> module (v0.82).  They're fine in Perl 5.8 and earlier, but
in the interests of maximum compatibility this policy treats such a string
as non-numeric.  Exponentials in versions should be unusual anyway.

=head2 Disabling

If you don't care about this policy at all then you can disable from your
F<.perlcriticrc> in the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-ValuesAndExpressions::RequireNumericVersion]

=head2 Other Ways to Do It

All the version number stuff with underscores, multi-dots, v-nums, etc is a
diabolical mess, and floating point in version checks is asking for rounding
error trouble (though normally fine in practice).  A radical simplification
is to just use integer version numbers.

    $VERSION = 123;

If you want sub-versions then increment by 100 say.  Even a YYYYMMDD date is
a possibility.

    $VERSION = 20110328;

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

L<Perl::Critic::Policy::Modules::RequireVersionVar>,
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitComplexVersion>,
L<Perl::Critic::Policy::ValuesAndExpressions::RequireConstantVersion>

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings>,
L<Perl::Critic::Policy::Modules::ProhibitUseQuotedVersion>

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


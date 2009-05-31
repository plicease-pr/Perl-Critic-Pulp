# Copyright 2008, 2009 Kevin Ryde

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


package Perl::Critic::Pulp;
use strict;
use warnings;

our $VERSION = 18;


# The code here is shared by some of the modules, or might one day get into
# perlcritic or PPI directly.  In any case it's meant for private use only.


# This regexp is what Perl's toke.c S_force_version() demands, as of
# versions 5.004 through 5.8.9.  A version number in a "use" must start with
# a digit and then have only digits, dots and underscores.  In particular
# other normal numeric forms like hex or exponential are not taken to be
# version numbers, and even omitting the 0 from a decimal like ".25" is not
# a version number.
#
our $use_module_version_number_re = qr/^v?[0-9][0-9._]*$/;

# $inc is a PPI::Statement::Include.
# If it has a version number for a module "use" or "no" then return that
# element.  As of PPI 1.203 there's no v-number parsing, so the version
# element is always a PPI::Token::Number.
#
# A "require" is treated the same as "use" and "no", though a module version
# number like "require Foo::Bar 1.5" is actually a syntax error.
#
# A module version is a literal number following the module name, with
# either nothing else after it, or with no comma before the arglist.
#
sub include_module_version {
  my ($inc) = @_;

  # only a module style "use Foo", not a perl version num like "use 5.010"
  defined ($inc->module) || return undef;

  my $ver = $inc->schild(2) || return undef;
  # ENHANCE-ME: when PPI recognises v-strings may have to extend this
  $ver->isa('PPI::Token::Number') || return undef;

  $ver->content =~ $use_module_version_number_re or return undef;

  # when followed by a comma it's an argument not a version number,
  # eg. "use Foo 1.0, 'hello'"
  if (my $after = $ver->snext_sibling) {
    if ($after->isa('PPI::Token::Operator')
        && ($after eq ',' || $after eq '=>')) {
      return undef;
    }
  }

  return $ver;
}

# $inc is a PPI::Statement::Include.
# Return the element which is the start of the first argument to its
# import() or unimport(), for "use" or "no" respectively.
#
# A "require" is treated the same as "use" and "no", but arguments to it
# like "require Foo::Bar '-init';" is in fact a syntax error.
#
sub include_module_first_arg {
  my ($inc) = @_;
  defined ($inc->module) || return undef;
  my $arg;
  if (my $ver = include_module_version ($inc)) {
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

1;
__END__

=head1 NAME

Perl::Critic::Pulp - some add-on perlcritic policies

=head1 DESCRIPTION

This is a collection of the following add-on policies for C<Perl::Critic>.
They're under a new "pulp" theme plus other themes according to their
function (see L<Perl::Critic/POLICY THEMES>).

=over 4

=item L<Compatibility::ConstantPragmaHash|Perl::Critic::Policy::Compatibility::ConstantPragmaHash>

Version declaration for hash style multi-constants.

=item L<Compatibility::Gtk2Constants|Perl::Critic::Policy::Compatibility::Gtk2Constants>

New enough Gtk2 version for its constants.

=item L<Documentation::RequireEndBeforeLastPod|Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod>

__END__ before POD at end of file.

=item L<Miscellanea::TextDomainPlaceholders|Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders>

Check args to C<__x> and C<__nx>.

=item L<Miscellanea::TextDomainUnused|Perl::Critic::Policy::Miscellanea::TextDomainUnused>

Locale::TextDomain imported but not used.

=item L<Modules::ProhibitUseQuotedVersion|Perl::Critic::Policy::Modules::ProhibitUseQuotedVersion>

Unquoted version string in C<use Foo '1.5'>

=item L<ValuesAndExpressions::ConstantBeforeLt|Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt>

Avoiding problems with C<< FOO < 123 >>

=item L<ValuesAndExpressions::NotWithCompare|Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare>

Avoiding problems with C<! $x == $y>

=item L<ValuesAndExpressions::ProhibitEmptyCommas|Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas>

Stray consecutive commas C<,,>

=item L<ValuesAndExpressions::ProhibitNullStatements|Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements>

Stray semicolons  C<;>

=item L<ValuesAndExpressions::UnexpandedSpecialLiteral|Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral>

Literal use of __PACKAGE__ etc.

=back

Roughly half are about bugs and half cosmetic.  You can always enable or
disable the ones you do or don't want.  You'll have realized there's a lot
of perlcritic builtin and add-on policies and they range from the helpful to
the bizarre, and in some cases are even mutually contradictory.  So it's
quite normal to pick and choose what you want reported.  If you're not
turning off about a quarter and customizing others then either you're not
trying or you're much too easily lead!

=head1 OTHER NOTES

In a lot of the perlcritic docs, including Pulp here, policy names appear
without the full C<Perl::Critic::Policy::...> class name.  In Emacs have a
look at my C<man-completion.el> to automatically get the man page from a
suffix part (at point), or C<ffap-perl-module.el> to go to the source
similarly.

=over 4

L<http://www.geocities.com/user42_kevin/man-completion/index.html>

L<http://www.geocities.com/user42_kevin/ffap-perl-module/index.html>

=back

Or in perlcritic's output you can ask for %P for the full name to paste or
follow.  Here's a good format you can put in your F<.perlcriticrc> with a
file:line:column: which Emacs will recognise (see L<Perl::Critic::Violation>
for C<%> escapes).

    verbose=%f:%l:%c:\n %P\n %m\n

F<perlcritic.el> has patterns to match the perlcritic builtin formats, but
it's easier to print file:line:column: in the first place.

=head1 SEE ALSO

L<Perl::Critic>

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

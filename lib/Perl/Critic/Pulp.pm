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


package Perl::Critic::Pulp;
use 5.006;
use strict;
use warnings;
use version;

our $VERSION = 28;


# The code here is shared by some of the modules, or might one day get into
# perlcritic or PPI directly.  In any case it's meant for private use only.


# a parser function for a "supported_parameters" entry taking a version
# number as a string
#
sub parameter_parse_version {
  my ($self, $parameter, $str) = @_;

  my $version;
  if (defined $str && $str ne '') {
    $version = version_if_valid ($str);
    if (! defined $version) {
      $self->throw_parameter_value_exception
        ($parameter->get_name,
         $str,
         undef, # source
         'invalid version number string');
    }
  }
  $self->{$parameter->get_name} = $version;
}

# return a version.pm object, or undef if invalid
sub version_if_valid {
  my ($str) = @_;
  # this is a nasty hack to notice "not a number" etc warnings
  my $good = 1;
  my $version;
  { local $SIG{'__WARN__'} = sub { $good = 0 };
    $version = version->new($str);
  }
  return ($good ? $version : undef);
}

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

  # must be followed by whitespace, or comment, or end of statement, so
  #
  #    use Foo 10 -3;    <- version 10, arg -3
  #    use Foo 10-3;     <- arg 7
  #
  #    use Foo 10#       <- version 10, arg -3
  #    -3;
  #
  if (my $after = $ver->next_sibling) {
    unless ($after->isa('PPI::Token::Whitespace')
            || $after->isa('PPI::Token::Comment')
            || ($after->isa('PPI::Token::Structure')
                && $after eq ';')) {
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
  defined ($inc->module) || return;
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
    return;
  }
  return $arg;
}

1;
__END__

=head1 NAME

Perl::Critic::Pulp - some add-on perlcritic policies

=head1 DESCRIPTION

This is a collection of add-on policies for C<Perl::Critic>, summaried in
the sections below.  They're under a new "pulp" theme plus other themes
according to their purpose (see L<Perl::Critic/POLICY THEMES>).

Roughly half are code related and half cosmetic.  You can always enable or
disable the ones you do or don't want.  It's normal to pick and choose what
you want reported.  There's a lot of perlcritic builtin and add-on policies
and they range from helpful things catching problems, to the bizarre or
restrictive, and in some cases are mutually contradictory!  Many are
intended as building blocks for enforcing a house style.  If you try to pass
everything then you give away big parts of the language, so if you're not
turning off or customizing about half then either you're not trying or
you're much too easily lead!

=head2 Bugs

=over 4

=item L<Miscellanea::TextDomainPlaceholders|Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders>

Check keyword arguments to C<__x>, C<__nx>, etc.

=item L<Modules::ProhibitUseQuotedVersion|Perl::Critic::Policy::Modules::ProhibitUseQuotedVersion>

Don't quote version requirement C<use Foo '1.5'>

=item L<ValuesAndExpressions::ConstantBeforeLt|Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt>

Avoid problems with C<< FOO < 123 >>

=item L<ValuesAndExpressions::NotWithCompare|Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare>

Avoid problems with C<! $x == $y>

=item L<ValuesAndExpressions::ProhibitFiletest_f|Perl::Critic::Policy::ValuesAndExpressions::ProhibitFiletest_f>

Don't use C<-f>.

=item L<ValuesAndExpressions::UnexpandedSpecialLiteral|Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral>

Literal use of C<__PACKAGE__> etc.

=back

=head2 Compatibility

=over 4

=item L<Compatibility::ConstantPragmaHash|Perl::Critic::Policy::Compatibility::ConstantPragmaHash>

Perl version for hash style multi-constants.

=item L<Compatibility::Gtk2Constants|Perl::Critic::Policy::Compatibility::Gtk2Constants>

Gtk2 module version for its constants.

=item L<Compatibility::PerlMinimumVersionAndWhy|Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy>

Perl version declared against features used.

=item L<Compatibility::PodMinimumVersion|Perl::Critic::Policy::Compatibility::PodMinimumVersion>

Perl version declared against POD features used.

=item L<Compatibility::ProhibitUnixDevNull|Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull>

Prefer C<File::Spec-E<gt>devnull> over explicit F</dev/null>.

=back

=head2 Efficiency

=over 4

=item L<Documentation::RequireEndBeforeLastPod|Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod>

Put C<__END__> before POD, at end of file.

=item L<Miscellanea::TextDomainUnused|Perl::Critic::Policy::Miscellanea::TextDomainUnused>

C<Locale::TextDomain> imported but not used.

=item L<Modules::ProhibitPOSIXimport|Perl::Critic::Policy::Modules::ProhibitPOSIXimport>

Don't import the whole of C<POSIX>.

=back

=head2 Cosmetic

=over 4

=item L<Documentation::ProhibitBadAproposMarkup|Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup>

Avoid CE<lt>E<gt> in NAME section, bad for man's "apropos" output.

=item L<ValuesAndExpressions::ProhibitEmptyCommas|Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas>

Stray consecutive commas C<,,>

=item L<ValuesAndExpressions::ProhibitNullStatements|Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements>

Stray semicolons C<;>

=item L<ValuesAndExpressions::ProhibitUnknownBackslash|Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash>

Unknown C<\z> etc escapes in strings.

=back

=head1 OTHER NOTES

In most of the perlcritic documentation, including the Pulp here, policy
names appear without the full C<Perl::Critic::Policy::...> class name.  In
Emacs have a look at C<man-completion.el> to automatically get the man page
from a suffix part at point, or C<ffap-perl-module.el> to go to the source
similarly.

    http://user42.tuxfamily.org/man-completion/index.html

    http://user42.tuxfamily.org/ffap-perl-module/index.html

In perlcritic's output you can ask for %P for the full policy name to copy
or follow.  Here's a good format you can put in your F<.perlcriticrc>,
including file:line:column: which Emacs will recognise.  See
L<Perl::Critic::Violation> for all the C<%> escapes.

    verbose=%f:%l:%c:\n %P\n %m\n

F<perlcritic.el> has patterns to match the builtin formats, but it's easier
to print file:line:column: in the first place.

=head1 SEE ALSO

L<Perl::Critic>

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

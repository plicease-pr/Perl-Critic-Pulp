# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

our $VERSION = 46;

1;
__END__

=for stopwords perlcritic builtin multi-constants Gtk2 Gtk2Constants perlcritic's Ryde barewords

=head1 NAME

Perl::Critic::Pulp - some add-on perlcritic policies

=head1 DESCRIPTION

This is a collection of add-on policies for C<Perl::Critic>, summarized
below.  They're under a "pulp" theme plus other themes according to their
purpose (see L<Perl::Critic/POLICY THEMES>).

Roughly half are code related and half cosmetic.  You can always enable or
disable the ones you do or don't want.  It's normal to pick and choose
things reported.  There's a lot of perlcritic policies both built-in and
add-on and they range from helpful things catching problems through to the
bizarre or restrictive, and in some cases mutually contradictory!  Many are
only intended as building blocks for enforcing a house style.  If you try to
pass everything then you'll give away big parts of the language, so if
you're not turning off or customizing about half then you're either not
trying or you're much too easily lead!

=head2 Bugs

=over

=item L<Miscellanea::TextDomainPlaceholders|Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders>

Check keyword arguments to C<__x>, C<__nx>, etc.

=item L<Modules::ProhibitUseQuotedVersion|Perl::Critic::Policy::Modules::ProhibitUseQuotedVersion>

Don't quote version requirement C<use Foo '1.5'>

=item L<ValuesAndExpressions::RequireNumericVersion|Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion>

C<$VERSION> a plain number for comparisons and checking.

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

=over

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

=over

=item L<Documentation::RequireEndBeforeLastPod|Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod>

Put C<__END__> before POD, at end of file.

=item L<Miscellanea::TextDomainUnused|Perl::Critic::Policy::Miscellanea::TextDomainUnused>

C<Locale::TextDomain> imported but not used.

=item L<Modules::ProhibitPOSIXimport|Perl::Critic::Policy::Modules::ProhibitPOSIXimport>

Don't import the whole of C<POSIX>.

=back

=head2 Cosmetic

=over

=item L<CodeLayout::RequireFinalSemicolon|Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon>

Semicolon C<;> on the last statement of a subroutine or block.

=item L<ValuesAndExpressions::ProhibitEmptyCommas|Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas>

Stray consecutive commas C<,,>

=item L<ValuesAndExpressions::ProhibitNullStatements|Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements>

Stray semicolons C<;>

=item L<ValuesAndExpressions::ProhibitUnknownBackslash|Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash>

Unknown C<\z> etc escapes in strings.

=item L<ValuesAndExpressions::ProhibitBarewordDoubleColon|Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon>

Double-colon barewords C<Foo::Bar::>

=item L<Modules::ProhibitModuleShebang|Perl::Critic::Policy::Modules::ProhibitModuleShebang>

No C<#!> interpreter line in F<.pm> files.

=back

=head2 Documentation

=over

=item L<Documentation::ProhibitBadAproposMarkup|Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup>

Avoid CE<lt>E<gt> in NAME section, bad for man's "apropos" output.

=item L<Documentation::ProhibitVerbatimMarkup|Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup>

Verbatim paragraphs not expanding CE<lt>E<gt> markup etc.

=back

=head1 OTHER NOTES

In most of the perlcritic documentation, including the Pulp stuff here,
policy names appear without the full C<Perl::Critic::Policy::...> class
part.  In Emacs try C<man-completion.el> to have C<M-x man> automatically
expand a suffix part at point, or C<ffap-perl-module.el> to go to the source
similarly.

    http://user42.tuxfamily.org/man-completion/index.html

    http://user42.tuxfamily.org/ffap-perl-module/index.html

In perlcritic's output you can ask for %P for the full policy name to copy
or follow.  Here's a good format you can put in your F<.perlcriticrc>,
including file:line:column: style Emacs will recognise.

    verbose=%f:%l:%c:\n %P\n %m\n

See L<Perl::Critic::Violation> for all the C<%> escapes.  F<perlcritic.el>
has patterns for Emacs to match the builtin perlcritic formats, but it's
easier to print file:line:column:.

=head1 SEE ALSO

L<Perl::Critic>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

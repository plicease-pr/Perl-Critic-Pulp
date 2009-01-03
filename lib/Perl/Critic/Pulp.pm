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

our $VERSION = 12;

1;
__END__

=head1 NAME

Perl::Critic::Pulp - some add-on perlcritic policies

=head1 DESCRIPTION

This is a collection of the following add-on policies for C<Perl::Critic>.
They're under a new "pulp" theme, plus other themes according to their
function (see L<Perl::Critic/POLICY THEMES>).

=over 4

=item ConstantBeforeLt -- avoiding problems with C<< FOO < 123 >>

See L<Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt>.

=item ConstantPragmaHash -- version declaration for hash style multi-constants

See L<Perl::Critic::Policy::Compatibility::ConstantPragmaHash>.

=item NotWithCompare -- avoiding problems with C<! $x == $y>

See L<Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare>.

=item ProhibitEmptyCommas -- stray consecutive commas

See L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas>.

=item ProhibitNullStatements -- stray semicolons

See L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements>.

=item RequireEndBeforeLastPod -- __END__ before POD at end of file

See L<Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod>.

=item TextDomainPlaceholders -- check args to C<__x> and C<__nx>

See L<Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders>.

=item UnexpandedSpecialLiteral -- literal use of __PACKAGE__ etc

See L<Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral>.

=back

Roughly half are about bugs and half cosmetic.  You can always enable or
disable the ones you do or don't want.  You'll have realized there's a lot
of perlcritic builtin and add-on policies and they range from the sublime to
the bizarre.  In some cases they're even mutually contradictory.  So it's
quite normal to pick and choose what you want reported!

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
Perl-Critic-Pulp.  If not, see L<http://www.gnu.org/licenses>.

=cut

# Copyright 2009 Kevin Ryde

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


package Perl::Critic::Policy::Modules::ProhibitUseQuotedVersion;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities);
use version;
use Perl::Critic::Pulp;

our $VERSION = 26;

use constant DEBUG => 0;


sub supported_parameters { return; }
sub default_severity     { return $SEVERITY_MEDIUM;   }
sub default_themes       { return qw(pulp bugs);      }
sub applies_to           { return 'PPI::Statement::Include'; }

sub violates {
  my ($self, $elem, $document) = @_;

  defined ($elem->module) || return;    # if a "use 5.005" etc
  my $arg = $elem->schild(2) || return; # if a "use Foo" with no args
  $arg->isa('PPI::Token::Quote') || return;
  _elem_is_last_of_statement ($arg) || return;

  # This is a strict match of what a module version number is like.
  # Previously looser forms like '.500' were matched too, but of course
  # unquoting that doesn't give something that's checked by perl itself.
  # There don't seem to be forms like .500 used in practice, so don't think
  # it's important.
  #
  my $str = $arg->string;
  $str =~ $Perl::Critic::Pulp::use_module_version_number_re
    or return;

  return $self->violation
    ("Don't use a quoted string version number in a \"use\" statement",
     '',
     $arg);
}

# return true if $elem is the last thing in its statement, apart from an
# optional terminating ";"
#
sub _elem_is_last_of_statement {
  my ($elem) = @_;
  my $next = $elem->snext_sibling;
  return (! $next
          || ($next->isa('PPI::Token::Structure')
              && $next eq ';'
              && ! $next->snext_sibling));
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitUseQuotedVersion - avoid quoted version number string in a "use" statement

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It prohibits a quoted version number string as the sole argument to
a C<use> or C<no> statement.

    use Foo::Bar '1.50';      # bad
    use Foo::Bar 1.50;        # ok

    no Abc::Def '2.000_010';  # bad
    no Abc::Def 2.000_010;    # ok

The unquoted form uses Perl's builtin module version check and always works.
The quoted form relies on the module in question to do the check.  If it has
no C<import> then the quoted form is silently ignored, without the intended
check.

L<C<Exporter>|Exporter> which is used by many modules provides an C<import>
that checks a version number arg, so those modules are fine.  But the idea
of this policy is to do what works always, and on that basis is under the
"bugs" theme (see L<Perl::Critic/POLICY THEMES>).

The policy only applies to a single version number string argument, anything
else is taken to be some module parameter.

    no Abc::Def '123', 'ABC';   # ok
    use lib '..';               # ok

If you're a bit nervous about floating point version numbers because they're
often not exactly representable in binary, well that's true, but in practice
it works out ok, due to either converting the same way everywhere in the
program or being treated as a string in the "version" module anyway.

If you're confident about the C<import> in modules you use and prefer the
string form you can always disable C<ProhibitUseQuotedVersion> from your
F<.perlcriticrc> in the usual way,

    [-Modules::ProhibitUseQuotedVersion]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2009 Kevin Ryde

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

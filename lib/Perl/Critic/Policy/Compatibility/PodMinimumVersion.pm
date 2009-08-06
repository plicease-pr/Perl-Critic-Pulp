# Copyright 2009 Kevin Ryde

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


package Perl::Critic::Policy::Compatibility::PodMinimumVersion;
use 5.006;
use strict;
use warnings;
use Pod::MinimumVersion;
use base 'Perl::Critic::Policy';
use Perl::Critic::Pulp;
use Perl::Critic::Utils qw(:severities);

our $VERSION = 20;

use constant DEBUG => 0;

sub default_severity { return $SEVERITY_LOW;  }
sub default_themes   { return qw(pulp compatibility); }
sub applies_to       { return 'PPI::Document';   }

sub supported_parameters {
  return ({ name        => 'above_version',
            description => 'Check only things above this version of Perl.',
            behavior    => 'string',
            parser      => \&Perl::Critic::Pulp::parameter_parse_version,
          });
}

sub violates {
  my ($self, $document) = @_;

  my $doc_version = $document->highest_explicit_perl_version;
  my $str = $document->serialize;
  my $pmv = Pod::MinimumVersion->new (string => $str,
                                      above_version => $doc_version,
                                      one_report_per_version => 1,
                                     );
  my @reports = $pmv->reports;
  @reports = sort {$a->{'version'} <=> $b->{'version'}} @reports;
  return map {
    my $report = $_;
    my $violation = $self->violation
      ("Pod requires perl $report->{'version'} due to: $report->{'why'}.",
       '', $document);
    _violation_override_linenum ($violation, $str, $report->{'linenum'});

  } @reports;
}

# Hack to set Perl::Critic::Violation location to $linenum in $doc_str.
# Have thought about validating _location and _source fields before mangling
# them, but hopefully there'll be a documented interface to use before long.
#
sub _violation_override_linenum {
  my ($violation, $doc_str, $linenum) = @_;

  $violation->{'_location'} = [ $linenum, 1, 1 ];
  $violation->{'_source'} = _str_line_n ($doc_str, $linenum);
  return $violation;
}

sub _str_line_n {
  my ($str, $n) = @_;
  $n--;
  return ($str =~ /^(.*\n){$n}(.*)/ ? $2 : '');
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::Compatibility::PodMinimumVersion - check Perl version declared against POD features used

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It checks that the POD features you use don't exceed your target
Perl version as indicated by C<use 5.008> etc.

    use 5.005;

    =pod

    C<< something >>     # bad, no angles before 5.006

POD doesn't affect how the code runs, so this policy is low priority, and
under the "compatibility" theme (see L<Perl::Critic/POLICY THEMES>).

See L<C<Pod::MinimumVersion>|Pod::MinimumVersion> for the POD version checks
applied.  The key idea is for instance when targeting Perl 5.005 to avoid
using double-angles S<C<CE<lt>E<lt> E<gt>E<gt>>>, since C<pod2man> in 5.005
didn't support them.  It's always possible to get newer versions of the POD
translators from CPAN, but whether they run on an older Perl and whether you
want to require that of users is another matter.

Adding the sort of C<use 5.006> etc to declare a target Perl can be a bit
tedious.  The config option below lets you set a base version you use.  As
always if you don't care at all about this sort of thing you can disable the
policy from your F<.perlcriticrc> in the usual way,

    [-Compatibility::PodMinimumVersion]

=head2 Other Notes

S<C<JE<lt>E<lt> E<gt>E<gt>>> for L<C<Pod::MultiLang>|Pod::MultiLang> is
recognised and is allowed for any Perl, including its double-angles.  The
assumption is that if you're writing that then you'll be crunching it with
the C<Pod::MultiLang> tools, so it's not important what C<pod2man> thinks of
it.

The C<Compatibility::RequirePodLinkText> policy asks you to use the
C<LE<lt>target|displayE<gt>> style always.  That feature is new in Perl
5.005 and will be reported by C<PodMinimumVersion> unless you've got C<use
5.005> or higher or set C<above_version> below.

=head1 CONFIGURATION

=over 4

=item C<above_version> (version string, default none)

Report only things about Perl versions above this.  The string is any
version number style L<C<version.pm>|version> understands.  For example if
you always use Perl 5.6 or higher then set

    [Compatibility::PodMinimumVersion]
    above_version = 5.006

The effect is that all POD features up to and including Perl 5.6 are
allowed, only things above that will be reported (and still only those
exceeding any C<use 5.xxx> in the file).

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Pod::MinimumVersion>, L<Perl::Critic>,
L<Perl::Critic::Policy::Compatibility::RequirePodLinkText>

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

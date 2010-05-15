# Copyright 2009, 2010 Kevin Ryde

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


package Pod::MinimumVersion;
use 5.005;
use strict;
use warnings;
use List::Util;
use version;
use vars qw($VERSION @CHECKS);

$VERSION = 37;

use constant DEBUG => 0;

sub new {
  my ($class, %self) = @_;
  $self{'want_reports'} ||= 'one_per_version';
  return bless \%self, $class;
}

sub minimum_version {
  my ($self) = @_;
  my $report = $self->minimum_report || return undef;
  return $report->{'version'};
}
sub minimum_report {
  my ($self) = @_;
  if (! exists $self->{'minimum_report'}) {
    $self->{'minimum_report'}
      = List::Util::reduce {$a->{'version'} > $b->{'version'} ? $a : $b}
        $self->reports;
  }
  return $self->{'minimum_report'};
}
sub reports {
  my ($self) = @_;
  $self->analyze;
  return @{$self->{'reports'} || []};
}

sub analyze {
  my ($self) = @_;
  return if $self->{'analyzed'};
  $self->{'analyzed'} = 1;

  if (DEBUG) { print "MinVer analyze\n"; }

  my %checks;
  foreach my $elem (@CHECKS) {
    my ($func, $command, $version) = @$elem;
    next if ($self->{'above_version'} && $version <= $self->{'above_version'});
    push @{$checks{$command}}, $func;
  }
  return if (! %checks);

  my $parser = Pod::MinimumVersion::Parser->new (pmv    => $self,
                                                 checks => \%checks);
  if (exists $self->{'string'}) {
    $parser->parse_from_string ("$self->{'string'}");
  } elsif (exists $self->{'filehandle'}) {
    $parser->parse_from_filehandle ($self->{'filehandle'});
  } elsif (exists $self->{'filename'}) {
    $parser->parse_from_file ($self->{'filename'});
  }
}

#------------------------------------------------------------------------------
# 5.004
#
# E<> newly documented in 5.004, but is in pod2man right back to 5.002, so
# don't report that

{
  my $v5004 = version->new('5.004');

  # =for, =begin, =end new in 5.004
  #
  push @CHECKS, [ \&_check_for_begin_end, 'command', $v5004 ];
  my %for_begin_end = (for => 1, begin => 1, end => 1);
  sub _check_for_begin_end {
    my ($self, $command, $text, $para_obj) = @_;
    if ($for_begin_end{$command}) {
      $self->report ('for_begin_end', $v5004, $para_obj, "=$command command");
    }
  }
}

#------------------------------------------------------------------------------
# 5.005

{
  my $v5005 = version->new('5.005');

  # L<display|target> display alternative new in 5.005
  #
  push @CHECKS, [ \&_check_link_display_text, 'interior_sequence', $v5005 ];
  sub _check_link_display_text {
    my ($self, $command, $arg, $seq_obj) = @_;
    if ($command eq 'L' && $arg =~ /\|/) {
      $self->report ('link_display_text', $v5005, $seq_obj,
                     'Display text L<display|target> link');
    }
  }
}

#------------------------------------------------------------------------------
# 5.006

{
  my $v5006 = version->new('5.006');

  push @CHECKS, [ \&_check_double_angles, 'interior_sequence', $v5006 ];
  sub _check_double_angles {
    my ($self, $command, $arg, $seq_obj) = @_;

    if ($seq_obj->left_delimiter =~ /^<</) {
      $self->report ('double_angles', $v5006, $seq_obj,
                     'Double angle brackets C<< foo >>');
    }
  }
}

#------------------------------------------------------------------------------
# 5.008

{
  my $v5008 = version->new('5.008');

  # =head3 and =head4 new in 5.8.0
  push @CHECKS, [ \&_check_head34, 'command', $v5008 ];
  my %head34 = (head3 => 1, head4 => 1);
  sub _check_head34 {
    my ($self, $command, $text, $para_obj) = @_;
    if ($head34{$command}) {
      $self->report ('head34', $v5008, $para_obj, "=$command command");
    }
  }

  # E<sol> and E<verbar> documented in 5.6.0, but Pod::Man only has them in
  # 5.8.0, so rate them as a 5008 feature
  #
  # E<apos> is in Pod::Man of 5.8.0, though not documented explicitly
  #
  push @CHECKS, [ \&_check_E_5008, 'interior_sequence', $v5008 ];
  my %E_5008 = (apos => 1, sol => 1, verbar => 1);
  sub _check_E_5008 {
    my ($self, $command, $arg, $seq_obj) = @_;

    if ($command eq 'E' && $E_5008{$arg}) {
      $self->report ('E_5008', $v5008, $seq_obj, "E<$arg> escape");
    }
  }

  # L<http://...> urls new in 5.8.0
  #
  # In 5.6 and earlier the "/" is interpreted as a section, so from
  # L<http://foo.com/index.html> you get something bad like
  #
  #    the section on "/foo.com/index.html" in the http: manpage
  #
  # Crib note: a "|" display text part is not allowed with a url, according
  # to perlpodspec of perl 5.10.0 under the "Authors wanting to link to a
  # particular (absolute) URL" bullet point.  So no need to watch for that
  # in applying this test.
  #
  push @CHECKS, [ \&_check_link_url, 'interior_sequence', $v5008 ];
  sub _check_link_url {
    my ($self, $command, $arg, $seq_obj) = @_;
    # this regexp as recommended by perlpodspec of perl 5.10.0
    if ($command eq 'L' && $arg =~ m/\A\w+:[^:\s]\S*\z/) {
      $self->report ('link_url', $v5008, $seq_obj,
                     'URL in L<> link');
    }
  }
}

#------------------------------------------------------------------------------
# 5.010

{
  my $v5010 = version->new('5.010');

  # =encoding documented in 5.8.0, but Pod::Man doesn't recognise it until
  # 5.10.0, so rate it as a 5010 feature
  #
  push @CHECKS, [ \&_check_encoding, 'command', $v5010 ];
  sub _check_encoding {
    my ($self, $command, $text, $para_obj) = @_;
    if ($command eq 'encoding') {
      $self->report ('encoding', $v5010, $para_obj, '=encoding command');
    }
  }
}

#------------------------------------------------------------------------------

sub report {
  my ($self, $name, $version, $pod_obj, $why) = @_;

  if ($self->{'want_reports'} eq 'one_per_check') {
    return if ($self->{'seen'}->{$name}++);
  }
  if ($self->{'want_reports'} eq 'one_per_version') {
    return if ($self->{'seen'}->{$version}++);
  }

  my ($filename, $linenum) = $pod_obj->file_line;
  if (defined $self->{'filename'}) {
    $filename = $self->{'filename'};
  }
  push @{$self->{'reports'}},
    Pod::MinimumVersion::Report->new (filename => $filename,
                                      name     => $name,
                                      linenum  => $linenum,
                                      version  => $version,
                                      why      => $why);
}

package Pod::MinimumVersion::Report;
use strict;
use warnings;
use overload '""' => \&as_string;

sub new {
  my ($class, %self) = @_;
  return bless \%self, $class;
}

# not sure about this ...
sub as_string {
  my ($self) = @_;
  return "$self->{'filename'}:$self->{'linenum'}: $self->{'version'} due to $self->{'why'}";
}

package Pod::MinimumVersion::Parser;
use strict;
use warnings;
use base 'Pod::Parser';

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->errorsub ('error_handler'); # method name
  return $self;
}
sub error_handler {
  my ($self, $errmsg) = @_;
  return 1;  # error handled
}

# sub begin_input {
#   print "begin_input\n";
# }
# sub end_input {
#   print "end_input\n";
# }

sub parse_from_string {
  my ($self, $str) = @_;

  require IO::String;
  my $fh = IO::String->new ($str);
  $self->{_INFILE} = "(string)";
  return $self->parse_from_filehandle ($fh);
}

sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  if (DEBUG) { print "command: $command -- ",
                 (defined $text ? $text : 'undef'), "\n"; }

  if ($command eq 'for'
      && $text =~ /^Pod::MinimumVersion\s+use\s+(v?[0-9._]+)/) {
    $self->{'pmv'}->{'for_version'} = version->new($1);
  }

  foreach my $func (@{$self->{'checks'}->{'command'}}) {
    $func->($self->{'pmv'}, $command, $text, $paraobj);
  }
  return '';
}

sub verbatim {
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  if (DEBUG) {
    print "textblock\n";
  }
  return $self->interpolate ($text, $linenum);
}

sub interior_sequence {
  my ($self, $command, $arg, $seq_obj) = @_;
  if (DEBUG) {
    print "interior: $command -- $arg seq=$seq_obj\n";
    print "  raw_text ", $seq_obj->raw_text, "\n";
    print "  left ", $seq_obj->left_delimiter, "\n";
    if (my $outer = $seq_obj->nested) {
      print "  nested ", $outer->cmd_name, "\n";
    }
  }

  # J<> from Pod::MultiLang -- doubled C<<>> or L<|display> are allowed
  # ENHANCE-ME: might prefer to make parse_tree() not descend into J<> at
  # all, but it doesn't seem setup for that
  my $outer;
  if ($command eq 'J'
      || (($outer = $seq_obj->nested) && $outer->cmd_name eq 'J')) {
    return '';
  }

  foreach my $func (@{$self->{'checks'}->{'interior_sequence'}}) {
    $func->($self->{'pmv'}, $command, $arg, $seq_obj);
  }
  return '';
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Pod::MinimumVersion - Perl version for POD directives used

=head1 SYNOPSIS

 use Pod::MinimumVersion;
 my $pmv = Pod::MinimumVersion->new (filename => '/some/foo.pl');
 print $pmv->minimum_version,"\n";
 print $pmv->reports;

=head1 DESCRIPTION

B<Caution: This is work in progress.>

C<Pod::MinimumVersion> parses the POD in a Perl script, module, or document,
and reports what version of Perl is required to process the directives in
it with C<pod2man> etc.

=head1 CHECKS

The following POD features are identified.

=over 4

=item *

Z<>=for, =begin and =end new in 5.004.

=item *

LE<lt>display text|targetE<gt> style display part, new in 5.005.

=item *

CE<lt>E<lt> foo E<gt>E<gt> double-angles, new in 5.6.0.

=item *

C<=head3> and C<=head4>, new in 5.8.0.

=item *

LE<lt>http://some.where.comE<gt>, new in 5.8.0.  (Prior versions take the "/"
as a "section" part, giving very poor output.)

=item *

EE<lt>aposE<gt>, EE<lt>solE<gt>, EE<lt>verbarE<gt> chars, new in 5.8.0.
(Documented in 5.6.0, but pod2man doesn't recognise them until 5.8.)

=item *

C<=encoding> command, new in 5.10.0.  (Documented in 5.8.0, but C<pod2man>
doesn't recognise it until 5.10.)

=back

POD syntax errors are quietly ignored currently.  The intention is only to
check what C<pod2man> would act on, but it's probably a good idea to use
C<Pod::Checker> first.

=head1 FUNCTIONS

=over 4

=item C<< $pmv = Pod::MinimumVersion->new (key => value, ...) >>

Create and return a new C<Pod::MinimumVersion> object which will analyze a
document.  The document is supplied as one of

    filehandle => $fh,
    string     => 'something',
    filename   => '/my/dir/foo.pod',

For C<filehandle> and C<string>, a C<filename> can be supplied too to give a
name in the reports.  The handle or string is what's actually read though.

The C<above_version> option lets you set a Perl version you use, so reports
are only about features above that level.

    above_version => '5.006',

=item C<< $version = $pmv->minimum_version () >>

=item C<< $report = $pmv->minimum_report () >>

Return the minimum Perl required for the document in C<$pmv>.

C<minimum_version> returns a C<version> object (see L<version>).
C<minimum_report> returns a C<Pod::MinimumVersion::Report> object (see
L</REPORT OBJECTS> below).

=item C<< @reports = $pmv->reports () >>

Return a list of C<Pod::MinimumVersion::Report> objects concerning the
document in C<$pmv>.

These multiple reports let you identify multiple places that a particular
Perl is required.  With the C<above_version> option the reports are still
only about things higher than that.

C<minimum_version> and C<minimum_report> simply give the highest Perl among
these multiple reports.

=back

=head1 REPORT OBJECTS

A C<Pod::MinimumVersion::Report> object holds a location within a document
and a reason that a particular Perl is needed at that point.  The hash
fields are

    filename   string
    linenum    integer, with 1 for the first line
    version    version.pm object
    why        string

=over 4

=item C<$str = $report-E<gt>as_string>

Return a formatted string for the report.  Currently this is in GNU
file:line style, simply

    <filename>:<linenum>: <version> due to <why>

=back

=head1 SEE ALSO

L<version>, L<Perl::MinimumVersion>,
L<Perl::Critic::Policy::Compatibility::PodMinimumVersion>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2009, 2010 Kevin Ryde

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

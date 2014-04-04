# Copyright 2013 Kevin Ryde

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


# perlcritic -s RequireFilenameMarkup RequireFilenameMarkup.pm

# unmarked /usr/local
# perlcritic -s RequireFilenameMarkup /usr/share/perl5/XML/Twig.pm

package Perl::Critic::Policy::Documentation::RequireFilenameMarkup;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Pod::Escapes;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 81;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### RequireFilenameMarkup on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::RequireFilenameMarkup->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::RequireFilenameMarkup;
use strict;
use warnings;
use Pod::ParseLink;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  $self->command_as_textblock(@_);
  return $self->SUPER::command(@_);  # for $self->{'in_begin'}
}

sub textblock {
  my ($self, $text, $linenum, $pod_para) = @_;
  ### textblock: "linenum=$linenum"

  if (($self->{'allow_next'}||0) > 0) {
    $self->{'allow_next'}--;
    return '';
  }
  if ($self->{'in_begin'}) {
    return '';
  }

  my $interpolated = $self->interpolate($text, $linenum);
  ### $text
  ### $interpolated

  while ($interpolated =~ m{(^|\W)
                            ((/usr
                              |/bin
                              |/tmp
                              |/etc(\W|$)
                              |/dev(\W|$)
                              |/opt(\W|$)
                              |[cC]:\\
                              )[^ \t\r\n]*)}gx) {
    my $before = $1;
    my $match = $2;
    my $pos = pos($interpolated) - length($match);

    # //foo is not a filename, eg. http://dev.foo.org
    # perlcritic -s RequireFilenameMarkup /usr/share/perl5/Moo.pm
    next if $before eq '/';

    $self->violation_at_linenum_and_textpos
      ("Filename without F<> or other markup \"$match\"\n",
       $linenum, $interpolated, $pos);
  }
}

sub interior_sequence {
  my ($self, $cmd, $text, $pod_seq) = @_;
  ### $cmd
  ### $text

  if ($cmd eq 'E') {
    my $char = Pod::Escapes::e2char($text);
    if (! defined $char) {
      ### oops, unrecognised E<> ...
      return 'X';
    }
    return $char;
  }
  if ($cmd eq 'L') {
    my ($display, $inferred, $name, $section, $type)
      = Pod::ParseLink::parselink ($text);
    ### $display
    ### $inferred
    ### $name
    return $inferred;  # the display part, or the name part if no display
  }

  ### X,C keep only the newlines: $text
  $text =~ tr/\n//cd;
  return $text;
}

1;
__END__

=for stopwords Ryde paren parens ie deref there'd backslashing Parens

=head1 NAME

Perl::Critic::Policy::Documentation::RequireFilenameMarkup - extra closing ">" after markup

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you to use C<FE<lt>E<gt>> markup on filenames.

=for ProhibitVerbatimMarkup allow next 2

    /usr/bin       # bad

    F</usr/bin>    # ok
    C</bin/sh>     # ok

C<FE<lt>E<gt>> makes nice italics in man pages which can help make it clear
that it's a filename, but otherwise this is a minor matter and on that basis
this policy is under the "cosmetic" theme (see L<Perl::Critic/POLICY
THEMES>) and lowest priority.

Filenames are identified by likely candidates starting

    /usr
    /bin
    /etc
    /dev
    /tmp
    /opt         # some proprietary Unix
    C:\          # MS-DOS

F</usr> and F</etc> are the most common.

Any markup satisfies this policy, not just C<FE<lt>E<gt>>.  So if
C<CE<lt>E<gt>> suits better because the filename is part of program code
then that's fine.  All "verbatim" paragraphs are ignored too, since markup
is not possible there.

=head2 Disabling

If you don't care about filename markup you can disable
C<RequireFilenameMarkup> from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::RequireFilenameMarkup]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2013 Kevin Ryde

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

# /usr/local
# /opt.
# /tmp
# /dev/null
# /dev/
# /dev.
# blah/option
# 
# /option
# 
# blah/blah/etc
# 
# E<sol>dev

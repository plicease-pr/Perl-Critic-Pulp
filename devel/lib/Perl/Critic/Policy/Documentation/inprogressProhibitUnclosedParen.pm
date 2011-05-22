# Copyright 2011 Kevin Ryde

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


# perlcritic -s inprogressProhibitUnclosedParen inprogressProhibitUnclosedParen.pm
# perlcritic -s inprogressProhibitUnclosedParen /usr/share/perl/5.10/CGI.pm

package Perl::Critic::Policy::Documentation::inprogressProhibitUnclosedParen;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 60;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOWEST;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### inprogressProhibitUnclosedParen on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::inprogressProhibitUnclosedParen->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::inprogressProhibitUnclosedParen;
use strict;
use warnings;
use Pod::ParseLink;
use base 'Perl::Critic::Pulp::PodParser';

my %command_non_text = (for   => 1,
                        begin => 1,
                        end   => 1,
                        cut   => 1);
sub command_as_textblock {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### command: $command
  unless ($command_non_text{$command}) {
    $self->textblock ($text, $linenum, $paraobj);
    # or padded to make the column number right ?
    # $self->textblock ((' ' x (length($command)+1)) . $text,
    #                   $linenum,
    #                   $paraobj);
  }
  return '';
}
*command = \&command_as_textblock;

sub textblock {
  my ($self, $text, $linenum, $pod_para) = @_;
  ### textblock: "linenum=$linenum"

  my $interpolated = $self->interpolate($text, $linenum);
  ### $text
  ### $interpolated

  my @openpos;
  my @openchar;
  while ($interpolated =~ m<
                             ([({[])          # $1 open
                           |([]})}])          # $2 close
                           |(["'])[][(){}]\3  # "(" etc
                           |[:;]-?[(]         # smiley faces don't open
                           |$[][()]           # perlvars
                           >xg) {
    if (defined $1) {
      push @openpos, pos($interpolated);
      push @openchar, $1;
    } elsif (defined $2) {
      pop @openpos;
      pop @openchar;
    }
  }
  ### @openpos
  if (@openpos) {
    $self->violation_at_linenum_and_textpos
      ("Unclosed parenthesis \"$openchar[-1]\"",
       $linenum, $interpolated, $openpos[-1]);
  }
  return '';
}
sub interior_sequence {
  my ($self, $cmd, $text, $pod_seq) = @_;
  if ($cmd eq 'X' || $cmd eq 'C') {
    # keep only the newlines
    $text =~ tr/\n//cd;

  } elsif ($cmd eq 'L') {
    my ($display, $inferred, $name, $section, $type)
      = Pod::ParseLink::parselink ($text);
    ### $display
    ### $inferred
    ### $name
    return $inferred;  # the display part, or the name part if no display
  }
  return $text;
}

1;
__END__

=for stopwords addon Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::inprogressProhibitUnclosedParen - don't leave an open bracket or parenthesis

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to leave an unclosed bracket or parenthesis,

    Blah blah (and B<something>.          # bad


About "(" ...

Blah C<som
code> blah (and B<something>
fdfdsjkf sdjk sdk

You have been warned:-)

=head2 Disabling

If you don't care about this you can disable
C<inprogressProhibitUnclosedParen> from your F<.perlcriticrc> in the usual way
(see L<Perl::Critic/CONFIGURATION>),

    [-Documentation::inprogressProhibitUnclosedParen]

=head1 SEE ALSO

L<Perl::Critic::Pulp> L<Perl::Critic>,

use Smart::Comments;

our $VERSION = 60;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOWEST;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### inprogressProhibitParagraphTwoDots on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::inprogressProhibitParagraphTwoDots->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::inprogressProhibitParagraphTwoDots;
use strict;
use warnings;
use Pod::ParseLink;
use base 'Perl::Critic::Pulp::PodParser';

my %command_non_text = (for   => 1,
                        begin => 1,
                        end   => 1,
                        cut   => 1);
sub command_as_textblock {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### command: $command
  unless ($command_non_text{$command}) {
    $self->textblock ($text, $linenum, $paraobj);
    # or padded to make the column number right ?
    # $self->textblock ((' ' x (length($command)+1)) . $text,
    #                   $linenum,
    #                   $paraobj);
  }
  return '';
}
*command = \&command_as_textblock;

sub textblock {
  my ($self, $text, $linenum, $pod_para) = @_;
  ### textblock: "linenum=$linenum"

  my $interpolated = $self->interpolate($text, $linenum);
  ### $text
  ### $interpolated

  if ($interpolated =~ /[^.](\.\.\s*)$/sg) {
    $text =~ /(\s*)$/;
    my $pos = length($text)-length($1); # end of $text
    ### $pos
    $self->violation_at_linenum_and_textpos
      ("Paragraph ends with two dots", $linenum, $text, $pos);
  }
  return '';
}
sub interior_sequence {
  my ($self, $cmd, $text, $pod_seq) = @_;
  if ($cmd eq 'X') {
    # keep only the newlines
    $text =~ tr/\n//cd;

  } elsif ($cmd eq 'L') {
    my ($display, $inferred, $name, $section, $type)
      = Pod::ParseLink::parselink ($text);
    ### $display
    ### $inferred
    ### $name
    return $inferred;  # the display part, or the name part if no display
  }
  return $text;
}

1;
__END__

=for stopwords addon Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::inprogressProhibitParagraphTwoDots - don't end a paragraph with two dots

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to end a POD paragraph with two dots,

    Some sentence..                # bad

This is a surprisingly easy typo to make, but of course is entirely cosmetic
and on that basis this policy is lowest priority and under the "cosmetic"
theme (see L<Perl::Critic/POLICY THEMES>).

A three or more dot ellipsis is fine,

    And some more of this...       # ok

There might be other dubious paragraph punctuation like this to pick up, but
things like ";." or ":." can arise from code or smiley faces.

=head2 Disabling

If you don't care about this you can disable
C<inprogressProhibitParagraphTwoDots> from your F<.perlcriticrc> in the usual way
(see L<Perl::Critic/CONFIGURATION>),

    [-Documentation::inprogressProhibitParagraphTwoDots]

=head1 SEE ALSO

L<Perl::Critic::Pulp> L<Perl::Critic>,

Note that in the above cases, C<thing($foo)> and C<thing($bar)>
I<are> evaluated -- but as long as the C<skip_if_true> is true,
then we C<skip(...)> just tosses out their value (i.e., not
bothering to treat them like values to C<ok(...)>.  But if
you need to I<not> eval the arguments when skipping the
test, use
this format:

=cut

# =head1 HOME PAGE
# 
# http://user42.tuxfamily.org/perl-critic-pulp/index.html
# 
# =head1 COPYRIGHT
# 
# Copyright 2011 Kevin Ryde
# 
# Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
# 
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
# 
# You should have received a copy of the GNU General Public License along with
# Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.
# 
# =cut

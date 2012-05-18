# Copyright 2010, 2011, 2012 Kevin Ryde

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


# perlcritic -s ProhibitFinalLinkComma ProhibitFinalLinkComma.pm
# perlcritic -s ProhibitFinalLinkComma /usr/share/perl5/MIME/Body.pm /usr/share/perl5/XML/Twig.pm

package Perl::Critic::Policy::Documentation::ProhibitFinalLinkComma;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 70;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOWEST;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitFinalLinkComma on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::ProhibitFinalLinkComma->new
    (-process_cut_cmd => 1,
     policy       => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::ProhibitFinalLinkComma;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub new {
  my $class = shift;
  return $class->SUPER::new (last => '',
                      @_);
}

sub parse_from_filehandle {
  my $self = shift;
  $self->SUPER::parse_from_filehandle(@_);
  $self->comma_violation_maybe;
}

sub comma_violation_maybe {
  my ($self) = @_;
  if ($self->{'last'} eq 'L-comma') {
    $self->violation_at_linenum_and_textpos
      ("Comma after L<> at end of section, should it be a full stop, or removed?",
       $self->{'saw_comma_linenum'},
       $self->{'saw_comma_text'},
       $self->{'saw_comma_textpos'});
  }
}

my %command_non_text = (for   => 1,
                        begin => 1,
                        end   => 1,
                        cut   => 1);

sub command {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### $command
  ### last: $self->{'last'}
  # ### $text

  if ($command_non_text{$command}) {
    # skip directives
    return '';
  }

  if (# before =over is ok
      $command eq 'over'

      # in between successive =item is ok
      || ($command eq 'item' && $self->{'last'} eq '=item')) {

  } else {
    # before =head or =cut is bad
    $self->comma_violation_maybe;
  }

  $self->{'last'} = '';
  return '';
}

sub verbatim {
  my ($self) = @_;
  ### verbatim
  $self->{'last'} = '';
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $pod_para) = @_;
  ### textblock
  ### $text
  $self->{'saw_comma_linenum'} = $linenum;
  $self->{'saw_comma_text'} = $text;
  $self->parse_text({-expand_seq => 'textblock_seq',
                     -expand_text => 'textblock_text' },
                    $text, $linenum);
  ### last now: $self->{'last'}
  return '';
}
sub textblock_seq {
  my ($self, $seq) = @_;
  ### seqsubr: $seq
  my $cmd = $seq->cmd_name;
  if ($cmd eq 'L') {
    if ($self->{'last'} eq 'L') {
      $self->violation_at_linenum_and_textpos
        ("Missing comma between L<> sequences",
         $self->{'saw_comma_linenum'},
         '', 0);
    }
    $self->{'last'} = 'L';

  } elsif ($cmd eq 'X') {
    # ignore X<>

  } else {
    # other like C<> as text
    ### raw_text: $seq->raw_text
    $self->textblock_text ($seq->raw_text, $seq);
  }
  return;
}
sub textblock_text {
  my ($self, $text, $textnode) = @_;
  ### textsubr: $text
  ### $textnode
  if ($text =~ /^(\s.*),\s*$/) {
    if ($self->{'last'} eq 'L') {
      $self->{'last'} = 'L-comma';
      $self->{'saw_comma_textpos'} = length($text) - length($1);
      return;
    }
  }
  if ($text !~ /^\s.*$/) {
    $self->{'last'} = '';
  }
  ### last now: $self->{'last'}
  return;
}

## no critic (ProhibitVerbatimMarkup)
1;
__END__

=for stopwords addon Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitFinalLinkComma - avoid comma at end of section

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to end a POD section with a comma.  The idea is to
catch a "SEE ALSO" list with a leftover comma at the end, or similar from
cut and paste.

    =head1 ONE THING

    L<Foo>, L<Bar>,     # bad

    =head1 AND ANOTHER

If you don't care about this you can disable C<ProhibitFinalLinkComma> from
your F<.perlcriticrc> in the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitFinalLinkComma]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>,

=cut

# =head1 HOME PAGE
# 
# http://user42.tuxfamily.org/perl-critic-pulp/index.html
# 
# =head1 COPYRIGHT
# 
# Copyright 2010, 2011, 2012 Kevin Ryde
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

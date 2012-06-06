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

package Perl::Critic::Policy::Documentation::RequireLinkedURLs;
use 5.006;
use strict;
use warnings;
use version ();
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

# perlcritic -s RequireLinkedURLs RequireLinkedURLs.pm
# perlcritic -s RequireLinkedURLs /usr/share/perl5/AnyEvent/HTTP.pm
# perlcritic -s RequireLinkedURLs /usr/share/perl5/SVG/Rasterize.pm

our $VERSION = 71;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

my $want_perl = version->new('5.008');

sub violates {
  my ($self, $elem, $document) = @_;
  ### RequireLinkedURLs violates()

  my $got_perl = $document->highest_explicit_perl_version;
  ### highest_explicit_perl_version: defined $got_perl && "$got_perl"
  if (! $got_perl                   # undef no use 5.x at all
      || $want_perl > $got_perl) {  # use 5.x too low
    ### no use 5.008 up, or too low
    return;
  }

  my $parser = Perl::Critic::Pulp::PodParser::RequireLinkedURLs->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::RequireLinkedURLs;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  $self->SUPER::command(@_);
  $self->command_as_textblock(@_);
  return '';
}

# ENHANCE-ME: Share this among the various parsing modules ...
my %command_non_text = (for   => 1,
                        begin => 1,
                        end   => 1,
                        cut   => 1);
sub command_as_textblock {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### command: $command
  unless ($command_non_text{$command}) {
    # padded to make the column number right, the leading spaces do no harm
    # for this policy
    $self->textblock ((' ' x (length($command)+1)) . $text,
                      $linenum,
                      $paraobj);

    # $self->textblock ($text, $linenum, $paraobj);
  }
  return '';
}

my %ignore_begin = (comment => 1,
                    html    => 1,
                    latex   => 1,
                    man     => 1,
                    roff    => 1,
                    tex     => 1,
                    wikidoc => 1,
                   );

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock ...

  return '' if $ignore_begin{lc($self->{'in_begin'})};

  my $expand = $self->interpolate ($text, $linenum);

  my $ptree = $self->parse_text ($text, $linenum);
  my @pending = reverse $ptree->children;   # depth first by pop()
  while (@pending) {
    my $obj = pop @pending;
    if (! ref $obj) {
      # plain text
      #                         12                          3
      while ($obj =~ m{(?<!L<)\b((https?|s?ftp|news|nntp)://(\S+))}g) {
        my $pos = pos($obj) - length($1);
        my $part = $3;
        next if _is_bogus_part($part);

        $self->violation_at_linenum_and_textpos
          ("URL can helpfully have L<> link markup",
           $linenum, $obj, $pos);
      }

    } else {
      # a Pod::InteriorSequence
      (undef, $linenum) = $obj->file_line;
      my $cmd = $obj->cmd_name;

      if ($cmd eq 'L') {
        next;

      } else {
        # descend into other like C<>
        # X<> is included, since markup is allowed in it, and maybe even L<>
        # to make hyperlinks in the index as such
        # Z<> is included, though it should normally be empty
        if (my $subtree = $obj->parse_tree) {
          push @pending, reverse $subtree->children;   # depth first by pop()
        }
      }
    }
  }
  return '';
}

sub _is_bogus_part {
  my ($part) = @_;
  ### _is_bogus_part(): $part
  return scalar ($part =~ m{^(
                              (foo|bar|quux|xyzzy)
                              \.(org|com|co\.[a-z]+)
                              (\.[a-z.]*)?
                            |
                              host(name)?[:/]
                            |
                              \.\.     # ellipsis like http://...
                            )}xi);
}

1;
__END__

=for stopwords addon Ryde formatters ProhibitVerbatimMarkup monospaced monospacing clickable

=head1 NAME

Perl::Critic::Policy::Documentation::RequireLinkedURLs - use LE<lt>E<gt> markup on URLs in POD

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you to put C<LE<lt>E<gt>> markup on URLs in POD text in Perl
5.8 and higher.

    use 5.008;

    =head1 HOME PAGE

    http://foo.org/mystuff/index.html      # bad

=for ProhibitVerbatimMarkup allow next

    L<http://foo.org/mystuff/index.html>   # good

C<LE<lt>E<gt>> markup gives clickable links in C<pod2html> and similar
formatters, and even in the plain text formatters may give
C<E<lt>http://...E<gt>> style angles around the URL which is a
semi-conventional way to delimit from surrounding text, and in particular
from an immediately following comma or period.

Of course this is only cosmetic and on that basis this policy is low
priority and under the "cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).

Only plain text parts of the POD are considered.  Verbatim paragraphs cannot
have C<LE<lt>E<gt>> markup (and a mistake to put it, as per
L<ProhibitVerbatimMarkup|Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup>).

    This is verbatim text,

        http://somewhere.com      # ok in verbatim

=head2 Perl 5.8

C<LE<lt>http://...E<gt>> linking of URLs is new in the Perl 5.8 POD
specification.  It comes out badly from the formatters in earlier Perl where
the "/" is taken to be a section delimiter.  For that reason this policy
only applies if there's an explicit C<use 5.008> or higher in the code.

    use 5.005;

=for ProhibitVerbatimMarkup allow next

    =item C<http://foo.org>       # ok when don't have Perl 5.8 L<>

=head2 Bad URLs

Some obviously bogus URLs like C<LE<lt>http://foo.orgE<gt>> are ignored.
They're only examples and won't go anywhere as a clickable link.  You might
like to put C<CE<lt>E<gt>> for a typeface, but C<LE<lt>E<gt>> is not
required and in fact probably undesirable.

Exactly what's ignored is not quite settled, but currently includes
variations like

    http://foo.com
    https://foo.org
    ftp://bar.org.au
    http://quux.com.au
    http://xyzzy.co.uk
    http://foo.co.nz
    http://host:port
    http://...

In the current implementation a URL is anything starting C<http://>,
C<https://>, C<ftp://>, C<news://> or C<nntp://>.

=head2 Begin Blocks

Text in an C<=begin html> block is not checked, since of course it should be
C<E<lt>a href=""E<gt>> etc, not C<LE<lt>E<gt>>.

    =begin html

    <a href="http://foo.org/index">home page</a>    # ok

    =end html

Other begins ignored for similar reasons are as follows.  They're probably
less likely to have URLs anyway.

    comment         programmer's notes only
    latex
    man
    roff 
    tex
    wikidoc         links are [http://...] style

Currently all other C<=begin> forms are examined, which is probably
excessive, but it's hard to be sure what will or won't be POD markup.  Keys
beginning ":" are supposed to be POD markup, others would be guesswork.

=head2 Disabling

If you don't care about this, if for instance it's hard enough to get your
programmers to write documentation at all without worrying about markup!,
then disable C<RequireLinkedURLs> from your F<~/.perlcriticrc> file in the
usual way (see L<Perl::Critic/CONFIGURATION>),

    [-Documentation::RequireLinkedURLs]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2011, 2012 Kevin Ryde

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

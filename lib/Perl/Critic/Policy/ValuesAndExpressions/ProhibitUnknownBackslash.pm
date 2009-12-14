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


package Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash;
use 5.006;
use strict;
use warnings;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities);
use Perl::Critic::Pulp;

our $VERSION = 26;

use constant DEBUG => 0;


sub supported_parameters {
  return ({ name           => 'single',
            description    => 'Checking of single-quote strings.',
            behavior       => 'string',
            default_string => 'none',
          },
          { name           => 'double',
            description    => 'Checking of double-quote strings.',
            behavior       => 'string',
            default_string => 'all',
          },
          { name           => 'heredoc',
            description    => 'Checking of interpolated here-documents.',
            behavior       => 'string',
            default_string => 'all',
          });
}

sub default_severity { return $SEVERITY_MEDIUM;   }
sub default_themes   { return qw(pulp cosmetic);  }
sub applies_to       { return ('PPI::Token::Quote::Single',
                               'PPI::Token::Quote::Literal',
                               'PPI::Token::Quote::Double',
                               'PPI::Token::Quote::Interpolate',
                               'PPI::Token::QuoteLike::Backtick',
                               'PPI::Token::QuoteLike::Command',
                               'PPI::Token::HereDoc'); }

my %charname = ("\n" => '{newline}',
                "\r" => '{cr}',
                "\t" => '{tab}',
                " "  => '{space}');

use constant _KNOWN => (
                        't'      # \t   tab
                        . 'n'    # \n   newline
                        . 'r'    # \r   carriage return
                        . 'f'    # \f   form feed
                        . 'b'    # \b   backspace
                        . 'a'    # \a   bell
                        . 'e'    # \e   esc
                        . '0123' # \377 octal
                        . 'x'    # \xFF \x{FF} hex
                        . 'c'    # \cX  control char

                        . 'l'    # \l   lowercase one char
                        . 'u'    # \u   uppercase one char
                        . 'L'    # \L   lowercase string
                        . 'U'    # \U   uppercase string
                        . 'E'    # \E   end case or quote
                        . 'Q'    # \Q   quotemeta
                        . '$'    # non-interpolation
                        . '@'    # non-interpolation
                       );

use constant _KNOWN_CONTROL
  => '?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_abcdefghijklmnopqrstuvwxyz';

my $quotelike_re = qr/^(?:(q[qrwx]?)  # $1 "q" if present
                    (?:(?:\s(?:\s*\#[^\n]*\n)*)\s*)?  # possible comments
                  )?    # possible "q"
                  (.)   # $2 opening quote
                  (.*)  # $3 guts
                  (.)$  # $4 closing quote
                 /xs;

sub violates {
  my ($self, $elem, $document) = @_;

  my $content = $elem->content;
  my $close = substr ($content, -1, 1);
  my $single = 0;
  my ($param, $str);

  if ($elem->isa('PPI::Token::HereDoc')) {
    return if ($close eq "'"); # uninterpolated
    $param = $self->{_heredoc};
    $str = join ('', $elem->heredoc);

  } else {
    if ($elem->can('string')) {
      $str = $elem->string;
    } else {
      $elem =~ $quotelike_re or die "Oops, didn't match quotelike_re";
      $str = $3;
    }
    $str =~ s{((^|\G|[^\\])(\\\\)*)\\\Q$close}{$close}sg;
    
    if ($elem->isa('PPI::Token::Quote::Single')
        || $elem->isa('PPI::Token::Quote::Literal')
        || ($elem->isa('PPI::Token::QuoteLike::Command')
            && $close eq "'")) {
      $single = 1;
      $param = $self->{_single};
      
    } else {
      $param = $self->{_double};
    }
  }
  return if ($param eq 'none');

  my $known = $close;

  if (! $single) {
    $known .= _KNOWN;

    # \N and octal chars above \377 are in 5.6 up
    # consider known if no "use 5.x" at all, or if present and 5.6 up
    # (so only under explicit "use 5.005" are they not allowed)
    my $perlver = $document->highest_explicit_perl_version;
    if (! defined $perlver || $perlver >= 5.006) {
      $known .= 'N4567';
    }
  }

  if (DEBUG) {
    require Data::Dumper;
    print "elem: ", ref $elem, "\n";
    print "  ", Data::Dumper->new([$str],['str'])->Useqq(1)->Dump;
    print "  ", Data::Dumper->new([$close],['close'])->Useqq(1)->Dump;
    print "  known: $known\n";
    my $perlver = $document->highest_explicit_perl_version;
    print "  perlver ", (defined $perlver ? $perlver : 'undef'), "\n";
  }

  my @violations;
  while ($str =~ /(\$.                     # $ not at end-of-string
                  |\@[[:alnum:]:'\{\$+-])  # @ forms per toke.c S_scan_const()
                 |(\\+)   # $2 run of backslashes
                 /sgx) {
    if (defined $1) {
      # $ or @
      unless ($single) {  # no variables in single-quote
        pos($str) = _pos_after_interpolate_variable ($str, pos($str)-1);
      }
      next;
    }

    if ((length($2) & 1) == 0) {
      # even number of backslashes, not an escape
      next;
    }

    # shouldn't have \ as the last char in $str, but if that happends then
    # $c is empty string ''

    my $c = substr($str,pos($str),1);
    pos($str)++;
    if ($c eq 'c') {
      # \cX skip char immediately after \c, in particular for \c\ the second
      # backslash isn't an escape.  Perl gives an error for that, should it
      # be reported here too?
      #
      # If \c is at end-of-string then pos() will go past length($str), but
      # that's ok, the loop regexp gives no-match.
      #
      pos($str)++;
      next;
    }

    if ($param eq 'quotemeta') {
      # only report on chars quotemeta leaves unchanged
      next if $c ne quotemeta($c);
    } elsif ($param eq 'alnum') {
      # only interested in alphanumerics like perl, does that mean only
      # ascii alphabeticals?
      next unless $c =~ /[a-zA-Z0-9]/;
    }

    # if $c eq '' for end-of-string then index() returns 0, for no violation
    if (index ($known, $c) >= 0) {
      # a known escape
      next;
    }

    # only ascii graphicals shown literally
    (my $printable = $c) =~ s{([^[:graph:]]|[^[:ascii:]])}
                             { $charname{$1} || sprintf('{0x%X}',ord($1)) }e;
    my $msg = "Unknown backslash \\$printable"
      . ($c eq 'N' && ", until perl 5.6.0");

    push @violations, $self->violation ($msg, '', $elem);

    # would have to take into account HereDoc begins on next line ...
    # _violation_elem_offset ($violation, $elem, pos($str)-2);
  }
  return @violations;
}

# $pos is a position within $str of a "$" or "@" interpolation
# return the position within $str after that variable or expression
#
sub _pos_after_interpolate_variable {
  my ($str, $pos) = @_;
  if (DEBUG) { print "_pos_after_interpolate_variable\n"; }
  $str = substr ($str, $pos);

  require PPI::Document;
  my $doc = PPI::Document->new(\$str);
  my $elem = $doc->child(0)->child(0);
  if (DEBUG) {
    print "  elem @{[ref $elem]} '$elem' len @{[length $elem->content]}\n";
  }
  $pos += length($elem->content);

  if ($elem->isa('PPI::Token::Cast')) {
    # get the PPI::Structure::Block following "$" or "@", can have
    # whitespace before it too
    while ($elem = $elem->next_sibling) {
      if (DEBUG) { print "  and '$elem' @{[length $elem->content]}\n"; }
      $pos += length($elem->content);
      last if $elem->isa('PPI::Structure::Block');
    }

  } elsif ($elem->isa('PPI::Token::Symbol')) {
    # any subscripts 'PPI::Structure::Subscript' following, like "$hash{...}"
    # whitespace stops the subscripts, so that Struct alone
    for (;;) {
      $elem = $elem->next_sibling || last;
      $elem->isa('PPI::Structure::Subscript') || last;
      if (DEBUG) { print "  and '$elem' @{[length $elem->content]}\n"; }
      $pos += length($elem->content);
    }
  }

  return $pos;
}

# $elem is a PPI::Token::Quote, PPI::Token::QuoteLike or PPI::Token::HereDoc
sub _string {
  my ($elem) = @_;
  if ($elem->can('heredoc')) {
    return join ('', $elem->heredoc);
  }
  if ($elem->can('string')) {
    return $elem->string;
  }
  $elem =~ $quotelike_re
    or die "Oops, didn't match quote_re";
  return $3;
}

# use Perl::Critic::Policy::Compatibility::PodMinimumVersion;
sub _violation_elem_offset {
  my ($violation, $elem, $offset) = @_;
  return $violation;

  #
  #   my $pre = substr ($elem->content, 0, $offset);
  #   my $newlines = ($pre =~ tr/\n//);
  #
  #   my $document = $elem->document;
  #   my $doc_str = $document->content;
  #
  #   return Perl::Critic::Policy::Compatibility::PodMinimumVersion::_violation_override_linenum ($violation, $doc_str, $newlines - 1);
}


#-----------------------------------------------------------------------------
# unused bits

# # $elem is a PPI::Token::Quote or PPI::Token::QuoteLike
# # return ($q, $open, $close) where $q is the "q" intro or empty string if
# # none, and $open and $close are the quote chars
# sub _quote_delims {
#   my ($elem) = @_;
#   if ($elem->can('heredoc')) {
#     return '"', '"';
#   }
#   $elem =~ $quotelike_re
#     or die "Oops, didn't match quote_re";
#   return ($1||'', $2, $4);
# }

# perlop "Quote and Quote-like Operators"
#   my $known = '';
#   if ($elem->isa ('PPI::Token::Quote::Double')
#       || $elem->isa ('PPI::Token::Quote::Interpolate')
#       || $elem->isa ('PPI::Token::QuoteLike::Backtick')
#       || ($elem->isa ('PPI::Token::QuoteLike::Command')
#           && $close ne '\'') # no interpolation in qx'echo hi'
#      ) {
#     $known = 'tnrfbae0123xcluLUQE$@';
#
#     # \N and octals bigger than 8-bits are in 5.6 up, and allow them if no
#     # "use 5.x" at all too
#     my $perlver = $document->highest_explicit_perl_version;
#     if (! defined $perlver || $perlver >= 5.006) {
#       $known .= 'N456789';
#     }
#   }
#   $known .= $close;
#
# my $re = qr/\\+[^\\$known$close]/;
#   my $unknown = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
#   $unknown =~ s{(.)}
#                {index($known,$1) >= 0 ? '' : $1}eg;

1;
__END__

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash - don't use undefined backslash forms

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It checks for unknown backslash escapes like

    print "\*.c";     # bad

This is usually harmless, in as much as the intention is a literal "*" and
that's what it gives, but it's unnecessary, and on that basis this policy is
under the C<cosmetic> theme (see L<Perl::Critic/POLICY THEMES>).  It's also
possible however an unnecessary backslash is a misunderstanding
interpolation, or a typo.

Perl already warns about unknown escaped alphanumerics like C<\v>, under
C<perl -w> or C<use warnings> (see L<perldiag/Unrecognized escape \\%c
passed through>).

    print "\v";       # provokes Perl warning

This policy extends to report on any unknown escape, with options below to
vary the strictness, and check single-quote strings too if desired.

=head2 Wide Chars

C<\N{}> named unicode and C<\777> octal escapes above 255 are new in Perl
5.6.  They're considered known if the document has a C<use 5.006> or higher,
or the default with no such version at all is to allow them too.

    print "\777";            # ok

    use 5.006;
    print "\N{APOSTROPHE}";  # ok

    use 5.005;
    print "\N{COLON}";       # bad

The absense of a C<use> is treated as 5.6 because that's most likely if you
have those escapes intentionally.  But perhaps this will change, or be
configurable.

In the violation messages a non-ascii or non-graphical escaped char is shown
as hex like C<\{0x263A}>, to ensure the message is printable and
unambiguous.

=head2 Other Notes

Interpolated C<$foo> or C<@{expr}> variables and expressions are parsed like
Perl does, so backslashes for refs there are ok, in particular tricks like
C<${\scalar ...}> are fine (see L<perlfaq4/How do I expand function calls in
a string?>).

    print "this ${\(some()+thing())}

As always, if you're not interested in any of this then you can disable
C<ProhibitUnknownBackslash> from your F<.perlcriticrc> in the usual way,

    [-ValuesAndExpressions::ProhibitUnknownBackslash]

=head1 CONFIGURATION

=over 4

=item C<double> (string, default "all")

=item C<heredoc> (string, default "all")

C<double> applies to double-quote strings C<"">, C<qq{}>, C<qx{}>, etc.
C<heredoc> applies to interpolated here-documents C<E<lt>E<lt>HERE> etc.
The possible values are

    none       don't report anything
    alnum      report unknown alphanumerics, like Perl's warning
    quotemeta  report anything C<quotemeta> doesn't escape
    all        report all unknowns

"alnum" does no more than compiling with C<perl -w>, but might be good for
checking code you don't want to run at all.

"quotemeta" means report escapes not produced by C<quotemeta()>.  For
example C<quotemeta> escapes a C<*>, so C<\*> is not reported, but it
doesn't escape an underscore C<_>, so C<\_> is reported.  The effect is to
prohibit a few more escapes than "alnum".  One use is to check code
generated by other code if you use C<quotemeta> to produce double-quoted
strings and thus may have escaping which is unnecessary but works fine.

=item C<single> (string, default "none")

C<single> applies to single-quote strings C<''>, C<q{}>, C<qx''>, etc.  The
possible values are as for C<double> above, though only "all" or "none" make
much sense.

"single" defaults to "none" because literal backslashes in single-quotes are
usually both what you want and quite convenient.  Setting "all" effectively
means you must write backslashes as C<\\>.

    print 'c:\my\msdos\filename';     # bad under "single=all"
    print 'c:\\my\\msdos\\filename';  # ok

Doubled backslashing like this is correct, and can emphasise that you really
did want a backslash, but it's a bit tedious and not easy on the eye and so
is left only as an option.

For reference, single-quote here-documents C<E<lt>E<lt>'HERE'> don't have
any backslash escapes and so are left alone by this policy.  C<qx{}>
backticks are normally double-quote, but C<qx''> is single-quote.

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>, L<perlop/Quote and Quote-like
Operators>

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
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses>.

=cut

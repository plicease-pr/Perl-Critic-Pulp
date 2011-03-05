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


package Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders;
use 5.006;
use strict;
use warnings;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_function_call
                           parse_arg_list
                           interpolate);

our $VERSION = 48;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => 'PPI::Token::Word';

my %funcs = (__x   => 1,
             __nx  => 1,
             __xn  => 1,

             __px  => 1,
             __npx => 1);

sub violates {
  my ($self, $elem, $document) = @_;

  my $funcname = $elem->content;
  $funcname =~ s/^Locale::TextDomain:://;
  $funcs{$funcname} || return;
  ### TextDomainPlaceholders: $elem->content

  is_function_call($elem) || return;

  my @violations;

  # The arg crunching bits assume one parsed expression results in one arg,
  # which is not true if the expressions are an array, a hash, or a function
  # call returning multiple values.  The one-arg-one-value assumption is
  # reasonable on the whole though.
  #
  # In the worst case you'd have to take any function call value part like
  # "foo => FOO()" to perhaps return multiple values -- which would
  # completely defeat testing of normal cases, so don't want to do that.
  #
  # ENHANCE-ME: One bit that could be done though is to recognise a %foo arg
  # as giving an even number of values, so keyword checking could continue
  # past it.

  # each element of @args is an arrayref containing PPI elements making up
  # the arg
  my @args = parse_arg_list ($elem);
  ### got total arg count: scalar(@args)

  if ($funcname =~ /p/) {
    # msgctxt context arg to __p, __npx
    shift @args;
  }

  # one format to __x, two to __nx and other "n" funcs
  my @format_args = splice @args, 0, ($funcname =~ /n/ ? 2 : 1);

  if ($funcname =~ /n/) {
    # count arg to __nx and other "n" funcs
    my $count_arg = shift @args;
    if (! $count_arg
        || do {
          # if it looks like a keyword symbol foo=> or 'foo' etc
          my ($str, $any_vars) = _arg_word_or_string ($count_arg);
          ($str =~ /^[[:alpha:]_]\w*$/ && ! $any_vars)
        }) {
      push @violations, $self->violation
        ("Probably missing 'count' argument to $funcname",
         '',
         $count_arg->[0] || $elem);
    }
  }

  ### got data arg count: scalar(@args)

  my $args_any_vars = 0;
  my %arg_keys;
  while (@args) {
    my $arg = shift @args;
    my ($str, $any_vars) = _arg_word_or_string ($arg);
    $args_any_vars ||= $any_vars;
    ### arg: @$arg
    ### $str
    ### $any_vars
    if (! $any_vars) {
      $arg_keys{$str} = $arg;
    }
    shift @args; # value part
  }

  my %format_keys;
  my $format_any_vars;

  foreach my $format_arg (@format_args) {
    my ($format_str, $any_vars) = _arg_string ($format_arg);
    $format_any_vars ||= $any_vars;

    while ($format_str =~ /\{(\w+)\}/g) {
      my $format_key = $1;
      ### $format_key
      $format_keys{$format_key} = 1;

      if (! $args_any_vars && ! exists $arg_keys{$format_key}) {
        push @violations, $self->violation
          ("Format key '$format_key' not in arg list",
           '',
           $format_arg->[0] || $elem);
      }
    }
  }

  if (! $format_any_vars) {
    foreach my $arg_key (keys %arg_keys) {
      if (! exists $format_keys{$arg_key}) {
        my $arg = $arg_keys{$arg_key};
        push @violations, $self->violation
          ("Argument key '$arg_key' not used by format"
           . (@format_args == 1 ? '' : 's'),
           '',
           $arg->[0] || $elem);
      }
    }
  }
  ### total violation count: scalar(@violations)

  return @violations;
}

sub _arg_word_or_string {
  my ($arg) = @_;
  if (@$arg == 1 && $arg->[0]->isa('PPI::Token::Word')) {
    return ("$arg->[0]", 0);
  } else {
    return _arg_string ($arg);
  }
}

sub _arg_string {
  my ($arg) = @_;
  my @elems = @$arg;
  my $ret = '';
  my $any_vars = 0;

  while (@elems) {
    my $elem = shift @elems;

    if ($elem->isa('PPI::Token::Quote')) {
      my $str = $elem->string;
      if ($elem->isa('PPI::Token::Quote::Double')
          || $elem->isa('PPI::Token::Quote::Interpolate')) {
        $any_vars ||= string_any_vars ($str);
      }
      $ret .= $str;

    } elsif ($elem->isa('PPI::Token::HereDoc')) {
      my $str = join('',$elem->heredoc);
      if ($elem =~ /`$/) {
        $str = ' '; # no idea what running backticks might produce
        $any_vars = 1;
      } elsif ($elem !~ /'$/) {
        # explicit "HERE" or default HERE expand vars
        $any_vars ||= string_any_vars ($str);
      }
      $ret .= $str;

    } elsif ($elem->isa('PPI::Token::Number')) {
      # a number can work like a constant string
      $ret .= $elem->content;

    } elsif ($elem->isa('PPI::Token::Word')) {
      if (my $next = $elem->snext_sibling) {
        if ($next->isa('PPI::Token::Operator') && $next eq '=>') {
          $ret .= $elem->content;
        }
      }
      last;

    } else {
      # some variable or something
      return ('', 1);
    }


    if (! @elems) { last; }
    my $op = shift @elems;
    if (! ($op->isa('PPI::Token::Operator') && $op eq '.')) {
      # something other than "." concat
      return ('', 1);
    }
  }
  return ($ret, $any_vars);
}

# $str is the contents of a "" or qq{} string
# return true if it has any $ or @ interpolation forms
sub string_any_vars {
  my ($str) = @_;
  return ($str =~ /(^|[^\\])(\\\\)*[\$@]/);
}

1;
__END__

=for stopwords addon args arg Gettext Charset runtime Ryde

=head1 NAME

Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders - check placeholder names in Locale::TextDomain calls

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It checks the placeholder arguments in format strings to the
following functions from C<Locale::TextDomain>.

    __x __nx __xn __px __npx

Calls with a key missing from the args or args unused by the format are
reported.

    print __x('Searching for {data}',  # bad
              datum => 123);

    print __nx('Read one file',
               'Read {num} files',     # bad
               $n,
               count => 123);

This is normally a mistake, so this policy is under the C<bugs> theme (see
L<Perl::Critic/POLICY THEMES>).  An error can easily go unnoticed because
(as of Locale::TextDomain version 1.16) a placeholder without a
corresponding arg goes through unexpanded and any extra args are ignored.

The way Locale::TextDomain parses the format string allows anything between
S<< C<< { } >> >> as a key, but for the purposes of this policy only symbols
(alphanumeric plus "_") are taken to be a key.  This is almost certainly
what you'll want to use, and it's then possible to include literal braces in
a format string without tickling this policy all the time.  (Symbol
characters are per Perl C<\w>, so non-ASCII is supported, though the Gettext
manual in node "Charset conversion" recommends message-IDs should be
ASCII-only.)

=head1 Partial Checks

If the format string is not a literal then it might use any args, so all are
considered used.

    # ok, 'datum' might be used
    __x($my_format, datum => 123);

Literal portions of the format are still checked.

    # bad, 'foo' not present in args
    __x("{foo} $bar", datum => 123);

Conversely if the args have some non-literals then they could be anything,
so everything in the format string is considered present.

    # ok, $something might be 'world'
    __x('hello {world}', $something => 123);

But again if some args are literals they can be checked.

    # bad, 'blah' is not used
    __x('hello {world}', $something => 123, blah => 456);

If there's non-literals both in the format and in the args then nothing is
checked, since it could all match up fine at runtime.

=head2 C<__nx> Count Argument

A missing count argument to C<__nx>, C<__xn> and C<__npx> is sometimes
noticed by this policy.  For example,

    print __nx('Read one file',
               'Read {numfiles} files',
               numfiles => $numfiles);   # bad

If the count argument looks like a key then it's reported as a probable
mistake.  This is not the main aim of this policy but it's done because
otherwise no violations would be reported at all.  (The next argument would
be the key, and normally being an expression it would be assumed to fulfil
the format strings at runtime.)

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>, L<Locale::TextDomain>,
L<Perl::Critic::Policy::Miscellanea::TextDomainUnused>

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

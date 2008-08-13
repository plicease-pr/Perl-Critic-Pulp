# Copyright 2008 Kevin Ryde

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
use strict;
use warnings;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities
                           parse_arg_list
                           interpolate);

our $VERSION = 6;

use constant DEBUG => 0;

sub supported_parameters { return; }
sub default_severity { return $SEVERITY_MEDIUM;       }
sub default_themes   { return qw(pulp bugs);      }
sub applies_to       { return 'PPI::Token::Word'; }

my %funcs = (__x  => [ 1, 0 ],
             __nx => [ 2, 1 ],
             __xn => [ 2, 1 ]);

sub violates {
  my ($self, $elem, $document) = @_;

  my $settings = $funcs{"$elem"} || return;
  my ($format_count, $skip_count) = @$settings;
  if (DEBUG) { print "TextDomainPlaceholders $elem\n"; }

  my @args = parse_arg_list ($elem);
  if (DEBUG) { print "  got total ",scalar(@args)," args\n"; }

  my @formats = splice @args, 0, $format_count;
  splice @args, 0, $skip_count;
  if (DEBUG) { print "  got ",scalar(@args)," data args\n"; }

  my $format_any_vars;
  foreach my $format (@formats) {
    my $any_vars;
    ($format, $any_vars) = _arg_string ($format);
    $format_any_vars ||= $any_vars;
  }

  my $arg_any_vars = 0;
  my %arg_keys;
  while (@args) {
    my $arg = shift @args;
    my ($str, $any_vars) = _arg_word_or_string ($arg);
    $arg_any_vars ||= $any_vars;
    if (DEBUG) { print "  arg '$str'\n"; }
    if (! $any_vars) {
      $arg_keys{$str} = 1;
    }
    shift @args; # value part
  }

  my %format_keys;
  foreach my $format (@formats) {
    while ($format =~ /\{([a-zA-Z0-9_]+)\}/g) {
      if (DEBUG) { print "  format key: '$1'\n"; }
      $format_keys{$1} = 1;
    }
  }

  my @violations;
  if (! $arg_any_vars) {
    foreach my $format_key (keys %format_keys) {
      if (! exists $arg_keys{$format_key}) {
        push @violations, $self->violation
          ("Format key '$format_key' not in arg list",
           '',
           $elem);
      }
    }
  }
  if (! $format_any_vars) {
    foreach my $arg_key (keys %arg_keys) {
      if (! exists $format_keys{$arg_key}) {
        push @violations, $self->violation
          ("Argument key '$arg_key' not used by format"
           . ($format_count ? 's' : ''),
           '',
           $elem);
      }
    }
  }
  if (DEBUG) { print "  total violations ",scalar(@violations),"\n"; }

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

# return true if $str has any $ or @ forms for expanding as a variable
sub string_any_vars {
  my ($str) = @_;
  return ($str =~ /(\\\\)*[\$\@]/);
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders - check placeholder names in Locale::TextDomain calls

=head1 DESCRIPTION

This policy is part of the Perl::Critic::Pulp addon.  It checks the
placeholder arguments in format strings to the C<__x>, C<__nx> and C<__xn>
functions from C<Locale::TextDomain>.  Any formats with a key missing from
the args, or args which are unused by the format, are reported.

    print __x('Searching for {data}',  # bad
              datum => 123);

    print __nx('Read one file',    # bad
               'Read {num} files',
               $n,
               count => 123);

This sort of thing is usually a mistake, so this policy is under the C<bugs>
theme.  An error can fairly easily go unnoticed since (as of TextDomain
version 1.16) a placeholder without a corresponding arg merely goes through
unexpanded and any extra args are ignored.

The way TextDomain is setup actually allows anything between
S<< "C<< { } >>" >> as a key string, but for the purposes of this policy
only symbol characters "a-zA-Z0-9_" are taken to be a key.  This is almost
certainly what you'll want to use anyway, and it makes it possible to
include literal braces in the string without tickling this policy all the
time.

=head1 LIMITATIONS

If the format string is not a literal then it might use any args, so all are
considered used.

    # ok, 'datum' might be used
    __x($my_format, datum => 123);

Literal portions of the format are still checked.

    # bad, 'foo' not present in args
    __x("{foo} $bar, datum => 123);

Conversely, if the args have some non-literals then they could be anything,
so everything in the format string is considered present.

    # ok, $something might be 'world'
    __x('hello {world}', $something => 123);

Literal args are still checked.

    # bad, 'blah' is not used
    __x('hello {world}', $something => 123, blah => 456);

If there's both a non-literal in the format and in the args then nothing is
checked, since it could match up fine at runtime.

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>, L<Locale::TextDomain>

=head1 HOME PAGE

L<http://www.geocities.com/user42_kevin/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008 Kevin Ryde

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

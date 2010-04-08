# Copyright 2008, 2009, 2010 Kevin Ryde

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


package Perl::Critic::Pulp::Utils;
use 5.006;
use strict;
use warnings;
use version;

our $VERSION = 33;


our %COMMA = (','  => 1,
              '=>' => 1);


# A parameter parser function for a "supported_parameters" entry which takes
# a version number as a string.
#
sub parameter_parse_version {
  my ($self, $parameter, $str) = @_;

  my $version;
  if (defined $str && $str ne '') {
    $version = version_if_valid ($str);
    if (! defined $version) {
      $self->throw_parameter_value_exception
        ($parameter->get_name,
         $str,
         undef, # source
         'invalid version number string');
    }
  }
  $self->{$parameter->get_name} = $version;
}

# return a version.pm object, or undef if $str is invalid
sub version_if_valid {
  my ($str) = @_;
  # this is a nasty hack to notice "not a number" warnings, and for version
  # 0.81 possibly throwing errors too
  my $good = 1;
  my $version;
  { local $SIG{'__WARN__'} = sub { $good = 0 };
    eval { $version = version->new($str) };
  }
  return ($good ? $version : undef);
}

# This regexp is what Perl's toke.c S_force_version() demands, as of
# versions 5.004 through 5.8.9.  A version number in a "use" must start with
# a digit and then have only digits, dots and underscores.  In particular
# other normal numeric forms like hex or exponential are not taken to be
# version numbers, and even omitting the 0 from a decimal like ".25" is not
# a version number.
#
our $use_module_version_number_re = qr/^v?[0-9][0-9._]*$/;

# $inc is a PPI::Statement::Include.
# If it has a version number for a module "use" or "no" then return that
# element.  As of PPI 1.203 there's no v-number parsing, so the version
# element is always a PPI::Token::Number.
#
# A "require" is treated the same as "use" and "no", though a module version
# number like "require Foo::Bar 1.5" is actually a syntax error.
#
# A module version is a literal number following the module name, with
# either nothing else after it, or with no comma before the arglist.
#
sub include_module_version {
  my ($inc) = @_;

  # only a module style "use Foo", not a perl version num like "use 5.010"
  defined ($inc->module) || return undef;

  my $ver = $inc->schild(2) || return undef;
  # ENHANCE-ME: when PPI recognises v-strings may have to extend this
  $ver->isa('PPI::Token::Number') || return undef;

  $ver->content =~ $use_module_version_number_re or return undef;

  # must be followed by whitespace, or comment, or end of statement, so
  #
  #    use Foo 10 -3;    <- version 10, arg -3
  #    use Foo 10-3;     <- arg 7
  #
  #    use Foo 10#       <- version 10, arg -3
  #    -3;
  #
  if (my $after = $ver->next_sibling) {
    unless ($after->isa('PPI::Token::Whitespace')
            || $after->isa('PPI::Token::Comment')
            || ($after->isa('PPI::Token::Structure')
                && $after eq ';')) {
      return undef;
    }
  }

  return $ver;
}

# $inc is a PPI::Statement::Include.
# Return the element which is the start of the first argument to its
# import() or unimport(), for "use" or "no" respectively.
#
# A "require" is treated the same as "use" and "no", but arguments to it
# like "require Foo::Bar '-init';" is in fact a syntax error.
#
sub include_module_first_arg {
  my ($inc) = @_;
  defined ($inc->module) || return;
  my $arg;
  if (my $ver = include_module_version ($inc)) {
    $arg = $ver->snext_sibling;
  } else {
    # eg. "use Foo 'xxx'"
    $arg = $inc->schild(2);
  }
  # don't return terminating ";"
  if ($arg
      && $arg->isa('PPI::Token::Structure')
      && $arg->content eq ';'
      && ! $arg->snext_sibling) {
    return;
  }
  return $arg;
}

1;
__END__

=for stopwords perlcritic Ryde

=head1 NAME

Perl::Critic::Pulp::Utils - shared helper code for the Pulp perlcritic add-on

=head1 SYNOPSIS

 use Perl::Critic::Pulp::Utils;

=head1 DESCRIPTION

This is only meant for internal use just yet.

=head1 SEE ALSO

L<Perl::Critic::Pulp>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2008, 2009, 2010 Kevin Ryde

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

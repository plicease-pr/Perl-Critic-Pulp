# Copyright 2010, 2011 Kevin Ryde

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

package Perl::Critic::Policy::Modules::ProhibitModuleShebang;
use 5.006;
use strict;
use warnings;
use List::Util;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils 0.21;  # version 0.21 for shebang_line()
use Perl::Critic::Pulp;
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 61;

use constant supported_parameters =>
  ({ name           => 'allow_bin_false',
     description    => 'Whether to allow #!/bin/false',
     behavior       => 'boolean',
     default_string => '1',
   });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes   => ('pulp', 'cosmetic');
use constant applies_to       => 'PPI::Document';

# only ever gives one violation
use constant default_maximum_violations_per_document => 1;

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitModuleShebang elem: $elem->content

  my $filename = $document->filename;
  (defined $filename && $filename =~ /\.pm$/)
    or return;  # only .pm files are modules

  my $shebang = Perl::Critic::Utils::shebang_line($document)
    || return;  # no #! at all

  if ($self->{'_allow_bin_false'}) {
    if ($shebang =~ m{^#!\s*/bin/false\s*$}) {
      return; # /bin/false allowed
    }
  }
  return $self->violation ('Don\'t use #! in a module file',
                           '',
                           $document);
}

1;
__END__

=for stopwords addon filename boolean ProhibitModuleShebang Ryde

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitModuleShebang - don't put a #! line at the start of a module file

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It asks you not to use a C<#!> interpreter line in a F<.pm> module
file.

    #!/usr/bin/perl -w      <-- bad
    package Foo;
    ...

This C<#!> does nothing, and might make a reader think it's supposed to be a
program instead of a module.  Often the C<#!> is a leftover cut and paste
from a script into a module, perhaps when grabbing a copyright notice or
similar intro.

Of course a module works the same with or without, so this policy is low
priority and under the "cosmetic" theme (see L<Perl::Critic/POLICY THEMES>).

Only the first line of a file is a prospective C<#!> interpreter.  A C<#!>
anywhere later is allowed, for example in code which generates other code,

    sub foo {
      print <<HERE;
    #!/usr/bin/make         <-- ok
    # Makefile generated by Foo.pm - DO NOT EDIT
    ...

This policy applies only to F<.pm> files.  Anything else, such as C<.pl> or
C<.t> scripts can have C<#!>, or not, in the usual way.  Modules are
identified by the F<.pm> filename because it's hard to distinguish a module
from a script just by the content.

=head2 Disabling

If you don't care about this you can always disable C<ProhibitModuleShebang>
from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Modules::ProhibitModuleShebang]

=head1 CONFIGURATION

=over 4

=item C<allow_bin_false> (boolean, default true)

If true then allow C<#!/bin/false> in module files.

    #! /bin/false           <-- ok

This will prevent execution of the code if accidentally run as a script, but
whether you want this is a personal preference.  Insofar as it indicates a
module is not a script it accords with ProhibitModuleShebang, but in general
it's probably unnecessary.

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2010, 2011 Kevin Ryde

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

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


package Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Perl::Critic::Pulp::Utils;
use Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon;
use Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders;
use Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 68;


use constant supported_parameters => ();
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp bugs);
use constant applies_to       => ('PPI::Structure::Constructor',
                                  'PPI::Structure::List',
                                  'PPI::Structure::Block');

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitDuplicateHashKeys violates() ...

  ### consider: "$elem"

  if ($elem->isa('PPI::Structure::Constructor')) {
    _constructor_is_hash($elem) or return;

    # is this needed ?
    # return if _constructor_is_block($elem);

  } elsif ($elem->isa('PPI::Structure::Block')) {
    return unless Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon::_block_is_hash_constructor($elem);

  } else { # PPI::Structure::List
    _elem_is_assigned_to_hash($elem) || return;
  }

  $elem = $elem->schild(0) || return;
  if ($elem->isa('PPI::Statement::Expression')) {
    $elem = $elem->schild(0) || return;
  }

  my @arefs = Perl::Critic::Utils::split_nodes_on_comma
    (Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt::_elem_and_ssiblings($elem));

  @arefs = grep {defined} @arefs;  # skip undef for consecutive commas

  my @violations;
  my %seen_key;
  while (@arefs) {
    ### arefs count: scalar(@arefs)
    my $key_aref = shift @arefs || last;
    $elem = $key_aref->[0];
    ### key: (ref $elem)."  $elem"

    # %$foo is an even number of things
    if ($elem->isa('PPI::Token::Cast') && $elem eq '%') {
      ### skip % even elements ...
      next;
    }

    shift @arefs; # value aref

    my $str;
    if (@$key_aref == 1 && $elem->isa('PPI::Token::Word')) {
      ### word ...
      $str = $elem->content;
    } else {
      ### other ...
      ($str, my $any_vars) = Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders::_arg_string($key_aref);
      ### $any_vars
      next if $any_vars;
    }

    ### $str
    if (defined $str && $seen_key{$str}++) {
      push @violations, $self->violation ("Duplicate hash key $str",
                                          '',
                                          $elem);
    }
  }

  ### done ...
  return @violations;
}

sub _constructor_is_hash {
  my ($elem) = @_;
  return (substr($elem,0,1) eq '[');
}

# my %word_is_block = (sub => 1,
#                      do => 1);
# sub _constructor_is_block {
#   my ($elem) = @_;
#   my $prev;
#   return (($prev = $elem->sprevious_sibling)
#           && $prev->isa('PPI::Token::Word')
#           && $word_is_block{$prev});
# }

sub _elem_is_assigned_to_hash {
  my ($elem) = @_;
  ### _elem_is_assigned_to_hash() ...

  $elem = $elem->sprevious_sibling || return 0;

  ($elem->isa('PPI::Token::Operator') && $elem eq '=')
    or return 0;

  $elem = $elem->sprevious_sibling || return 0;
  ### assign to: "$elem"

  # %{expr} = () deref
  if ($elem->isa('PPI::Structure::Block')) {
    $elem = $elem->sprevious_sibling || return 0;
    ### cast hash ...
    return ($elem->isa('PPI::Token::Cast') && $elem eq '%');
  }

  if ($elem->isa('PPI::Token::Symbol')) {
    if ($elem->symbol_type eq '%') {
      ### yes, %foo ...
      return 1;
    }
    if ($elem->symbol_type eq '$') {
      ### symbol scalar ...
      # %$x=() or %$$$x=() deref
      for (;;) {
        $elem = $elem->sprevious_sibling || return 0;
        ### prev: (ref $elem)."  $elem"
        if ($elem->isa('PPI::Token::Magic')) {
          # PPI 1.215 mistakes %$$$r as magic variable $$
        } elsif ($elem->isa('PPI::Token::Cast')) {
          if ($elem ne '$') {
            ### cast hash: ($elem eq '%')
            return ($elem eq '%');
          }
        } else {
          return 0;
        }
      }
    }
  }

  ### no ...
  return 0;
}

1;
__END__

=for stopwords addon Ryde

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys - disallow duplicate literal hash keys

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
addon.  It reports duplicate hash keys in a hash assignment or anonymous
hash constructor.  For example,

    my %hash  = (red   => 1,
                 green => 2,
                 red   => 3,   # bad
                );

Perl is happy to run this, and the last "red" has priority, but writing two
identical literal keys like this is probably a mistake, or at least is
unclear to the reader what is intended.  On that basis this policy is only
under the "bugs" theme (see L<Perl::Critic/POLICY THEMES>).

If you don't care about this you can always disable
C<ProhibitDuplicateHashKeys> from your F<.perlcriticrc> file in the usual
way (see L<Perl::Critic/CONFIGURATION>),

    [-ValuesAndExpressions::ProhibitDuplicateHashKeys]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2011 Kevin Ryde

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

#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Perl-Critic-Pulp',
   ABSTRACT     => 'Some add-on policies for Perl::Critic.',
   VERSION      => 1,
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   PREREQ_PM    => {
                    # think 1.082 for the new style parameter specs
                    'Perl::Critic' => '1.082',
                   },
  );

sub MY::postamble {
  return <<'MAKE_FRAG';

lint:
	perl -MO=Lint $(TO_INST_PM)
	podchecker    $(TO_INST_PM)
pc:
	perlcritic $(TO_INST_PM)

myman:
	mv MANIFEST MANIFEST.old
	touch SIGNATURE
	(make manifest 2>&1; diff -u MANIFEST.old MANIFEST) |less

# find files in the dist with mod times this year, but without this year in
# the copyright line
copyright-years-check: Perl-Critic-Pulp-$(VERSION).tar.gz
	year=`date +%Y`; \
	tar tvfz Perl-Critic-Pulp-$(VERSION).tar.gz \
	| grep $$year- \
	| sed 's:^.*Perl-Critic-Pulp-$(VERSION)/::' \
	| (result=0; \
	  while read i; do \
	    case $$i in \
	      '' | */ \
	      | debian/changelog | debian/compat | debian/control \
	      | t/pod.t \
	      | COPYING | MANIFEST | SIGNATURE | META.yml) \
	      continue ;; \
	    esac; \
	    if test -e "$(srcdir)/$$i"; then f="$(srcdir)/$$i"; \
	    else f="$$i"; fi; \
	    if ! grep -q "Copyright.*$$year" $$f; then \
	      echo "$$i:1: this file"; \
	      grep Copyright $$f; \
	      result=1; \
	    fi; \
	  done; \
	  exit $$result)

debug-constants-check:
	if egrep -n 'DEBUG => [^0]' $(TO_INST_PM); then exit 1; else exit 0; fi

MAKE_FRAG
}

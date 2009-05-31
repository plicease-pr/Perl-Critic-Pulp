#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

# This file is part of Perl-Critic-Pulp.

# Perl-Critic-Pulp is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'Perl-Critic-Pulp',
   ABSTRACT     => 'Some add-on policies for Perl::Critic.',
   VERSION_FROM => 'lib/Perl/Critic/Pulp.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   PREREQ_PM    => {
                    # 1.082 or some such for new style parameter specs
                    'Perl::Critic' => '1.082',

                    # builtin in recent perl anyway
                    'List::Util' => 0,
                    'Test::More' => 0,

                    # demanded by Perl::Critic itself anyway,
                    # and comes with perl 5.10 anyway too
                    'version' => 0,
                   },
   clean     => { FILES => [ 'TAGS' ] },

   EXTRA_META => <<'HERE',
optional_features:
    maximum_tests:
        description: Have "make test" do as much as possible.
        requires:
            Test::Pod: 0
            Test::YAML::Meta: 0
            YAML: 0
            YAML::Syck: 0
            YAML::Tiny: 0
            YAML::XS: 0
no_index:
    directory:
        - devel
resources:
    homepage: http://www.geocities.com/user42_kevin/perl-critic-pulp/index.html
    license: http://www.gnu.org/licenses/#GPL
HERE
  );

sub MY::postamble {
  return <<'MAKE_FRAG';

LINT_FILES = $(TO_INST_PM) t/*.t devel/churn.pl
lint:
	for i in $(LINT_FILES); do perl -MO=Lint $$i; done
pc:
	-podchecker $(LINT_FILES)
	perlcritic $(LINT_FILES)
unused:
	(for i in $(LINT_FILES); do perl -c -Mwarnings::unused -I lib $$i; done) \
	  2>&1 | grep -v 'at /'

myman:
	-mv MANIFEST MANIFEST.old
	touch SIGNATURE
	(make manifest 2>&1; diff -u MANIFEST.old MANIFEST) |less

# find files in the dist with mod times this year, but without this year in
# the copyright line
copyright-years-check:
	year=`date +%Y`; \
	tar tvfz Perl-Critic-Pulp-$(VERSION).tar.gz \
	| egrep '$$year-|debian/copyright' \
	| sed 's:^.*Perl-Critic-Pulp-$(VERSION)/::' \
	| (result=0; \
	  while read i; do \
	    case $$i in \
	      '' | */ \
	      | debian/changelog | debian/compat \
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

diff-prev:
	rm -rf diff.tmp
	mkdir diff.tmp
	cd diff.tmp \
	&& tar xfz ../$(NAME)-`expr $(VERSION) - 1`.tar.gz \
	&& tar xfz ../$(NAME)-$(VERSION).tar.gz
	-cd diff.tmp; diff -ur $(NAME)-`expr $(VERSION) - 1` \
	                       $(NAME)-$(VERSION) >tree.diff
	-less diff.tmp/tree.diff
	rm -rf diff.tmp

TAG_FILES = $(TO_INST_PM)
TAGS: $(TAG_FILES)
	etags $(TAG_FILES)

MAKE_FRAG
}

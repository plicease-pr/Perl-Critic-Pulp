#!/usr/bin/perl

# 0-Test-YAML-Meta.t -- run Test::YAML::Meta if available

# Copyright 2009 Kevin Ryde

# 0-Test-YAML-Meta.t is shared by several distributions.
#
# 0-Test-YAML-Meta.t is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# 0-Test-YAML-Meta.t is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

use 5.000;
use strict;
use warnings;
use FindBin;
use File::Spec;
use Test::More;

plan skip_all =>
  "disabled -- Test::YAML::Meta 0.11 asks for 'optional_features' as a list, but think it's meant to be a map ...";



my $meta_filename = File::Spec->catfile
  ($FindBin::Bin, File::Spec->updir, 'META.yml');
open META, $meta_filename
  or plan skip_all => "Cannot open $meta_filename ($!) -- assume this is a working directory not a dist";
close META or die;

eval 'use Test::YAML::Meta; 1'
  or plan skip_all => "due to Test::YAML::Meta not available -- $@";

meta_yaml_ok();
exit 0;

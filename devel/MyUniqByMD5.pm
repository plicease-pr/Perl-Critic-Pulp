# Copyright 2009, 2010, 2011 Kevin Ryde.

# MyUniqByMD5.pm is shared by various distributions.
#
# MyUniqByMD5.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyUniqByMD5.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyUniqByMD5;
use strict;
use warnings;
use Digest::MD5;
use Perl6::Slurp;
use MyUniqByInode;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my ($class) = @_;
  return bless { seen => MyUniqByInode::tied_hashref(), # { },
               }, $class;
}

sub uniq_file {
  my ($self, $filename_or_fh) = @_;
  my $str;
  eval { $str = Perl6::Slurp::slurp($filename_or_fh); 1 } or return 1;
  return $self->uniq_str ($str);
}

sub uniq_str {
  my ($self, $str) = @_;
  my $key = Digest::MD5::md5 ($str);
  ### MyUniqByMD5 key: $key
  ### seen: exists $self->{'seen'}->{$key}
  # if (exists $self->{'seen'}->{$key}) { print "MyUniqByMD5:  suppress\n"; }

  my $seen = $self->{'seen'};
  return (! exists $seen->{$key}
          && ($seen->{$key} = 1));
}

1;
__END__

package main;
my $uniq = MyUniqByMD5->new;
print $uniq->uniq_file('/etc/passwd'),"\n";
print $uniq->uniq_file('/etc/passwd'),"\n";


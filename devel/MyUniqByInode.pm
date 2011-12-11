# Copyright 2009, 2010, 2011 Kevin Ryde.

# MyUniqByInode.pm is shared by various distributions.
#
# MyUniqByInode.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyUniqByInode.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


package MyUniqByInode;
use strict;
use warnings;
use File::Temp;
use SDBM_File;
use Fcntl;

# {
#   package File::Temp::SDBM;
#   sub new {
#     
#       $fh = File::Temp->new (SUFFIX => '.sdbm');
#   sub DESTROY {
#     my ($self) = @_;
#     $self->filename . '.dir';
#       $self->SUPER::DESTROY;
#   }
{
  my $t;
  my $dir;
  my $filename;
  sub tied_hashref {
    if (! $t) {
      my %hash;
      $dir = File::Temp->newdir;
      $filename = File::Spec->catfile ($dir->dirname, 'MyUniq.sdbm');
      print
        "tempfiles $filename.pag\n",
        "          $filename.dir\n";
      tie %hash, 'SDBM_File', $filename,  Fcntl::O_RDWR() | Fcntl::O_CREAT(), 0666
        or die $!;
      $t = \%hash;
    }
    return $t;
  }
  END {
    if ($filename) {
      print "tempfile $filename sizes ",
        -s "$filename.pag"," ",
          -s "$filename.dir","\n";
    }
  }
}

sub new {
  my ($class) = @_;
  return bless { seen => tied_hashref(), # { },
               }, $class;
}

sub uniq {
  my ($self, $filename_or_handle) = @_;
  my ($dev, $ino)
    = (ref $filename_or_handle && $filename_or_handle->can('stat')
       ? $filename_or_handle->stat
       : stat ($filename_or_handle));
  if (! defined $dev) { return 1; } # error treated as unique

  my $key = "$dev,$ino";
  ### $key
  my $seen = $self->{'seen'};
  ### seen: exists $seen->{$key}
  return (! exists $seen->{$key}
          && ($seen->{$key} = 1));
}

# sub stat_dev_ino {
#   my ($filename) = @_;
#   my ($dev, $ino) = stat ($filename);
#   if (! defined $dev) {
#     # print "Cannot stat: $filename\n";
#     return '';
#   }
#   return "$dev,$ino";
# }

1;
__END__

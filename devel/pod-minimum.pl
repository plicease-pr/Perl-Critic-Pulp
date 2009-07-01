
use strict;
use warnings;
use FindBin;
use File::Spec;
use Pod::MinimumVersion;
use Data::Dumper;

my $script_filename = File::Spec->catfile ($FindBin::Bin, $FindBin::Script);

{
  my $pmv = Pod::MinimumVersion->new
    (
     # string => "use 5.010; =encoding\n",
     # string => "=pod\n\nC<< foo >>",
     # filename => $script_filename,
     # filehandle => do { require IO::String; IO::String->new("=pod\n\nE<sol> E<verbar>") },
      string => "=pod\n\nL<foo|bar>",
     one_report_per_version => 1,
     above_version => '5.005',
    );

  print Dumper($pmv);
  print "min ", $pmv->minimum_version, "\n";
  print Dumper($pmv);

  my @reports = $pmv->reports;
  foreach my $report (@reports) {
    my $loc = $report->PPI_location;
    print $report->as_string,"\n";
    print Data::Dumper->new ([\$loc],['loc'])->Indent(0)->Dump,"\n";
  }
}

{
  require Perl::Critic;
  my $critic = Perl::Critic->new ('-profile' => '',
                                  '-single-policy' => 'PodMinimumVersion');
  require Perl::Critic::Violation;
  Perl::Critic::Violation::set_format("%f:%l:%c:\n %P\n %m\n %r\n");

  my $filename = $script_filename;
  my @violations;
  if (! eval { @violations = $critic->critique ($filename); 1 }) {
    print "Died in \"$filename\": $@\n";
    exit 1;
  }
  foreach my $violation (@violations) {
    print $violation;
    print $violation->filename,"\n";
    my $loc = $violation->location;
    print Data::Dumper->new ([\$loc],['loc'])->Indent(0)->Dump,"\n";
  }
  if (my $exception = Perl::Critic::Exception::Parse->caught) {
    print "Caught exception in \"$filename\": $exception\n";
  }
  exit 0;
}

use 5.002;

__END__

=encoding utf-8

=head1 Heading

J<< C<< x >> >>
C<< double >>
S<< double >>
L<C<Foo>|Footext>

=cut

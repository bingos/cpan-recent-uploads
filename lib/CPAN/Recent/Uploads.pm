package CPAN::Recent::Uploads;

#ABSTRACT: Find the distributions recently uploaded to CPAN

use strict;
use warnings;
use Carp;
use YAML::Syck;
use File::Spec;
use CPAN::Recent::Uploads::Retriever;

my $MIRROR = 'ftp://ftp.funet.fi/pub/CPAN/';
my @times = qw(1h 6h 1d 1W 1M 1Q 1Y);
my %periods  = ( 
  '1h' => (60*60),
  '6h' => (60*60*6),
  '1d' => (60*60*24),
  '1W' => (60*60*24*7),
  '1M' => (60*60*24*30),
  '1Q' => (60*60*24*90),
  '1Y' => (60*60*24*365.25),
);

sub recent {
  my $epoch = shift;
  $epoch = shift if $epoch and $epoch->isa(__PACKAGE__);
  $epoch = ( time() - ( 7 * 24 * 60 * 60 ) )
    unless $epoch and $epoch =~ /^\d+$/ and
      $epoch <= time() and $epoch >= ( time() - $periods{'1Y'} );
  my $period = _period_from_epoch( $epoch );
  my $mirror = shift || $MIRROR;
  my %data;
  my $finished;
  OUTER: while( !$finished ) {
    my $foo = shift @times;
    $finished = 1 if $foo eq $period;
    my $yaml = CPAN::Recent::Uploads::Retriever->retrieve( time => $foo, mirror => $mirror );
    my @yaml;
    eval { @yaml = YAML::Syck::Load( $yaml ); };
    croak "Unable to process YAML\n" unless @yaml;
    my $record = shift @yaml;
    die unless $record;
    RECENT: foreach my $recent ( reverse @{ $record->{recent} } ) {
      next RECENT unless $recent->{path} =~ /\.(tar\.gz|tgz|tar\.bz2|zip)$/;
      if ( $recent->{type} eq 'new' ) {
        ( my $foo = $recent->{path} ) =~ s#^id/##;
        next RECENT if $recent->{epoch} < $epoch;
        $data{ $foo } = $recent->{epoch};
      }
      else {
        ( my $foo = $recent->{path} ) =~ s#^id/##;
        delete $data{ $foo } if exists $data{ $foo };
      }
    }
  }
  return \%data unless wantarray;
  return sort { $data{$a} <=> $data{$b} } keys %data;
}

sub _period_from_epoch {
  my $epoch = shift || return;
  foreach my $period ( @times ) {
    return $period if ( time() - $periods{$period} ) < $epoch;
  }
  return;
}

q[Whats uploaded, Doc?];

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=over

=item C<recent>

=back

=cut

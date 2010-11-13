package CPAN::Recent::Uploads::Retriever;

#ABSTRACT: Retrieves recentfiles from a CPAN mirror

use strict;
use warnings;
use Carp;
use URI;
use LWP::UserAgent;
use File::Spec::Unix;

my @times = qw(1h 6h 1d 1W 1M 1Q 1Y);

sub retrieve {
  my $class = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  my $self = bless \%opts, $class;
  $self->{uri} = URI->new( $self->{mirror} || 'http://www.cpan.org/' );
  croak "Unknown scheme\n" 
      unless $self->{uri} and $self->{uri}->scheme and
             $self->{uri}->scheme =~ /^(http|ftp)$/i;
  $self->{time} = '6h' 
      unless $self->{time} 
         and grep { $_ eq $self->{time} } @times;
  $self->{uri}->path( File::Spec::Unix->catfile( $self->{uri}->path, 'authors', 'RECENT-' . $self->{time} . '.yaml' ) );
  return $self->_fetch();
}

sub _fetch {
  my $self = shift;
  open my $fooh, '>', \$self->{foo} or die "$!\n";
  my $ua = LWP::UserAgent->new();
  my $resp = $ua->get( $self->{uri}->as_string, ':content_cb' => sub { my $data = shift; print {$fooh} $data; } );
  close $fooh;
  return $self->{foo} if $resp->is_success;
}

q[Woof];

=pod

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=over

=item C<retrieve>

=back

=cut

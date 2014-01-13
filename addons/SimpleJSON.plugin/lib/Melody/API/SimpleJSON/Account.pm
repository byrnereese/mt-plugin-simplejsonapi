package Melody::API::SimpleJSON::Account;

use base qw( Melody::API::SimpleJSON );
use Melody::API::Twitter::Util
  qw( serialize_author twitter_date serialize_entries is_number );

###########################################################################

=head2 account/verify_credentials 

Returns an HTTP 200 OK response code and a representation of the requesting user 
if authentication was successful; returns a 401 status code and an error message 
if not.  Use this method to test if supplied user credentials are valid.
 
HTTP Method(s): GET
 
Requires Authentication: true
 
API rate limited: false
 
=cut

sub verify_credentials {
    my $app = shift;
    my ($params) = @_;
    return unless $app->SUPER::authenticate();

    my $user = $app->user;
    return { user => serialize_author($user) };

}

1;
__END__

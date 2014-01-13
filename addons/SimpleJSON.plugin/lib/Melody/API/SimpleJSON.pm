package Melody::API::SimpleJSON;

use strict;

use MT;
use MT::Util qw( encode_xml format_ts );
use MT::I18N qw( length_text substr_text );
use Melody::API::SimpleJSON::Util qw( debug );
use base qw( MT::App );

use constant {
    AUTH_REQUIRED => 1,
    AUTH_OPTIONAL => 0,
};

sub init {
    my $app = shift;
    debug('Initializing app.');
    $app->{no_read_body} = 1
      if $app->request_method eq 'POST' || $app->request_method eq 'PUT';

    # TODO - this is throwing off errors
    $app->SUPER::init(@_) 
        or return $app->error("Initialization failed");

    $app->request_content
      if $app->request_method eq 'POST' || $app->request_method eq 'PUT';
    $app->add_methods( handle => \&handle, );
    $app->{default_mode}  = 'handle';
    $app->{is_admin}      = 0;
    $app->{warning_trace} = 0;
    $app;
}

our $SUBAPPS = {
#    'users'           => 'Melody::API::SimpleJSON::User',
#    'account'         => 'Melody::API::SimpleJSON::Account',
    'entries'         => 'Melody::API::SimpleJSON::Entries',
    'blogs'           => 'Melody::API::SimpleJSON::Blogs',
    'help'            => 'Melody::API::SimpleJSON::Help'
};

sub handle {
    my $app = shift;
    my $out = eval {
        ( my $pi = $app->path_info ) =~ s!^/!!;
        debug( 'Path info: ' . $pi );
        $app->{param} = {};

        my ( $subapp, $method, $id, $format );

        if ( ( $subapp, $method, $id, $format ) =
            ( $pi =~ /^([^\/]*)\/([^\/]*)\/([^\.]*)\.(.*)$/ ) )
        {
            debug("Sub app: $subapp, method: $method, id: $id, format: $format");
        }
        elsif ( ( $subapp, $method, $format ) =
            ( $pi =~ /^([^\/]*)\/([^\.]*)\.(.*)$/ ) )
        {
            debug("Sub app: $subapp, method: $method, format: $format");
        }
        elsif ( ( $subapp, $format ) = ( $pi =~ /^([^\.]*)\.(.*)$/ ) ) {
            $method = $subapp;
            debug("Sub app: $subapp, method: $method, format: $format");
        }
        else {
            debug("Unrecognized query format.");
            # TODO - bail
        }
        $app->mode($method);

        my $args = {};
        for my $arg ( split( ';', $app->query_string ) ) {
            my ( $k, $v ) = split( /=/, $arg, 2 );
            $app->{param}{$k} = $v;
            $args->{$k} = $v;
        }
        if ($id) {
            $args->{id} = $id;
        }
        if ($format) {
            $args->{format} = $format;
        }
        if ( my $class = $SUBAPPS->{$subapp} ) {
            eval "require $class;";
            bless $app, $class;
        }
        my $out;
        if ( $app->can($method) ) {
            # Authentication should be defered to the designated handler since not
            # all methods require auth.
            use Data::Dumper;
            debug( "Calling $class::$method with args: " . Dumper($args) );
            $out = $app->$method($args);
        }
        else {
            debug("Drat, app can't process $method");
        }
        if ( $app->{_errstr} ) {
            debug('There was an error processing the request.');
            return;
        }
        return unless defined $out;
        my $out_enc;
        if ( lc($format) eq 'json' ) {
            $app->response_content_type('application/json');
            $out_enc = MT::Util::to_json($out, { pretty => 1 });
        }
        elsif ( lc($format) eq 'xml' ) {
            $app->response_content_type('text/xml');
            require XML::Simple;
            my $xml = XML::Simple->new;
            $out_enc = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
            $out_enc .= $xml->XMLout(
                $out,
                NoAttr    => 1,
                KeepRoot  => 1,
                GroupTags => { statuses => 'status' }
            );
        }
        else {

            # TODO - respond with indication that it is unsupported format
            return $app->error( 500, 'Unsupported format: ' . $format );
            $app->show_error("Internal Error");
            return;
        }
        #debug("Return as $format: $out_enc");
        return $out_enc;
    };
    my $e = $@;
    if ( $e ) {
        debug("An error occured generated encoded output");
        $app->error( 500, $e );
        $app->show_error("Internal Error");
    }
    $app->response_content($out);
}

sub get_auth_info {
    my $app = shift;
    my %param;

    my $auth_header = $app->get_header('Authorization')
      or return undef;

    debug( 'Authorization header present: ' . $auth_header );
    my ( $type, $creds_enc ) = split( " ", $auth_header );
    if ( lc($type) eq 'basic' ) {
        require MIME::Base64;
        my $creds = MIME::Base64::decode_base64($creds_enc);
        my ( $username, $password ) = split( ':', $creds );

        #debug( 'Username: ' . $username );
        #debug( 'Password (encoded): ' . $password );

        # Lookup user record
        my $user = MT::Author->load( { name => $username, type => 1 } )
          or return $app->auth_failure( 403, 'Invalid login' );
        $param{username} = $user->name;
        $app->user($user);

        # Make sure use has an API Password set
        return $app->auth_failure( 403, 'Invalid login. API Password not set.' )
          unless $user->api_password;

        # Make sure user is active
        return $app->auth_failure( 403, 'Invalid login. User is not active.' )
          unless $user->is_active;

        # Check to see if passwords match
        return $app->auth_failure( 403, 'Invalid login. Password mismatch.' )
          unless $user->api_password eq $password;

    }
    else {

        # Unsupported auth type
        # TODO: return unsupported
    }

    \%param;
}

sub authenticate {
    my $app = shift;
    my ($mode) = @_;
    debug('Attempting to authenticate user...');
    my $auth;
    if ( $mode == AUTH_REQUIRED ) {
        $auth = $app->get_auth_info
          or return $app->auth_failure( 401, "Unauthorized" );
    }
    elsif ( $mode == AUTH_OPTIONAL ) {
        $auth = $app->get_auth_info
          or return 0;
    }
    return 1;
}

sub auth_failure {
    my $app = shift;
    $app->set_header( 'WWW-Authenticate', 'Basic realm="api.localhost"' );
    return $app->error( @_, 1 );
}

=head2

This is what a Twitter Error looks like in XML.

<?xml version="1.0" encoding="UTF-8"?>
<hash>
  <request>/direct_messages/destroy/456.xml</request>
  <error>No direct message with that ID found.</error>
</hash>

=cut 

sub error {
    my $app = shift;
    my ( $code, $msg, $dont_send_body ) = @_;
    return unless ref($app) && $code && $msg; # TODO - figure out why error is being called from super classes
    debug("Processing error code='$code' with message: '$msg'");
    if ( $code && $msg ) {
        $app->response_code($code);
        $app->response_message($msg);
        $app->{_errstr} = $msg;
    }
    elsif ($code) {
        return $app->SUPER::error($code);
    }
    return undef if $dont_send_body;
    return {
        request => $app->path_info,
        error   => $msg,
    };
}

sub show_error {
    my $app = shift;
    my ($err) = @_;
    chomp( $err = encode_xml($err) );
    return <<ERR;
<error>$err</error>
ERR
}

1;
__END__

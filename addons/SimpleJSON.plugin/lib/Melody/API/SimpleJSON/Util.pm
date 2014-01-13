package Melody::API::SimpleJSON::Util;

use strict;

use base 'Exporter';
use MT::Util qw( format_ts caturl );
use MT::I18N qw( length_text substr_text );

our @EXPORT_OK =
  qw( serialize_entry_list serialize_author serialize_entries is_number debug );

sub debug {
    print STDERR $_[0] . "\n";
}

sub is_number {
    my ($n) = @_;
    return $n + 0 eq $n;
}

#{
#  id: 1,
#  title: 'Ancient Hidden Khmer City Discovered in Cambodia',
#  url: 'http://www.majordojo.com/2013/06/ancient-hidden-khmer-city-discovered-in-cambodia.php',
#  api_url: 'http://majordojo.com/cgi-bin/mt/plugins/json/api.cgi?blog_id=3&entry_id=1'
#}
sub serialize_entry_list {
    my ($entries) = @_;
    my $app = MT::App->instance;
    my $list = [];
    my @ids;
    foreach my $e (@$entries) {
        push @ids, $e->id;
        my $ser = {
            id         => $e->id,
            title      => $e->title,
	    url        => $e->permalink,
	    api_url    => caturl( $app->base, $app->uri, 'entries' ) . '?entry_id='.$e->id
        };
        push @$list, $ser;
    }
    return $list;
}

sub serialize_entries {
    my ($entries) = @_;
    my $statuses = [];
    my @ids;
    foreach my $e (@$entries) {
        my ( $trunc, $txt ) = truncate_tweet( $e->text );
        push @ids, $e->id;
        my $ser = {
            created_at => twitter_date( $e->created_on ),
            id         => $e->id,
            text       => $txt,
            source =>
              'Melody',  # TODO - replace with a meta data field I should create
            truncated => ( $trunc ? 'true' : 'false' ),
            in_reply_to_status_id   => '',
            in_reply_to_user_id     => '',
            favorited               => 'false',
            in_reply_to_screen_name => '',
            user                    => serialize_author( $e->author ),
            geo                     => undef,
        };
        if ( $e->geo_latitude && $e->geo_longitude ) {
            $ser->{geo} = $e->geo_latitude . " " . $e->geo_longitude;
        }
        push @$statuses, $ser;
    }
    return $statuses;
}

sub serialize_author {
    my ($a) = @_;
    $a ||= ();
    return {
        id                => $a->id,
        name              => $a->nickname,
        screen_name       => $a->name,
        location          => '',
        description       => '',
        profile_image_url => '',
        url               => $a->url,
        protected         => 'false',
        created_at        => twitter_date( $a->created_on ),

        #        followers_count,
        #        profile_background_color,
        #        profile_text_color,
        #        profile_link_color,
        #        profile_sidebar_fill_color,
        #        profile_sidebar_border_color,
        #        friends_count,
        #        favourites_count,
        #        utc_offset,
        #        time_zone,
        #        profile_background_image_url,
        #        profile_background_tile,
        #        statuses_count,
        #        notifications,
        #        following,
        #        verified,
    };
}

1;

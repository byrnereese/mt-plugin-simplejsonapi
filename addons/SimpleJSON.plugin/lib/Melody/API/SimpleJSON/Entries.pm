package Melody::API::SimpleJSON::Entries;

use strict;
use base qw( Melody::API::SimpleJSON );
use Melody::API::SimpleJSON::Util qw( debug serialize_entry_list serialize_comments serialize_author serialize_tags serialize_entry );
use MT::Util qw( caturl );

=head2 entries/show
=cut
sub show {
    debug('In Entries::show()');
    my $app       = shift;
#    my $is_authed = $app->SUPER::authenticate(AUTH_OPTIONAL);
    my ($params)  = @_;
    my $terms     = {};
    my $args      = {};
    my $entry     = MT->model('entry')->load( $params->{entry_id} );
    return serialize_entry( $entry );
}

=head2 entries/list
=cut
sub list {
    debug('In Entries::list()');
    my $app       = shift;
#    my $is_authed = $app->SUPER::authenticate(AUTH_OPTIONAL);
    my ($params)  = @_;
    my $terms     = {};
    my $args      = {
        sort_by   => 'id',
        direction => 'ascend',
    };

    # Validate input
#    if ( !$params->{user_id} && !$params->{screen_name} && $is_authed ) {
        # TODO - authenticate and set current context to current user
#        $params->{user_id} = $app->user->id;
#    }

    my $n    = 20;
    my $page = 1;
    if (   $params->{count}
        && is_number( $params->{count} )
        && $params->{count} <= 200 )
    {
        $n = $params->{count};
    }
#    if ( $params->{user_id} ) {
#        my $user = MT->model('author')->load( { name => $params->{user_id} } );
#        unless ($user) {
#            return $app->error( 404,
#                'User ' . $params->{user_id} . ' not found.' );
#        }
#        $terms->{author_id} = $params->{user_id};
#    }

#    if ( $params->{screen_name} ) {
#        my $join_str = '=entry_author_id';
#        $args->{join} = MT->model('author')->join_on(
#            undef,
#            {
#                'id'   => \$join_str,
#                'name' => $params->{screen_name},
#            }
#        );
#    }

    if ( $params->{blog_id} ) {
        $terms->{blog_id} = $params->{blog_id};
    }

    if ( $params->{max_id} ) {
        $terms->{id} = { '<=' => $params->{max_id} };
    }

    if ( $params->{since} ) {
        $terms->{id} = { '>' => $params->{since} };
    }

    if ( $params->{page} && is_number( $params->{page} ) ) {
        $page = $params->{page};
    }

    $args->{limit} = $n;
    $args->{offset} = ( $n * ( $page - 1 ) ) if $page > 1;

    my $iter = MT->model('entry')->load_iter( $terms, $args ); # load everything
    my @entries;

    my $i = 0;
  ENTRY: while ( my $e = $iter->() ) {
        push @entries, $e;
        $i++;
        #      $iter->end, last if $n && $i >= $n;
    }
    my $list = serialize_entry_list( \@entries, $params->{format} );
    my $last_id = $#entries >= 0 ? $entries[$#entries]->id : 0;
    debug('entry count=' . $#entries . ", n=".$n);
    return { 
        meta  => {
            'count' => ($#entries + 1),
            'total' => MT->model('entry')->count({ blog_id => $params->{blog_id} }),
            ($#entries + 1) >= $n ? 
                ( 'next' => caturl( $app->base, $app->uri, 'entries', 'list.'.$params->{format} ) . 
                  "?blog_id=" . $params->{blog_id} . 
                  "&since=" . $last_id )
                : ()
        },
        posts => $list 
    };
#    return { posts => { status => $statuses } };
}

1;
__END__

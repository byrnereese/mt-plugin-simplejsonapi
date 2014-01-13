package Melody::API::SimpleJSON::Util;

use strict;

use base 'Exporter';
use MT::Util qw( format_ts caturl );
use MT::I18N qw( length_text substr_text );

our @EXPORT_OK =
  qw( serialize_blog_list serialize_entry_list serialize_author serialize_entry serialize_comments serialize_tags 
      is_number debug );

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
    my ($entries,$format) = @_;
    my $app = MT::App->instance;
    my $list = [];
    my @ids;
    foreach my $e (@$entries) {
        push @ids, $e->id;
        my $ser = {
            id         => $e->id,
            title      => $e->title,
	    url        => $e->permalink,
	    api_url    => caturl( $app->base, $app->uri, 'entries','show.'.$format ) . '?entry_id='.$e->id
        };
        push @$list, $ser;
    }
    return $list;
}

sub serialize_blog_list {
    my ($blogs,$format) = @_;
    my $app = MT::App->instance;
    my $list = [];
    my @ids;
    foreach my $b (@$blogs) {
        push @ids, $b->id;
        my $ser = {
            id              => $b->id,
            name            => $b->name,
            url             => $b->site_url,
            entries_api_url => caturl( $app->base, $app->uri, 'entries', 'list.'.$format ) . '?blog_id='.$b->id
        };
        push @$list, $ser;
    }
    return $list;
}

=head2
{
    "id":1,
    "title":"Ancient Hidden Khmer City Discovered in Cambodia",
    "slug":"ancient-hidden-khmer-city-discovered-in-cambodia",
    "content":'<p><div style="float: right; margin: 0 0 20px 20px; width: 200px;"><a rel="lightbox" href="http://www.majordojo.com/taphrom.JPG" title="Ta Phrom"><img alt="Ta Phrom" src="http://www.majordojo.com/assets_c/2013/06/taphrom-thumb-200x266-3587.jpg" width="200" height="266" class="mt-image-right" style="" /></a></div>Archaeologists have discovered an ancient Khmer city that predates Angkor Wat by about 350 years using lasers that were able to map surface features through the canopy of the surrounding trees. The city has either been largely destroyed or buried by nature, so do not expect to see the kinds of amazing ruins like Ta Phrom (pictured to the right), but there remain artifacts that have been untouched by looters for centuries. </p><p>It is so exciting to know that there are still wondrous and amazing places on this Earth still yet to be discovered.</p><iframe width="560" height="315" src="http://www.youtube.com/embed/Ypoqdk2yy5U" frameborder="0" allowfullscreen></iframe>',
    "status":"published",
    "language":"en_US",
    "author_id":1,
    "created_at":946684800000,
    "created_by":1,
    "updated_at":946684800000,
    "updated_by":1,
    "published_at":946684800000,
    "published_by":1,
    "comments":[
        {
          id: 1,
          author: 'Byrne Reese',
          author_url: '',
          author_email: 'byrne@majordojo.com',
          content: 'Foo'
        }
        ],
    "tags":[
        {"name":"ancient"},
        {"name":"anthropology"},
        {"name":"archeology"},
        {"name":"cambodia"},
        {"name":"cities"},
        {"name":"khmer"},
        {"name":"video"}
        ]
}  
=cut
sub serialize_comment {
    my ($c,$format) = @_;
    my $ser = {
        id           => $c->id,
        author       => $c->author,
        author_url   => $c->url,
        author_email => $c->email,
        content      => $c->text
    };
    return $ser;
}
sub serialize_comments {
    my ($comments,$format) = @_;
    my $app = MT::App->instance;
    my $list = [];
    foreach my $c (@$comments) {
        debug($c);
        push @$list, serialize_comment($c);
    }
    return $list;
}
sub serialize_tags {
    my ($tags,$format) = @_;
    use Data::Dumper;
    debug("tags: " . Dumper($tags));
    my $app = MT::App->instance;
    my $list = [];
    foreach my $t (@$tags) {
        push @$list, { name => $t };
    }
    return $list;
}
sub serialize_author {
    my ($a,$format) = @_;
    my $ser = {
        id    => $a->id,
        name  => $a->name,
        url   => $a->url,
        email => $a->email
    };
    return $ser;
}
sub serialize_entry {
    my ($e,$format) = @_;
    my $ser = {
        id           => $e->id,
        title        => $e->title,
        slug         => $e->basename,
        text         => $e->text . $e->text_more,
        status       => $e->status,
        language     => "en_US",
        author       => serialize_author( $e->author ),
        created_at   => $e->created_on,
        created_by   => $e->created_by,
        updated_at   => $e->modified_on,
        updated_by   => $e->modified_by,
        published_at => $e->authored_on,
        published_by => $e->created_by,
        comments     => serialize_comments( $e->comments ),
        tags         => serialize_tags( [ $e->get_tags ] )
    };
    return $ser;
}

1;

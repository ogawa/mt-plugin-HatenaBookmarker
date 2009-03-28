# $Id$
package HatenaBookmarker::CMS;
use strict;

use MT;
use MT::Util;

##
## handlers
##
sub post_save_entry {
    my $class   = shift;
    my $app     = MT->instance;
    my ($entry) = @_;
    return
      unless $entry->isa('MT::Entry') && $entry->status == MT::Entry::RELEASE();
    MT::Util::start_background_task(
        sub {
            bookmark_entry( $app, $entry )
              or return $app->error( $app->errstr );
        }
    );
}

sub cms_post_save_entry {
    my $class = shift;
    my ( $app, $entry ) = @_;
    return
      unless $entry->isa('MT::Entry') && $entry->status == MT::Entry::RELEASE();
    MT::Util::start_background_task(
        sub {
            bookmark_entry( $app, $entry )
              or return $app->error( $app->errstr );
        }
    );
}

sub bookmark_entries {
    my $app   = shift;
    my $perms = $app->permissions;
    return $app->trans_error('Permission Denied.')
      unless $perms && $perms->can_create_post;

    my $type = $app->param('_type') || 'entry';
    my $class = MT->model($type);

    my @entry_ids = $app->param('id')
      or return $app->error(
        $app->translate( 'No [_1] was selected to bookmark.', $type ) );
    MT::Util::start_background_task(
        sub {
            for my $entry_id (@entry_ids) {
                my $entry = $class->load($entry_id)
                  or return $app->trans_error('Invalid entry_id');
                if ( $entry->status == MT::Entry::RELEASE() ) {
                    bookmark_entry( $app, $entry )
                      or return $app->error( $app->errstr );
                }
            }
        }
    );
    $app->call_return;
}

##
## main
##

sub bookmark_entry {
    my ( $app, $entry ) = @_;

    my $blog_id  = $entry->blog_id;
    my $entry_id = $entry->id;
    my $plugin   = $app->component('hatena_bookmarker');
    my $config   = $plugin->get_config_hash( 'blog:' . $blog_id ) or return;
    my $username = $config->{hatena_username}
      or return $app->error(
        $plugin->translate('You need to configure your hatena username.') );
    my $password = $config->{hatena_password}
      or return $app->error(
        $plugin->translate('You need to configure your hatena password.') );

    require HatenaBookmarker::Client;
    my $client = HatenaBookmarker::Client->new;
    $client->username($username);
    $client->password($password);

    my $editURI = $client->createBookmarkEntry( { url => $entry->permalink, } );
    require MT::Log;
    unless ($editURI) {
        $app->log(
            {
                message => $plugin->translate(
                    'Entry (ID:[_1]) has been failed to bookmark: [_2]',
                    $entry_id, $client->errstr
                ),
                level    => MT::Log::ERROR(),
                class    => 'entry',
                metadata => $entry_id,
            }
        );
        return;
    }

    my $bookmark = $client->getEntry($editURI);
    unless ($bookmark) {
        $app->log(
            {
                message => $plugin->translate(
'Entry (ID:[_1]) has been bookmarked, but has caused an error: [_2]',
                    $entry_id,
                    $client->errstr
                ),
                level    => MT::Log::ERROR(),
                class    => 'entry',
                metadata => $entry_id,
            }
        );
        return;
    }

    my $title = _create_bm_title( $entry, $config->{hatena_bm_title} );
    my $summary = _create_bm_summary($entry);

    my $enc = $app->config->PublishCharset || 'utf-8';
    require MT::I18N;
    $title   = MT::I18N::encode_text( $title,   $enc, 'utf-8' ) if $title;
    $summary = MT::I18N::encode_text( $summary, $enc, 'utf-8' ) if $summary;

    if ( $bookmark->title eq $title && $bookmark->summary eq $summary ) {
        $app->log(
            {
                message => $plugin->translate(
                    'Entry (ID:[_1]) has been skipped to bookmark.', $entry_id
                ),
                level    => MT::Log::INFO(),
                class    => 'entry',
                metadata => $entry_id,
            }
        );
        return;
    }

    my $res = $client->updateBookmarkEntry(
        $editURI,
        {
            $title   ? ( title   => $title )   : (),
            $summary ? ( summary => $summary ) : ()
        }
    );
    $app->log(
        {
            $res
            ? (
                message => $plugin->translate(
                    'Entry (ID:[_1]) has been successfully bookmarked.',
                    $entry_id
                ),
                level => MT::Log::INFO()
              )
            : (
                message => $plugin->translate(
                    'Entry (ID:[_1]) has been failed to bookmark: [_2]',
                    $entry_id, $client->errstr
                ),
                level => MT::Log::ERROR()
            ),
            class    => 'entry',
            metadata => $entry_id,
        }
    );
}

##
## utilities
##

# create a bookmark title from an MT::Entry and a format string
sub _create_bm_title {
    my ( $entry, $format ) = @_;

    require MT::Template::Context;
    my $ctx = MT::Template::Context->new;
    $ctx->stash( 'entry', $entry );
    $ctx->stash( 'blog',  $entry->blog );

    require MT::Builder;
    my $builder = MT::Builder->new;
    my $tokens = $builder->compile( $ctx, $format )
      or return $ctx->error( $builder->errstr );
    defined( my $title = $builder->build( $ctx, $tokens ) )
      or return $ctx->error( $builder->errstr );

    $title;
}

# create a bookmark summary from an MT::Entry
sub _create_bm_summary {
    my $entry = shift;
    _tags_to_text($entry) || _keywords_to_text($entry) || '';
}

# convert entry tags to a flattened text
sub _tags_to_text {
    my $entry = shift;
    return '' unless $entry->can('tags');

    my $text = '';
    for my $tag ( $entry->tags ) {
        $text .= '[' . $tag . ']';
    }
    $text;
}

# convert entry keywords to a flattened text
sub _keywords_to_text {
    my $entry = shift;
    my $str = $entry->keywords or return '';
    $str =~ s/\#.*$//g;
    $str =~ s/(^\s+|\s+$)//g;
    return '' unless $str;

    my $text = '';
    if ( $str =~ m/[;,|]/ ) {

        # separated by non-whitespaces
        while ( $str =~ m/(\[[^]]+\]|"[^"]+"|'[^']+'|[^;,|]+)/g ) {
            my $tag = $1;
            $tag =~ s/(^[\["'\s;,|]+|[\]"'\s;,|]+$)//g;
            $text .= '[' . $tag . ']' if $tag;
        }
    }
    else {

        # separated by whitespaces
        while ( $str =~ m/(\[[^]]+\]|"[^"]+"|'[^']+'|[^\s]+)/g ) {
            my $tag = $1;
            $tag =~ s/(^[\["'\s]+|[\]"'\s]+$)//g;
            $text .= '[' . $tag . ']' if $tag;
        }
    }
    $text;
}

1;

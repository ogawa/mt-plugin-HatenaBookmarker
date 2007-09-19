# A plugin for posting an entry as a hatena bookmark
#
# $Id$
#
# This software is provided as-is. You may use it for commercial or 
# personal use. If you distribute it, please keep this notice intact.
#
# Copyright (c) 2006,2007 Hirotaka Ogawa
#
package MT::Plugin::HatenaBookmarker;
use strict;
use base qw(MT::Plugin);

use MT;

our $VERSION = '0.01';

my $plugin = __PACKAGE__->new({
    id                   => 'hatena_bookmaker',
    name                 => 'HatenaBookmarker',
    description          => q(<MT_TRANS phrase="HatenaBookmaker allows you to create a hatena bookmark to your entry when publishing entries.">),
    doc_link             => 'http://code.as-is.net/wiki/HatenaBookmarker',
    author_name          => 'Hirotaka Ogawa',
    author_link          => 'http://as-is.net/blog/',
    version              => $VERSION,
    l10n_class           => 'HatenaBookmarker::L10N',
    blog_config_template => 'config.tmpl',
    settings             => new MT::PluginSettings([
	['hatena_username', { Default => '' }],
	['hatena_password', { Default => '' }]
    ])
});
MT->add_plugin($plugin);

sub init_registry {
    my $plugin = shift;
    my $callbacks;
    if (MT->instance->isa('MT::App::CMS')) {
	$callbacks = { 'cms_post_save.entry' => \&cms_post_save_entry };
    } else {
	$callbacks = { 'MT::Entry::post_save' => \&post_save_entry };
    }
    $plugin->registry({
	callbacks => $callbacks
    });
}

sub post_save_entry {
    my $class = shift;
    my ($entry) = @_;
    return unless $entry->isa('MT::Entry') && $entry->status == MT::Entry::RELEASE();
    MT::Util::start_background_task(
	sub { do_bookmark(MT->instance, $entry) }
    );
}

sub cms_post_save_entry {
    my $class = shift;
    my ($app, $entry) = @_;
    return unless $entry->isa('MT::Entry') && $entry->status == MT::Entry::RELEASE();
    MT::Util::start_background_task(
	sub { do_bookmark($app, $entry) }
    );
}

use MT::Log;
use MT::I18N;
use HatenaBookmarker::Client;

sub do_bookmark {
    my ($app, $entry) = @_;

    my $blog_id = $entry->blog_id;
    my $entry_id = $entry->id;
    my $config = $plugin->get_config_hash('blog:' . $blog_id) or return;
    my $username = $config->{hatena_username} or return;
    my $password = $config->{hatena_password} or return;

    my $client = HatenaBookmarker::Client->new;
    $client->username($username);
    $client->password($password);

    my $editURI = $client->createBookmarkEntry({
	url => $entry->permalink,
    });
    unless ($editURI) {
	$app->log({
	    message  => $plugin->translate('Entry (ID:[_1]) has been failed to bookmark: [_2]', $entry_id, $client->errstr),
	    level    => MT::Log::ERROR(),
	    class    => 'entry',
	    metadata => $entry_id,
	});
	return;
    }

    my $bookmark = $client->getEntry($editURI);
    unless ($bookmark) {
	$app->log({
	    message  => $plugin->translate('Entry (ID:[_1]) has been bookmarked, but has caused an error: [_2]', $entry_id, $client->errstr),
	    level    => MT::Log::ERROR(),
	    class    => 'entry',
	    metadata => $entry_id,
	});
	return;
    }

    my $saved_title   = $bookmark->title;
    my $saved_summary = extract_summary($bookmark);
    my $title         = $entry->blog->name . ': ' . $entry->title;
    my $summary       = tags2summary($entry) || keywords2summary($entry->keywords) || '';

    my $enc = $app->config->PublishCharset || 'utf-8';
    $title   = MT::I18N::encode_text($title  , $enc, 'utf-8') if $title  ;
    $summary = MT::I18N::encode_text($summary, $enc, 'utf-8') if $summary;

    if ($saved_title eq $title && $saved_summary eq $summary) {
	$app->log({
	    message  => $plugin->translate('Entry (ID:[_1]) has been skipped to bookmark.', $entry_id),
	    level    => MT::Log::INFO(),
	    class    => 'entry',
	    metadata => $entry_id,
	});
	return;
    }

    if ($client->updateBookmarkEntry($editURI, {
	$title   ? (title   => $title  ) : (),
	$summary ? (summary => $summary) : ()
    })) {
	$app->log({
	    message  => $plugin->translate('Entry (ID:[_1]) has been successfully bookmarked.', $entry_id),
	    level    => MT::Log::INFO(),
	    class    => 'entry',
	    metadata => $entry_id,
	});
    } else {
	$app->log({
	    message  => $plugin->translate('Entry (ID:[_1]) has been failed to bookmark: [_2]', $entry_id, $client->errstr),
	    level    => MT::Log::ERROR(),
	    class    => 'entry',
	    metadata => $entry_id,
	});
    }
}

# extract summary text from a hatena entry
sub extract_summary {
    my ($entry) = @_;
    my $summary = '';
    my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
    for my $subject ($entry->getlist($dc, 'subject')) {
	$summary .= '[' . $subject . ']';
    }
    $summary;
}

# convert MT keywords to summary text
sub keywords2summary {
    my ($str) = @_;
    return '' unless $str;
    $str =~ s/\#.*$//g;
    $str =~ s/(^\s+|\s+$)//g;
    return '' unless $str;

    my $summary = '';
    if ($str =~ m/[;,|]/) {
	# separated by non-whitespaces
	while ($str =~ m/(\[[^]]+\]|"[^"]+"|'[^']+'|[^;,|]+)/g) {
	    my $tag = $1;
	    $tag =~ s/(^[\["'\s;,|]+|[\]"'\s;,|]+$)//g;
	    $summary .= '[' . $tag . ']' if $tag;
	}
    } else {
	# separated by whitespaces
	while ($str =~ m/(\[[^]]+\]|"[^"]+"|'[^']+'|[^\s]+)/g) {
	    my $tag = $1;
	    $tag =~ s/(^[\["'\s]+|[\]"'\s]+$)//g;
	    $summary .= '[' . $tag . ']' if $tag;
	}
    }
    $summary;
}

# convert MT tags to summary text
sub tags2summary {
    my $entry = shift;
    return '' unless $entry->can('tags');

    my $summary = '';
    for my $tag ($entry->tags) {
	$summary .= '[' . $tag . ']';
    }
    $summary;
}

1;

# A plugin for posting an entry as a hatena bookmark
#
# $Id$
#
# This software is provided as-is. You may use it for commercial or
# personal use. If you distribute it, please keep this notice intact.
#
# Copyright (c) 2006-2007,2009 Hirotaka Ogawa
#
package MT::Plugin::HatenaBookmarker;
use strict;
use base qw( MT::Plugin );

use MT 4.2;

our $VERSION = '0.10';

my $plugin = __PACKAGE__->new(
    {
        id   => 'hatena_bookmaker',
        name => 'Hatena Bookmarker',
        description =>
q(<MT_TRANS phrase="HatenaBookmaker allows you to create a hatena bookmark to your entry when publishing entries.">),
        doc_link    => 'http://code.as-is.net/public/wiki/HatenaBookmarker',
        author_name => 'Hirotaka Ogawa',
        author_link => 'http://as-is.net/blog/',
        version     => $VERSION,
        l10n_class  => 'HatenaBookmarker::L10N',
        blog_config_template => 'config.tmpl',
        settings             => new MT::PluginSettings(
            [
                [ 'hatena_username', { Default => '' } ],
                [ 'hatena_password', { Default => '' } ],
                [
                    'hatena_bm_title',
                    {
                        Default =>
q(<$mt:BlogName encode_html="1"$>: <$mt:EntryTitle encode_html="1"$>)
                    }
                ],
            ]
        )
    }
);
MT->add_plugin($plugin);

sub instance { $plugin }

sub init_registry {
    my $plugin = shift;
    my $pkg = 'HatenaBookmarker::CMS::';
    if ( !MT->instance->isa('MT::App::CMS') ) {
        $plugin->registry(
            { callbacks => { 'MT::Entry::post_save' => "${pkg}post_save_entry" } } );
        return;
    }
    $plugin->registry(
        {
            callbacks    => { 'cms_post_save.entry' => "${pkg}cms_post_save_entry" },
            applications => {
                cms => {
                    list_actions => {
                        entry => {
                            bookmark_entry => {
                                label => 'Bookmark Entries',
                                continue_prompt =>
'Are you sure you want to bookmark the selected entries?',
                                code       => "${pkg}bookmark_entries",
                                permission => 'create_post',
                            }
                        },
                        page => {
                            bookmark_page => {
                                label => 'Bookmark Pages',
                                continue_prompt =>
'Are you sure you want to bookmark the selected pages?',
                                code       => "${pkg}bookmark_entries",
                                permission => 'create_post',
                            }
                        },
                    }
                }
            }
        }
    );
}

1;

# $Id$
package HatenaBookmarker::Client;
use strict;
use base qw( XML::Atom::Client );

use XML::Atom::Entry;
use XML::Atom::Link;

# create an entry for hatena bookmark
# 'url' is mandatory
sub createBookmarkEntry {
    my $client = shift;
    my ($param) = @_;

    my $entry = XML::Atom::Entry->new;
    $entry->title( $param->{title} || 'dummy' );
    $entry->summary( $param->{summary} ) if $param->{summary};

    my $link = XML::Atom::Link->new;
    $link->type('text/html');
    $link->rel('related');
    $link->href( $param->{url} );
    $entry->add_link($link);

    $client->username( $param->{username} ) if $param->{username};
    $client->password( $param->{password} ) if $param->{password};

    $client->createEntry( 'http://b.hatena.ne.jp/atom/post', $entry );
}

sub getBookmarkEntry { getEntry(@_) }

# update an entry for hatena bookmark
# 'editURI' is mandatory
sub updateBookmarkEntry {
    my $client  = shift;
    my $editURI = shift;
    my ($param) = @_;

    my $entry = XML::Atom::Entry->new;
    $entry->title( $param->{title} || 'dummy' );
    $entry->summary( $param->{summary} ) if $param->{summary};

    $client->username( $param->{username} ) if $param->{username};
    $client->password( $param->{password} ) if $param->{password};

    $client->updateEntry( $editURI, $entry );
}

1;

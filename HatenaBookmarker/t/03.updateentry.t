#!/usr/bin/perl

use lib qw(lib extlib plugins/HatenaBookmarker plugins/HatenaBookmarker/lib);

use HatenaBookmarkClient;
my $client = HatenaBookmarkClient->new;
$client->username('...');
$client->password('...');
my $editURI = $client->createBookmarkEntry({
    url => 'http://www.movabletype.org/',
});
$client->updateBookmarkEntry($editURI, {
    title => 'test',
    summary => 'test',
});

# $Id$
package HatenaBookmarker::L10N::ja;

use strict;
use base 'HatenaBookmarker::L10N';
use vars qw( %Lexicon );

our %Lexicon = (
    'HatenaBookmaker allows you to create a hatena bookmark to your entry when publishing entries.' => 'HatenaBookmarkerを用いると、ブログ記事などの公開時にその記事への「はてなブックマーク」を生成することができます。',
    'Entry (ID:[_1]) has been failed to bookmark: [_2]' => 'エントリ (ID:[_1]) のブックマークに失敗しました: [_2]',
    'Entry (ID:[_1]) has been bookmarked, but has caused an error: [_2]' => 'エントリ (ID:[_1]) はブックマークされましたが、何らかのエラーが発生しました: [_2]',
    'Entry (ID:[_1]) has been skipped to bookmark.' => 'エントリ (ID:[_1]) のブックマークは重複しているためスキップされました。',
    'Entry (ID:[_1]) has been successfully bookmarked.' => 'エントリ (ID:[_1]) は正常にブックマークされました。',
    'Hatena Username' => 'はてなIDのユーザ名',
    'Hatena Password' => 'はてなIDのパスワード',
);

1;

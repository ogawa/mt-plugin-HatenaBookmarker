# $Id$
package HatenaBookmarker::L10N::ja;
use strict;
use base qw( HatenaBookmarker::L10N::en_us );
use vars qw( %Lexicon );
%Lexicon = (
'HatenaBookmaker allows you to create a hatena bookmark to your entry when publishing entries.'
      => 'HatenaBookmarkerを用いると、ブログ記事などの公開時にその記事への「はてなブックマーク」を生成することができます。',
    '[_1] (ID:[_2]) has been failed to bookmark: [_3]' =>
      '[_1] (ID:[_2]) のブックマークに失敗しました: [_3]',
    '[_1] (ID:[_2]) has been bookmarked, but has caused an error: [_3]' =>
'[_1] (ID:[_2]) はブックマークされましたが、何らかのエラーが発生しました: [_3]',
    '[_1] (ID:[_2]) has been skipped to bookmark.' =>
'[_1] (ID:[_2]) のブックマークは重複しているためスキップされました。',
    '[_1] (ID:[_2]) has been successfully bookmarked.' =>
      '[_1] (ID:[_2]) は正常にブックマークされました。',
    'Hatena Username'       => 'はてなIDのユーザ名',
    'Hatena Password'       => 'はてなIDのパスワード',
    'Bookmark Title Format' => 'ブックマークのタイトルの形式',
    'Bookmark Entries'      => 'ブログ記事のブックマーク',
    'Are you sure you want to bookmark the selected entries?' =>
'選択したブログ記事をブックマークしてよろしいですか?',
    'Bookmark Pages' => 'ウェブページのブックマーク',
    'Are you sure you want to bookmark the selected pages?' =>
'選択したウェブページをブックマークしてよろしいですか?',
    'You need to configure your hatena username.' =>
      'はてなIDのユーザ名を設定する必要があります。',
    'You need to configure your hatena password.' =>
      'はてなIDのパスワードを設定する必要があります。',
);

1;

use strict;
use warnings;

# 素材テキストを読み込んで変換 ---------------------------------------------------------------------------------------

    my $input_file  = "01_onmark/source_mokuji.txt";     # sourceの目次ファイル抜粋部分
    my $output_file1 = "01_onmark/onmark_toc.html";         # 出力ファイル
    my $output_file2 = "01_onmark/getset_toc.html"; # 出力ファイル

    # 検討用
#    my $output_file = "01_adjust/test_toc.html";         # 出力ファイル

open my $in,  '<', $input_file  or die "Cannot open $input_file: $!";
open my $out1, '>', $output_file1 or die "Cannot open $output_file1: $!";
open my $out2, '>', $output_file2 or die "Cannot open $output_file2: $!";

    # プレビュー用に貼るヘッダーを取り込む
    open my $header1, '<', '01_onmark/arrange_preview_hedder.txt' or die "Cannot open arrange_preview_hedder.txt: $!";
    open my $header2, '<', '01_onmark/arrange_preview_hedder.txt' or die "Cannot open arrange_preview_hedder.txt: $!";
    # 先にヘッダーの内容を出力
    print $out1 join("", <$header1>);
    print $out2 join("", <$header2>);
    close $header1;
    close $header2;

while (<$in>) {
    my $content = $_;  # 読み込んだ行を変数に格納

    # 置換リスト -----------------------------------------------------------------------------------------------------

    $content =~ s/_idGenStoryDirection-2/_idGen_toc/g;                      # 目次ページタグに変換のため

    $content =~ s/#_idTextAnchor/#toc-/g;                                   # <p 本文を <>化

    $content =~ s/<p.*?>/<p>/g;

    $content =~ s/\t//g;                                                                        #タブを除去

    # 汎用性に疑問符
    $content =~ s/<span class="ハイパーリンク _idGenCharOverride-.">(.*?)<\/span>/$1/g;
    $content =~ s/<span class="ハイパーリンク">(.*?)\/<span>/$1/g;
    $content =~ s/<span class="ハイパーリンク">&#9;&#9;<\/span>//g;
    $content =~ s/<span class="ハイパーリンク">(.*?)<\/span>/$1/g;
    $content =~ s/<span class="_idGenCharOverride-1">/<span class="tcy">/g;

    # 汎用的ではない見込み
    $content =~ s/<span class="…">&#9;&#9;&#9;<\/span>//g;
    $content =~ s/<span class="…">&#9;&#9;<\/span>//g;
    $content =~ s/<span class="…">&#9;<\/span>//g;



#    $content =~ s///g;
#    $content =~ s///g;
#    $content =~ s///g;
#    $content =~ s///g;
#    $content =~ s///g;


#   追加の未処理
#   プレビュー用ヘッダー.txtを読み込み、出力ファイルの先頭に配置（vscodeでプレビューが可能になる）

    # 変換後の内容を書き出す
    print $out1 $content;
    print $out2 $content;
}
close $in;
close $out1;
close $out2;

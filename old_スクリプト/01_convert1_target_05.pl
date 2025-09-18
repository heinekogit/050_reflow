use strict;
use warnings;

# 素材テキストを読み込んで変換 ---------------------------------------------------------------------------------------

    #テスト用
#    open my $in, '<', '01_adjust/source_original.html' or die "Cannot open source: $!";

    #本番用
    open my $in, '<', '01_adjust/source.html' or die "Cannot open source: $!";
    open my $out, '>', '01_adjust/pre_target.html' or die "Cannot open output: $!";

while (<$in>) {
    my $content = $_;  # 読み込んだ行を変数に格納

    # 置換リスト -----------------------------------------------------------------------------------------------------
    $content =~ s|<html xmlns="http://www.w3.org/1999/xhtml" lang="ja-JP">|<html\n xmlns="http://www.w3.org/1999/xhtml"\n xmlns:epub="http://www.idpf.org/2007/ops"\n xml:lang="ja"\n class="vrtl"\n>|;

    $content =~ s|(<title>(.*?)<\/title>)|$1\n\t<link href="style\/style-standard.css" rel="stylesheet" type="text\/css" />|;

    $content =~ s/<div id="_idContainer..." class="基本テキストフレーム _idGenStoryDirection-(.)">/<div class="_idGenStoryDirection-$1">/g;     # 改ページ位置明示の前措置（→ ここも改ページとする）

    $content =~ s/<p class="本文">/<p>/g;                                                       # <p 本文を <>化
    $content =~ s/<img class="_idGenObjectAttribute-\d+" src="(.*?)\/(.*?)" alt="" \/>/<p><img src="..\/$2" alt="" class="fit" \/><\/p>/g;
                                                                                                # イメージタグ正規化1
    next if $content =~ /^\s*<figure id="_idContainer...">\s*$/;            # イメージタグ正規化2
    next if $content =~ /^\s*<\/figure>\s*$/;                                # イメージタグ正規化2

    # 追加：改ページコメントを挿入
    $content =~ s|(<div class="_idGen[^>]*>)|$1 <!--改ページ位置 --------------------------------------------->|g;


    $content =~ s/<p class="h1_章タイトル">(.*?)<\/p>/<h1>$1<\/h1>/g;
    $content =~ s/<p class="h2_節タイトル">(.*?)<\/p>/<h2>$1<\/h2>/g;
    $content =~ s/<p class="h3_項タイトル">(.*?)<\/p>/<h3>$1<\/h3>/g;
    $content =~ s/<p class="h4_目タイトル">(.*?)<\/p>/<h4>$1<\/h4>/g;

    $content =~ s/<p class="脚注">(.*?)<\/p>/<div class="start-3em h-indent-3em">$1<\/div>/g;     # 脚注
    $content =~ s/<rt class="_idGenRuby-.">/<rt>/g;                                             # ルビ正規化
    $content =~ s/<p>　<\/p>/<p><br \/><\/p>/g;                                                    # 一行アケ正規化

    $content =~ s/<span class="_idGenCharOverride-.">(...)<\/span>/<span class="tcy">$1<\/span>/g;     # 縦中横英数字3文字
    $content =~ s/<span class="_idGenCharOverride-.">(..)<\/span>/<span class="tcy">$1<\/span>/g;     # 縦中横英数字2文字
    $content =~ s/<span class="_idGenCharOverride-.">(.)<\/span>/<span class="tcy">$1<\/span>/g;     # 縦中横英数字1文字

    $content =~ s/\t//g;                                                                        #タブを除去
    $content =~ s/^(.*?)<a id="_idTextAnchor(...)"><\/a>/<a id="toc-$2"><\/a>$1/g;              #aタグの位置補正

#    $content =~ s///g;
#    $content =~ s///g;
#    $content =~ s///g;
#    $content =~ s///g;
#    $content =~ s///g;

    # 変換後の内容を書き出す
    print $out $content;
}
close $in;
close $out;

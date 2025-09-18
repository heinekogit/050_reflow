use strict;
use warnings;
use Encode;
use utf8;

my $log_message = "";  # ログメッセージを集約する変数
my $log_message_tcy = "";  # 二桁英数字に tcy を付加する処理のログメッセージ
my $log_message_space = "";  # 本文中の半角スペースを検索・置換する処理のログメッセージ

# 素材テキストを読み込んで変換 -------------------------------------------------------------------------

my $input_file   = "01_onmark/source.html";              # source
my $output_file1 = "01_onmark/onmark_target.html";      # 出力ファイル1
my $output_file2 = "01_onmark/getset_target.html";      # 出力ファイル2。02_getsetに手動で移動要（自動変換の上書き防止用）
my $output_report = "02_getset/report.txt";             # 出力ログ

# report.txt を初期化
open my $out_log, '>:encoding(UTF-8)', $output_report or die "Cannot open $output_report: $!";
close $out_log;

open my $in_source, '<:encoding(UTF-8)', $input_file or die "Cannot open source.html: $!";
open my $out_target1, '>:encoding(UTF-8)', $output_file1 or die "Cannot open pre_target.html: $!";
open my $out_target2, '>:encoding(UTF-8)', $output_file2 or die "Cannot open pre_target.html: $!";

while (<$in_source>) {
    my $content = $_;  # 読み込んだ行を変数に格納
#    $content = decode('UTF-8', $content);

    # 置換リスト ====================================================================================

    $content =~ s|<html xmlns="http://www.w3.org/1999/xhtml" lang="ja-JP">|<html\n xmlns="http://www.w3.org/1999/xhtml"\n xmlns:epub="http://www.idpf.org/2007/ops"\n xml:lang="ja"\n class="vrtl"\n>|;

#    $content =~ s|(<title>(.*?)<\/title>)|$1\n\t<link href="arrange_style\/style-standard.css" rel="stylesheet" type="text\/css" />|;
    $content =~ s|(<title>(.*?)<\/title>)|$1\n\t<link href="..\/01_onmark\/arrange_style\/style-standard.css" rel="stylesheet" type="text\/css" />|;

    $content =~ s|(<link href="source-web-resources)|<link href="..\/01_onmark\/source-web-resources|g;


    $content =~ s/<div id="_idContainer..." class="基本テキストフレーム _idGenStoryDirection-(.)">/<div class="_idGenStoryDirection-$1">/g;     # 改ページ位置明示の前措置（→ ここも改ページとする）

    $content =~ s/<p class="本文.*?>/<p>/g;                                                     # <p 本文を <>化
    $content =~ s/<p class="本文">/<p>/g;                                                       # <p 本文を <>化
    $content =~ s/<img class="_idGenObjectAttribute-\d+" src="(.*?)\/(.*?)" alt="" \/>/<p><img src="..\/$2" alt="" class="fit" \/><\/p>/g;
                                                                            # イメージタグ正規化1
    next if $content =~ /^\s*<figure id="_idContainer...">\s*$/;            # イメージタグ正規化2
    next if $content =~ /^\s*<\/figure>\s*$/;                                # イメージタグ正規化2

    $content =~ s|(<div class="_idGen[^>]*>)|$1 <!--改ページ位置 --------------------------------------------->|g;                      # 追加：改ページコメント挿入

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

    $content =~ s/イデ1/h-indent-1em/g;             # 段落1字下げ
    $content =~ s/イデ2/h-indent-2em/g;             # 段落2字下げ
    $content =~ s/イデ3/h-indent-3em/g;             # 段落3字下げ
    $content =~ s/ブラ1/h-indent-1em/g;             # ぶら下げ1字
    $content =~ s/ブラ2/h-indent-2em/g;             # ぶら下げ2字
    $content =~ s/ブラ3/h-indent-3em/g;             # ぶら下げ3字

    $content =~ s/注釈/ref/g;                       # 脚注
    $content =~ s/枠/k-solid/g;                       # 枠

    # 以下、ログ付き変換で内容検証要の変換や検索レポート ----------------------------------------------------
# ok    ・$content =~ s/([ぁ-ん一-龥])([0-9]{2})([ぁ-ん一-龥])/$1<span class="tcy">$2<\/span>$3/g;
# ok    ・本文中の半角スペースを検索・置換（　(<[^>]+>[^<]*?) ([^<]*?<\/[^>]+>)　→　$1$2）
#   ・1桁英数字の扱い、全角に
#   ・文字化け要因
#   ・漢字
#   ・

# 二桁英数字に tcy を付加し、変換があった場合はログへ出力するバージョン
my $content_before = $content;  # 変換前のコンテンツを保存

if ($content =~ s/([ぁ-ん一-龥])([0-9]{2})([ぁ-ん一-龥])/$1<span class="tcy">$2<\/span>$3/g) {
    unless ($log_message_tcy =~ /【二桁英数字に tcy を付加】====================================================/) {
        $log_message_tcy .= "【二桁英数字に tcy を付加】====================================================\n";
    }
    
    # 変換された部分を出力
    my @lines_before = split /\n/, $content_before;
    my @lines_after = split /\n/, $content;
    for my $i (0..$#lines_before) {
        if ($lines_before[$i] ne $lines_after[$i]) {
            $log_message_tcy .= "Before: \n$lines_before[$i]\n";
            $log_message_tcy .= "After: \n$lines_after[$i]\n\n";
        }
    }
}

# 本文中の半角スペースを検索・置換し、変換があった場合はログへ出力するバージョン
$content_before = $content;  # 変換前のコンテンツを保存

if ($content =~ s/(<[^>]+>[^<]*?) ([^<]*?<\/[^>]+>)/$1$2/g) {
    unless ($log_message_space =~ /【本文中の半角スペースを検索・置換】====================================================/) {
        $log_message_space .= "【本文中の半角スペースを検索・置換】====================================================\n";
    }
    
    # 変換された部分を出力
    my @lines_before = split /\n/, $content_before;
    my @lines_after = split /\n/, $content;
    for my $i (0..$#lines_before) {
        if ($lines_before[$i] ne $lines_after[$i]) {
            $log_message_space .= "Before: \n$lines_before[$i]\n";
            $log_message_space .= "After: \n$lines_after[$i]\n\n";
        }
    }
}


    # 置換リスト 終了 ===============================================================================

    # 変換後の内容を書き出す（2つのファイルに）
    print $out_target1 $content;
    print $out_target2 $content;
}

# ログメッセージをファイルに書き出す
if ($log_message_tcy || $log_message_space) {
    open my $out_log, '>>:encoding(UTF-8)', $output_report or die "Cannot open $output_report: $!";
    print $out_log $log_message_tcy if $log_message_tcy;
    print $out_log $log_message_space if $log_message_space;
    close $out_log;
}

close $in_source;
close $out_target1;
close $out_target2;

print "Processing complete. Output saved to:\n";
print "  - 01_onmark/onmark_target.html\n";
print "  - 01_onmark/getset_target.html\n";
print "  - 02_getset/report.txt\n";
use strict;
use warnings;
use Encode;
use utf8;
use File::Copy;  # ファイルコピー用モジュール

my $log_message = "";  # ログメッセージを集約する変数
my $log_message_tcy = "";  # 二桁英数字に tcy を付加する処理のログメッセージ
my $log_message_space = "";  # 本文中の半角スペースを検索・置換する処理のログメッセージ
my $log_message_fullwidth = "";  # 一桁英数字を全角英数字に変換する処理のログメッセージ

my @shosi;
my @koumoku_content;
my $source_mokuji_tempfile;
my $destination_mokuji_file;
my $source_annotation_tempfile;
my $destination_annotation_file;

# 素材テキストを読み込んで変換 -------------------------------------------------------------------------

my $input_file   = "03_setup/source.html";              # source
my $output_file1 = "03_setup/backup_target.xhtml";      # 出力ファイル1
my $output_file2 = "03_setup/arrange_target.xhtml";      # 出力ファイル2。04_arrangeに手動で移動要（自動変換の上書き防止用）
my $output_report = "04_arrange/report.txt";             # 出力ログ

# report.txt を初期化
open my $out_log, '>:encoding(UTF-8)', $output_report or die "Cannot open $output_report: $!";
close $out_log;

open my $in_source, '<:encoding(UTF-8)', $input_file or die "Cannot open source.html: $!";
open my $out_target1, '>:encoding(UTF-8)', $output_file1 or die "Cannot open pre_target.xhtml: $!";
open my $out_target2, '>:encoding(UTF-8)', $output_file2 or die "Cannot open pre_target.xhtml: $!";

# 前提。shosi.csvの読み込み  ==========================================================

    open(IN_SHOSI, "<:encoding(UTF-8)", "05_assemble/shosi.csv") or die "cant open shosi\n";
    @shosi = <IN_SHOSI>;
    close(IN_SHOSI);

    @koumoku_content = map { chomp; [ split(/,/) ] } @shosi;   		 

# 目次テンプレートのコピーと名前変更
    $source_mokuji_tempfile = 'C:/Users/tomoki.kawakubo/050/03_setup/toolbox/template_mokuji_header.txt';
    $destination_mokuji_file = 'C:/Users/tomoki.kawakubo/050/03_setup/arrange_toc.xhtml';

    if (defined $koumoku_content[0][5] && $koumoku_content[0][5] eq "yes") {    # 書誌、目次有ならarrange_toc.xhtmlを生成
        copy($source_mokuji_tempfile, $destination_mokuji_file) or die "ファイルのコピーに失敗しました: $!";
        print "File copied and renamed to $destination_mokuji_file\n";
    }

# 注釈テンプレートのコピーと名前変更
    $source_annotation_tempfile = 'C:/Users/tomoki.kawakubo/050/03_setup/toolbox/template_annotation_header.txt';
    $destination_annotation_file = 'C:/Users/tomoki.kawakubo/050/03_setup/arrange_annotation.xhtml';

    if (defined $koumoku_content[0][6] && $koumoku_content[0][6] eq "yes") {
        copy($source_annotation_tempfile, $destination_annotation_file) or die "ファイルのコピーに失敗しました: $!";
        print "File copied and renamed to $destination_annotation_file\n";
    }

# 奥付テンプレートのコピーと名前変更
    my $source_okuduke_file = 'C:/Users/tomoki.kawakubo/050/03_setup/toolbox/template_okuduke_header.txt';
    my $destination_okuduke_file = 'C:/Users/tomoki.kawakubo/050/03_setup/arrange_colophon.xhtml';

    copy($source_okuduke_file, $destination_okuduke_file) or die "ファイルのコピーに失敗しました: $!";  


# 本体の処理 ===========================================================================

while (<$in_source>) {
    my $content = $_;  # 読み込んだ行を変数に格納

    # 置換リスト =======================================
#   未達
#   
#   
    $content =~ s|<html xmlns="http://www.w3.org/1999/xhtml" lang="ja-JP">|<html\n xmlns="http://www.w3.org/1999/xhtml"\n xmlns:epub="http://www.idpf.org/2007/ops"\n xml:lang="ja"\n class="vrtl"\n>\n<!--目次カット開始位置（div直後に挿入） -------------------->\n<!--目次カット終了位置（div閉じ直後に挿入） --------------------------------------->|;

    $content =~ s|<title>.*?<\/title>|<title>arrange_targetのhtml<\/title>\n\t<link href="..\/03_setup\/toolbox\/arrange_style\/style-standard.css" rel="stylesheet" type="text\/css" />|;

    $content =~ s|(<link href="source-web-resources)|<link href="..\/03_setup\/source-web-resources|g;

    $content =~ s/ id="_idContainer[^"]*"//g;
    $content =~ s/基本テキストフレーム //g;                                                     

    $content =~ s/<div class="基本グラフィックフレーム">\s*<\/div>//g;

    $content =~ s/<p class="本文.*?>/<p>/g;                                                     # <p 本文を <>化
    $content =~ s/<p class="本文">/<p>/g;                                                       # <p 本文を <>化
    $content =~ s/<img class="_idGenObjectAttribute-\d+" src="(.*?)\/(.*?)" alt="" \/>/<p><img src="..\/$2" alt="" class="fit" \/><\/p>/g;
                                                                            # イメージタグ正規化1
    $content =~ s/<figure.*?>//g;            # <figure> タグ行を削除
    $content =~ s/^\s*<\/figure>\s*$//g;                                # </figure> タグ行を削除


    $content =~ s|(<div class="_idGen[^>]*>)|$1 <!--改ページ位置 --------------------------------------------->|g;                      # 追加：改ページコメント挿入

    $content =~ s/<p class="h1_章タイトル">(.*?)<\/p>/<h1 class="h1見出し">$1<\/h1>/g;
    $content =~ s/<p class="h2_節タイトル">(.*?)<\/p>/<h2 class="h2見出し">$1<\/h2>/g;
    $content =~ s/<p class="h3_項タイトル">(.*?)<\/p>/<h3 class="h3見出し">$1<\/h3>/g;
    $content =~ s/<p class="h4_目タイトル">(.*?)<\/p>/<h4 class="h4見出し">$1<\/h4>/g;

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

    $content =~ s/<a href="source\.html#_idTextAnchor(...)">/<a href="target.xhtml#toc-$1">/g;   #リンクタグ正規化
    $content =~ s/<a id="_idTextAnchor(...)"><\/a>/<a id="toc-$1"><\/a>/g;                      #リンクタグ正規化

    # 約物 --------------------------------------------------------------------------------------------

    $content =~ s/([ぁ-んァ-ヶ一-龥])!!!([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">!!!<\/span>$2/g;          # 
    $content =~ s/([ぁ-んァ-ヶ一-龥])!!([ぁ-んァ-ヶ一-龥<\　+])/$1<span class="tcy">!!<\/span>$2/g;           # 

    $content =~ s/([ぁ-んァ-ヶ一-龥])\?\?\?([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">\?\?\?<\/span>$2/g;    #
    $content =~ s/([ぁ-んァ-ヶ一-龥])\?\?([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">\?\?<\/span>$2/g;        #
    
    $content =~ s/([ぁ-んァ-ヶ一-龥])!\?([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">!\?<\/span>$2/g;          # 
    $content =~ s/([ぁ-んァ-ヶ一-龥])\?!([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">\?!<\/span>$2/g;          # 

    $content =~ s/([ぁ-んァ-ヶ一-龥])!!\?([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">!!\?<\/span>$2/g;        #
    $content =~ s/([ぁ-んァ-ヶ一-龥])!\?\?([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">!\?\?<\/span>$2/g;      #
    $content =~ s/([ぁ-んァ-ヶ一-龥])\?!!([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">\?!!<\/span>$2/g;        #
    $content =~ s/([ぁ-んァ-ヶ一-龥])\?\?!([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">\?\?!<\/span>$2/g;      #

    $content =~ s/([ぁ-んァ-ヶ一-龥])!([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">!<\/span>$2/g;              #
    $content =~ s/([ぁ-んァ-ヶ一-龥])\?([ぁ-んァ-ヶ一-龥<　+])/$1<span class="tcy">\?<\/span>$2/g;            #

    $content =~ s/<span class="tcy">\?<\/span>/？/g;                                                #
    $content =~ s/<span class="tcy">!<\/span>/！/g;                                                 #

    $content =~ s/“(.*?)”/〝$1〟/g;                                                 #

    # ログ付き変換で内容検証要の変換や検索レポート ----------------------------------------------------

# ok    ・$content =~ s/([ぁ-んァ-ヶ一-龥])([0-9]{2})([ぁ-んァ-ヶ一-龥])/$1<span class="tcy">$2<\/span>$3/g;
# ok    ・本文中の半角スペースを検索・置換（　(<[^>]+>[^<]*?) ([^<]*?<\/[^>]+>)　→　$1$2）
#   ・文字化け要因
#   ・漢字
#   ・約物（“” → 〝〟　）
#   ・「>70<」のように、2桁あるいは3桁の数字にtcyがかかっているかのアラート出し（下のパターンで引っかからない場合想定）
#   ・2桁英字にtcyがかかっているかのアラート出し（5字の英字名が半角で全角要の例も見た）
#   ・いろいろ。チェックログ出し
#       ・「No.1」　→　 <span class="tcy">No</span>・１
#       ・本文中の半角スペースを、どう扱うか。
#       ・約物！？等の後ろに全角スペースの有無。
#       ・「＝」イコールの全角半角
#       ・Ｎｏ．１
#       ・ウムラウト等「é」
#       ・全角・半角の「’」「'」「.」「．」「，」「,」の使い分け
#       ・「Ｖｏｌ.１」、「<span class="tcy">vol</span>．１」など組み合わせ

    $content =~ s/――/──/g;                                                 # U+2500へ


# 二桁英数字に tcy を付加し、変換があった場合はログへ出力するバージョン
my $content_before_tcy = $content;  # 変換前のコンテンツを保存

if ($content =~ s/([ぁ-んァ-ヶ一-龥])([0-9]{2})([ぁ-んァ-ヶ一-龥])/$1<span class="tcy">$2<\/span>$3/g) {
    unless ($log_message_tcy =~ /【二桁英数字に tcy を付加】====================================================/) {
        $log_message_tcy .= "【二桁英数字に tcy を付加】====================================================\n";
    }
    
    # 変換された部分を出力
    my @lines_before = split /\n/, $content_before_tcy;
    my @lines_after = split /\n/, $content;
    for my $i (0..$#lines_before) {
        if ($lines_before[$i] ne $lines_after[$i]) {
            $log_message_tcy .= "Before: \n$lines_before[$i]\n";
            $log_message_tcy .= "After: \n$lines_after[$i]\n\n";
        }
    }
}


# 一桁英数字を全角英数字に変換し、変換があった場合はログへ出力するバージョン
my $content_before_fullwidth = $content;  # 変換前のコンテンツを保存

if ($content =~ s/([ぁ-んァ-ヶ一-龥])([0-9A-Za-z])([ぁ-んァ-ヶ一-龥])/$1 . chr(ord($2) + 0xFEE0) . $3/ge) {
    unless ($log_message_fullwidth =~ /【一桁英数字を全角英数字に変換】====================================================/) {
        $log_message_fullwidth .= "【一桁英数字を全角英数字に変換】====================================================\n";
    }
    
    # 変換された部分を出力
    my @lines_before = split /\n/, $content_before_fullwidth;
    my @lines_after = split /\n/, $content;
    for my $i (0..$#lines_before) {
        if ($lines_before[$i] ne $lines_after[$i]) {
            $log_message_fullwidth .= "Before: \n$lines_before[$i]\n";
            $log_message_fullwidth .= "After: \n$lines_after[$i]\n\n";
        }
    }
}

# 本文中の半角スペースを検索・置換し、変換があった場合はログへ出力するバージョン
my $content_before_space = $content;  # 変換前のコンテンツを保存

# if ($content =~ s/(<[^>]+>[^<]*?) ([^<]*?<\/[^>]+>)/$1$2/g) {   # 本文中の半角スペースを検索・置換　oldバージョン
if ($content =~ s/(<[^>]+>[^<]?) ([^<]*?<\/[^>]+>)/$1$2/g) {
    unless ($log_message_space =~ /【本文中の半角スペースを検索・置換】====================================================/) {
        $log_message_space .= "【本文中の半角スペースを検索・置換】====================================================\n";
    }

    # 変換された部分を出力
    my @lines_before = split /\n/, $content_before_space;
    my @lines_after = split /\n/, $content;
    for my $i (0..$#lines_before) {
        if ($lines_before[$i] ne $lines_after[$i]) {
            $log_message_space .= "Before: \n$lines_before[$i]\n";
            $log_message_space .= "After: \n$lines_after[$i]\n\n";
        }
    }
}

# 最後の方で置換するもの ------------------------------------------------------------------------


    # 置換リスト 終了 ===============================================================================

    # 変換後の内容を書き出す（2つのファイルに）
    print $out_target1 $content;
    print $out_target2 $content;
}

# ログメッセージをファイルに書き出す
if ($log_message_tcy || $log_message_space || $log_message_fullwidth) {
    open my $out_log, '>>:encoding(UTF-8)', $output_report or die "Cannot open $output_report: $!";
    print $out_log $log_message_tcy if $log_message_tcy;
    print $out_log $log_message_space if $log_message_space;
    print $out_log $log_message_fullwidth if $log_message_fullwidth;
    close $out_log;
}

close $in_source;
close $out_target1;
close $out_target2;

print "Processing complete. Output saved to:\n";
print "  - 03_setup/onmark_target.xhtml\n";
print "  - 03_setup/getset_target.xhtml\n";
print "  - 04_arrange/report.txt\n";




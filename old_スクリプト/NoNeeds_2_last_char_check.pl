use strict;
use warnings;
use Encode;
use utf8;

my $log_message = "";  # ログメッセージを集約する変数
my $log_message_tcy = "";  # 二桁英数字に tcy を付加する処理のログメッセージ
my $log_message_space = "";  # 本文中の半角スペースを検索・置換する処理のログメッセージ
my $log_message_fullwidth = "";  # 一桁英数字を全角英数字に変換する処理のログメッセージ

# 素材テキストを読み込んで変換 -------------------------------------------------------------------------
my $input_file   = "02_getset/getset_target.xhtml";              # source
my $output_file2 = "02_getset/cleaned_target.xhtml";      # 出力ファイル2。02_getsetに手動で移動要（自動変換の上書き防止用）
my $output_report = "02_getset/report_char.txt";             # 出力ログ

# report.txt を初期化
open my $out_log, '>:encoding(UTF-8)', $output_report or die "Cannot open $output_report: $!";
close $out_log;

open my $in_source, '<:encoding(UTF-8)', $input_file or die "Cannot open $input_file: $!";
open my $out_target2, '>:encoding(UTF-8)', $output_file2 or die "Cannot open $output_file2: $!";

while (<$in_source>) {
    my $content = $_;  # 読み込んだ行を変数に格納

    # 一桁英数字を全角英数字に変換し、変換があった場合はログへ出力するバージョン
    my $content_before = $content;  # 変換前のコンテンツを保存

    if ($content =~ s/<span class="tcy">([0-9])<\/span>/chr(ord($1) + 0xFEE0)/ge) {
        unless ($log_message_fullwidth =~ /【一桁英数字を全角英数字に変換】====================================================/) {
            $log_message_fullwidth .= "【一桁英数字を全角英数字に変換】====================================================\n";
        }
        
        # 変換された部分を出力
        my @lines_before = split /\n/, $content_before;
        my @lines_after = split /\n/, $content;
        for my $i (0..$#lines_before) {
            if ($lines_before[$i] ne $lines_after[$i]) {
                $log_message_fullwidth .= "Before: \n$lines_before[$i]\n";
                $log_message_fullwidth .= "After: \n$lines_after[$i]\n\n";
            }
        }
    }

    # 最後の方で置換するもの ------------------------------------------------------------------------
    $content_before = $content;  # 変換前のコンテンツを保存

    if ($content =~ s#<span class="tcy">([0-9])</span>#chr(ord($1) + 0xFEE0)#ge) {
        unless ($log_message_fullwidth =~ /【一桁英数字を全角英数字に変換】====================================================/) {
            $log_message_fullwidth .= "【一桁英数字を全角英数字に変換】====================================================\n";
        }
        
        # 変換された部分を出力
        my @lines_before = split /\n/, $content_before;
        my @lines_after = split /\n/, $content;
        for my $i (0..$#lines_before) {
            if ($lines_before[$i] ne $lines_after[$i]) {
                $log_message_fullwidth .= "Before: \n$lines_before[$i]\n";
                $log_message_fullwidth .= "After: \n$lines_after[$i]\n\n";
            }
        }
    }

    # 置換リスト 終了 ===============================================================================

    # 変換後の内容を書き出す
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
close $out_target2;

print "Processing complete. Output saved to:\n";
print "  - 02_getset/cleaned_target.xhtml\n";
print "  - 02_getset/report_char.txt\n";

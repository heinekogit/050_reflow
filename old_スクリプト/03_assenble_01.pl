#   ［04_arrange］フォルダで、
#   arrange_～_.htmlの_手動調整が終わったら起動。
#   ・作業目安用のコメント行とか、プレビュー用のヘッダーとかを取り去り、
#   ・ファイル名を変更して［03_materials］フォルダに複製配置
#   する。

#   追加する機能
#       <!--------> （目視用）を削除する
#       不要なテンプレートヘッダーを消す
#       <div と </div> が同数かをカウント判定、レポート出力もしくはアラートで中止
#       ファイル名を変更して配置する

use strict;
use warnings;
use Encode;
use utf8;
use File::Copy;
# -----------------------------------------------------

# 入力ファイルと出力ファイルのパスを定義 --------------------------------------------------
my $input_target = 'C:/Users/tomoki.kawakubo/050/04_arrange/arrange_target.xhtml';
my $input_toc = 'C:/Users/tomoki.kawakubo/050/04_arrange/arrange_toc.xhtml';
my $input_navigation = 'C:/Users/tomoki.kawakubo/050/04_arrange/arrange_navigation.xhtml';

my $output_target = 'C:/Users/tomoki.kawakubo/050/05_assemble/target.xhtml';
my $output_toc = 'C:/Users/tomoki.kawakubo/050/05_assemble/go_toc.xhtml';
my $output_navigation = 'C:/Users/tomoki.kawakubo/050/05_assemble/go_navigation.xhtml';

# 入力ファイルを開く
open my $in_target, '<:encoding(UTF-8)', $input_target or die "Cannot open $input_target: $!";

# 出力ファイルを開く
open my $out_target, '>:encoding(UTF-8)', $output_target or die "Cannot open $output_target: $!";

# ファイルの内容を読み込み、コメントを削除して出力ファイルに書き込む
while (<$in_target>) {
    s/ <!--改ページ位置 --------------------------------------------->//g;  # コメントを削除
    s/<! -- 目次抜粋位置 -->>//g;                                           # コメントを削除（未定、外すかも）

    print $out_target $_;
}

# ファイルを閉じる
close $in_target;
close $out_target;

print "Processing complete. Output saved to:\n";
print "  - $output_target\n";























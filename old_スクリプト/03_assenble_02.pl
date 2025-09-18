use strict;
use warnings;
use Encode;
use utf8;
use File::Copy;

# 入力ファイルと出力ファイルのパスを定義 --------------------------------------------------
my $input_target = 'C:/Users/tomoki.kawakubo/050/04_arrange/arrange_target.xhtml';
my $input_toc = 'C:/Users/tomoki.kawakubo/050/04_arrange/arrange_toc.xhtml';
my $input_navigation = 'C:/Users/tomoki.kawakubo/050/04_arrange/arrange_navigation.xhtml';

my $output_target = 'C:/Users/tomoki.kawakubo/050/05_assemble/target.xhtml';
my $output_toc = 'C:/Users/tomoki.kawakubo/050/05_assemble/go_toc.xhtml';
my $output_navigation = 'C:/Users/tomoki.kawakubo/050/05_assemble/go_navigation.xhtml';

# 入力ファイルを開く
open my $in_target, '<:encoding(UTF-8)', $input_target or die "Cannot open $input_target: $!";
open my $in_toc, '<:encoding(UTF-8)', $input_toc or die "Cannot open $input_toc: $!";
open my $in_navigation, '<:encoding(UTF-8)', $input_navigation or die "Cannot open $input_navigation: $!";

# 出力ファイルを開く
open my $out_target, '>:encoding(UTF-8)', $output_target or die "Cannot open $output_target: $!";
open my $out_toc, '>:encoding(UTF-8)', $output_toc or die "Cannot open $output_toc: $!";
open my $out_navigation, '>:encoding(UTF-8)', $output_navigation or die "Cannot open $output_navigation: $!";

# ファイルの内容を読み込み、コメントを削除して出力ファイルに書き込む
while (<$in_target>) {
    s/ <!--改ページ位置 --------------------------------------------->//g;  # コメントを削除
    s/<! -- 目次抜粋位置 -->>//g;                                           # コメントを削除（未定、外すかも）

    print $out_target $_;
}

while (<$in_toc>) {
    print $out_toc $_;
}

while (<$in_navigation>) {
    print $out_navigation $_;
}

# ファイルを閉じる
close $in_target;
close $out_target;
close $in_toc;
close $out_toc;
close $in_navigation;
close $out_navigation;

print "Processing complete. Output saved to:\n";
print "  - $output_target\n";
print "  - $output_toc\n";
print "  - $output_navigation\n";
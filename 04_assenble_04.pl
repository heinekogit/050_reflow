use strict;
use warnings;
use Encode;
use utf8;
use File::Copy;

my $skip;

# 入力ファイルと出力ファイルのパスを定義 --------------------------------------------------
my $input_target = 'C:/Users/tomoki.kawakubo/050/04_arrange/adjust_link_target.xhtml';
my $input_toc = 'C:/Users/tomoki.kawakubo/050/04_arrange/arrange_toc.xhtml';
my $input_navigation = 'C:/Users/tomoki.kawakubo/050/04_arrange/arrange_navigation.xhtml';
my $input_annotation = 'C:/Users/tomoki.kawakubo/050/04_arrange/arrange_annotation.xhtml';
my $input_colophon = 'C:/Users/tomoki.kawakubo/050/04_arrange/arrange_colophon.xhtml';

my $output_target = 'C:/Users/tomoki.kawakubo/050/05_assemble/target.xhtml';
my $output_toc = 'C:/Users/tomoki.kawakubo/050/05_assemble/go_toc.xhtml';
my $output_navigation = 'C:/Users/tomoki.kawakubo/050/05_assemble/go_navigation.xhtml';
my $output_annotation = 'C:/Users/tomoki.kawakubo/050/05_assemble/go_annotation.xhtml';
my $output_colophon = 'C:/Users/tomoki.kawakubo/050/05_assemble/go_colophon.xhtml';


# サブルーチン tocの処理 -------------------------------------------------------------------
sub process_toc_file {
    my ($input_file, $output_file) = @_;

    # 入力ファイルを開く
    open my $in, '<:encoding(UTF-8)', $input_file or die "Cannot open $input_file: $!";
    
    # 出力ファイルを開く
    open my $out, '>:encoding(UTF-8)', $output_file or die "Cannot open $output_file: $!";

    my $skip = 1;  # スキップフラグを立てる

    # ファイルの内容を読み込み、処理して出力ファイルに書き込む
    while (<$in>) {
        # 先頭行から指定の行までをスキップ
        if ($skip) {
            if (/<!--テンプレートここまで.*?>/) {
                $skip = 0;  # スキップフラグを下ろす
                next;  # この行もスキップ
            }
            next;
        }
        s/ <!--改ページ位置 --------------------------------------------->//g;  # コメントを削除
        s/<div class="_idGenStoryDirection-."><!--目次.*?>//g;  # コメントを削除
        s/<!--目次.*?>//g;  # コメントを削除
        s/<\/div><!--目次.*?>//g;  # コメントを削除

        s/^\s*\n//mg;                                           # 空行を削除           
        s/^\t</</g;                                             # 行頭のタブ削除            

        print $out $_;
    }

    # ファイルを閉じる
    close $in;
    close $out;

    print "Processing complete. Output saved to $output_file\n";
}
# サブルーチン 終了 -------------------------------------------------------------------


# 入力ファイルを開く
open my $in_target, '<:encoding(UTF-8)', $input_target or die "Cannot open $input_target: $!";
open my $in_toc, '<:encoding(UTF-8)', $input_toc or die "Cannot open $input_toc: $!";
open my $in_navigation, '<:encoding(UTF-8)', $input_navigation or die "Cannot open $input_navigation: $!";
open my $in_colophon, '<:encoding(UTF-8)', $input_colophon or die "Cannot open $input_colophon: $!";

# 出力ファイルを開く
open my $out_target, '>:encoding(UTF-8)', $output_target or die "Cannot open $output_target: $!";
open my $out_toc, '>:encoding(UTF-8)', $output_toc or die "Cannot open $output_toc: $!";
open my $out_navigation, '>:encoding(UTF-8)', $output_navigation or die "Cannot open $output_navigation: $!";
open my $out_colophon, '>:encoding(UTF-8)', $output_colophon or die "Cannot open $output_colophon: $!";
open my $out_annotation, '>:encoding(UTF-8)', $output_annotation or die "Cannot open $output_annotation: $!";

# 単体ページの脚注が存在すると知覚した場合、go_ファイルを生成する（それだけ（書誌読み取りではない））
if (!open my $in_annotation, '<:encoding(UTF-8)', $input_annotation) {
    warn "Warning: Cannot open $input_annotation: $!";
} else {
    while (<$in_annotation>) {
        s/adjust_link_target.xhtml/target.xhtml/g;                                           # 
        print $out_annotation $_;
    }
    close $in_annotation;
}


# ファイルの内容を読み込み、コメントを削除して出力ファイルに書き込む
while (<$in_target>) {
    s/ <!--改ページ位置 --------------------------------------------->//g;  # コメントを削除
    s/<! -- 目次抜粋位置 -->//g;                                           # コメントを削除（未定、外すかも）
    s/<\/body>//g;                                           # 
    s/<\/html>//g;                                           # 

    s/^\s*\n//mg;                                           # 空行を削除           
    s/^\t</</g;                                             # 行頭のタブ削除            
    s/^\s+</</g;                                             # 行頭のタブ削除

    s/adjust_link_target.xhtml/target.xhtml/g;        # リンク先名を周辺合わせ

    print $out_target $_;
}


while (<$in_navigation>) {                   # navigationファイルの処理
    print $out_navigation $_;
}

while (<$in_colophon>) {                    # colophonファイルの処理
    print $out_colophon $_;
}


# ファイルを閉じる
close $in_target;
close $out_target;
close $in_navigation;
close $out_navigation;

# サブルーチンを呼び出して処理を実行
process_toc_file($input_toc, $output_toc);

print "Processing complete. Output saved to:\n";
print "  - $output_target\n";
print "  - $output_toc\n";
print "  - $output_navigation\n";
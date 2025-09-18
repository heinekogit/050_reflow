#!/usr/local/bin/perl

use strict;
use warnings;
use utf8;
binmode STDIN, 'encoding(cp932)';
binmode STDOUT, 'encoding(cp932)';
binmode STDERR, 'encoding(cp932)';
use Encode;
use File::Path 'mkpath';
use File::Copy;
use File::Copy::Recursive qw(rcopy);
use Image::Size 'imgsize';

use HTML::TreeBuilder;
use Encode qw(decode encode);

#	================================================================================================================================
    my @trgt_html;
	my @moto_html;
	my @xhtml_enu;
	my $html_content;
	my $xhtml_content;
#    my $template_fh;
#    my input_fh;
#    my output_fh;
	
#	================================================================================================================================
#	パス：C:\Users\tomoki.kawakubo\050
#	================================================================================================================================
#	素材の取り込み 

#    open(IN_TRGT, "<:encoding(UTF-8)", "/03_materials/target.html") or die "cant open target_html\n";
#    @trgt_html = <IN_TRGT>;
#    close(IN_TRGT);

 
   		 &divide_xhtml;   				#prcs04		p-001xhtmlのセッティング



#    p-001.xhtmlの読み込み部分    ===========================================================================

    sub divide_xhtml{
    
#	<h1>でhtmlを切り出し    ------------------------------------

open(my $input_fh, '<:encoding(UTF-8)', "03_materials/target.html") or die "Cannot open file input_file: $!";
# テンプレートファイルを読み込む
open(my $template_fh, '<:encoding(UTF-8)', "01_templates/p-00n.xhtml") or die "Cannot open file template_file: $!";
# 出力ファイルを書き込みモードで開く（存在しなければ新規作成）
open(my $output_fh, '>:encoding(UTF-8)', "04_output/output.xhtml") or die "Cannot create file output_file: $!";


# コピーを開始するフラグとコピー対象の行を格納する変数
my $copying = 0;
my @lines_to_copy;

while (my $line = <$input_fh>) {
    chomp $line;

    if ($line =~ m/<h1>|<h2>/) {
        if ($copying) {
            # コピー中に次の <h1> または <h2> タグが見つかったらコピーを終了する
            last;
        } else {
            # コピーを開始する
            $copying = 1;
        }
    }

    if ($copying) {
        # コピー中なら行を配列に追加する

#    print $line;

        push @lines_to_copy, $line;
    }
}


# コピー対象の行を1つの文字列に結合
my $content_to_insert = join("\n", @lines_to_copy);

#    print $content_to_insert;       #テスト出力

# プレースホルダーをエスケープ
my $placeholder = quotemeta('▼本文挿入位置▼');

# テンプレートファイルの内容を読み込み、プレースホルダーを置換して出力ファイルに書き込む
while (my $temp_line = <$template_fh>) {
    chomp $temp_line;
    $temp_line =~ s/$placeholder/$content_to_insert/;
    print $output_fh "$temp_line\n";
}

# ファイルを閉じる
close($input_fh);
close($template_fh);
close($output_fh);

print "HTML operation end\n";

}



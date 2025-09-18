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

#	================================================================================================================================
    my @trgt_html;
	my @moto_html;
	my @xhtml_enu;
	my $html_content;
	my $xhtml_content;
	my $output_file;
	
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
    
#	htmlとxhtmlテンプレを開く	------------------------------------

   	 open(IN_HTML, "<:encoding(UTF-8)", "03_materials/target.html") or die "cant open moto_html\n";
   	 @moto_html = <IN_HTML>;
   	 close(IN_HTML);

   	 open(IN_XHTML, "<:encoding(UTF-8)", "01_templates/p-00n.xhtml") or die "cant open 0n_xhtml\n";
   	 @xhtml_enu = <IN_XHTML>;
   	 close(IN_XHTML);


#	<h1>でhtmlを切り出し    ------------------------------------
my $input_file = '03_materials/target.html';
my $output_file = '04_output/output.xhtml';

# 入力ファイルを読み込む
open(my $input_fh, '<', $input_file) or die "Cannot open file $input_file: $!";
# 出力ファイルを書き込みモードで開く（存在しなければ新規作成）
open(my $output_fh, '>', $output_file) or die "Cannot create file $output_file: $!";

# コピーを開始するフラグとコピー対象の行を格納する変数
my $copying = 0;
my @lines_to_copy;

while (my $line = <$input_fh>) {
    chomp $line;

    if ($line =~ m/<h1>/) {
        # 第１章の開始タグが見つかったらコピーを開始する
        $copying = 1;
    }

    if ($copying) {
        # コピー中なら行を配列に追加する
        push @lines_to_copy, $line;
    }

#   if ($line =~ m/<\/h1>/) {
#		h1タグの終わりが見つかったらコピーを終了する
#       $copying = 0;
#   }

    if ($line =~ m/<h2>/) {
        # h2タグが見つかったら直前の行までをコピー対象から削除する
        pop @lines_to_copy;
        last; # h2タグが見つかったらループを終了する
    }
}

# 出力ファイルにコピー対象の行を書き込む
foreach my $line (@lines_to_copy) {
#    print $output_fh "$line\n";
    s/▼本文挿入位置▼/join "", @lines_to_copy/eg;   		 #環境変数から用意

}

# ファイルを閉じる
close($input_fh);
close($output_fh);

print "HTMLファイルの処理が完了しました。\n";



	}



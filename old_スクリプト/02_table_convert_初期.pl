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
use File::Basename;
use DateTime;
use DateTime::Format::ISO8601;


#	グローバル変数　========================================================================================================
my @;

#	============================================================================================================
#	パス：C:\Users\tomoki.kawakubo\050
#	============================================================================================================
#	素材の取り込み 

    open(IN_TRGT, "<:encoding(UTF-8)", "03_materials/target.html") or die "cant open target_html\n";
    @trgt_html = <IN_TRGT>;
    close(IN_TRGT);

#	==============================================================================================================

# xhtmlの加工    ===========================================================================

sub make_xhtml {
    # 素材htmlを読み込み
    open(my $input_fh, '<:encoding(UTF-8)', "03_materials/target.html") or die "Cannot open file input_file: $!";
    # テンプレートファイルを読み込む

    # 出力ファイルの連番用カウンタ
    my $file_counter = 1;

    # コピーを開始するフラグとコピー対象の行を格納する変数
    my $copying = 0;
    my @lines_to_copy;
    my $current_template = '';

    while (my $line = <$input_fh>) {
        chomp $line;

        if ($line =~ m/<div class="_idGen[^"]*">/) {
            if ($copying) {

                # 配列の末尾から空行と </div> を削除
               while (@lines_to_copy && $lines_to_copy[-1] =~ /^\s*$/) {      #古い。空き行だけ削除のパターン
                    pop @lines_to_copy;
                }

    while (my $temp_line = <$template_fh>) {
        chomp $temp_line;
        $temp_line =~ s/$placeholder/$content_to_insert/;
        
        # IDが見つかった場合、テンプレートの●toc_id●部分を置換
        if ($found_id) {
            $temp_line =~ s/●toc_id●/id="$found_id"/;
        } else {
            $temp_line =~ s/●toc_id●//; 	# IDが見つからない場合は空文字に置換
        }

		$temp_line =~ s/●タイトル名●/$koumoku_content[0]/;		# 標準的な文字置き換えがここで可
		$temp_line =~ s/●方向●/$koumoku_content[5]/;			

        $temp_line =~ s|<a id="toc-\d+">(.*?)</a>|$1|g;         # 本文中のリンク先の記述タグを消す
        $temp_line =~ s/<div class="_idGen[^"]*">//;            # <div class="_idGenObject[^"]*">を消す

        print $output_fh "$temp_line\n";
    }

    close($output_fh);
}


foreach my $line (@standard_opf) {
	$line =~ s/●タイトル名●/$koumoku_content[0]/g;
    $line =~ s/●話巻順番●/$koumoku_content[1]/g;   			 #2L以上は使わない
    $line =~ s/●タイトル名カタカナ●/$koumoku_content[9]/g;   	 #2L以上は使わない
    $line =~ s/●話数3桁●/$koumoku_content[2]/g;   			 	#2L以上は使わない
    $line =~ s/●出版社名●/$koumoku_content[11]/g;   			 #2L以上は使わない
    $line =~ s/●出版社名カタカナ●/$koumoku_content[13]/g;   	 #2L以上は使わない
    $line =~ s/●読み方向●/$koumoku_content[5]/g;

	$line =~ s/▼著者情報テキスト挿入位置▼/join "", @go_opf_chosha/eg;   		#	サブルーチン chosha_divide   

    $line =~ s/▼xhtmlファイルタグ印字位置▼/$item_tags_str/eg;
    $line =~ s/▼spineタグ印字位置▼/$spine_tags_str/eg;
    $line =~ s/▼画像ファイルタグ印字位置▼/join "\n", @$gazou_tags_ref/eg;










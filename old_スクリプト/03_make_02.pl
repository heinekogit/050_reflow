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

#	グローバル変数　================================================================================================================================
my @trgt_html;
my @shosi;
my @koumoku_content;
my @log;
my @mate_folders;
my @standard_opf;
my @img_list;
my @go_opf_chosha;
my @opf_content;
my @xhtml_one;
my @chosha_mei;
my @chosha_katakana;
my @chosha_temp;
my @mokuji_list;
my @navig_list;
my @go_mokuji;
my @gazou_tags;

my $count;
my $image_count;
my $page_count;
my $filenames_ref;
my $output_filenames_ref;

my $line;
my $opf_placeholder;
my $items_to_insert;
my $spine_placeholder;
my $spines_to_insert;

my $filename;

my @output_filenames;
my @new_opf_content;
my $opf_out_fh;



#	================================================================================================================================
#	パス：C:\Users\tomoki.kawakubo\050
#	================================================================================================================================
#	素材の取り込み 

    open(IN_TRGT, "<:encoding(UTF-8)", "03_materials/target.html") or die "cant open target_html\n";
    @trgt_html = <IN_TRGT>;
    close(IN_TRGT);

#	================================================================================================================================
#	目次に使う目次素材テキスト & navigation-documents.xhtml & toc.ncxの取り込み    

#    open(IN_MOKUJI_LIST, "<:encoding(UTF-8)", "03_materials/mokuji.csv") or die "cant open mokuji_csv\n";
#    @mokuji_list = <IN_MOKUJI_LIST>;
#    close(IN_MOKUJI_LIST);

#    open(IN_NAVIG_LIST, "<:encoding(UTF-8)", "01_templates/navigation-documents.xhtml") or die "cant open navigation_documents_xhtml\n";
#    @navig_list = <IN_NAVIG_LIST>;
#    close(IN_NAVIG_LIST);


#    shosi.csvの読み込み部分   	 ===========================================================================

    open(IN_SHOSI, "<:encoding(UTF-8)", "03_materials/shosi.csv") or die "cant open shosi\n";
    @shosi = <IN_SHOSI>;
    close(IN_SHOSI);

    foreach(@shosi)   	 
   	 {
   		@koumoku_content = split(/,/);
   		 
   		&pre_check;						#prcs00		書誌とデータのチェック
   		 
   		&chosha_divide;					#prcs01		著者複数の場合

   		&output_folders;   				#prcs02		フォルダ類＆画像ファイルを出力

#		&gazou_glob;   					#prcs03		画像情報の取得	下で使うのがイキ？
   		 
   		&make_xhtml;   					#prcs04		xhtmlのセッティング・出力
		 
   		&make_opf;   						#prcs06		opfファイルのセッティング

#		&make_mokuji;
   		 
   		&output_txts;   					#prcs07		テキスト類の出力
   		 
   		&output_log;						#prcs08		ログファイルの出力

   	 }

   	 open(LOGS, ">:encoding(UTF-8)", "04_output/log.txt") or die "cant open log_file\n";   	 #002以降xhtmlファイルの出力
   	 print LOGS @log;
   	 close(LOGS);


# 事前チェック    ===========================================================================
    sub pre_check{
		
		opendir(DIRHANDLE, "03_materials");		# ディレクトリエントリの取得

		foreach(readdir(DIRHANDLE)){
			next if /^\.{1,2}$/;				# '.'や'..'をスキップ
#			print "$_\n";
		}

		my $data = $koumoku_content[4];
		
		for (@mate_folders) {

		if ($_ eq $data){
  				print "ok\n";
			} else {
  				print "$data nai\n";
			}
		}
	}


#    xhtmlの加工部分    ===========================================================================

    sub make_xhtml{
    
#	htmlを切り出し    ------------------------------------

open(my $input_fh, '<:encoding(UTF-8)', "03_materials/target.html") or die "Cannot open file input_file: $!";
# テンプレートファイルを読み込む
open(my $template_fh, '<:encoding(UTF-8)', "01_templates/p-text.xhtml") or die "Cannot open file template_file: $!";
# 出力ファイルを書き込みモードで開く（存在しなければ新規作成）

# 出力ファイル名を格納する配列
my @output_filenames;

# 出力ファイルの連番用カウンタ
my $file_counter = 1;

# コピーを開始するフラグとコピー対象の行を格納する変数
my $copying = 0;
my @lines_to_copy;
my $prev_line = '';

while (my $line = <$input_fh>) {
    chomp $line;

    if ($line =~ m/<div class="_idGen[^"]*">/) {
        if ($copying) {
            # コピー中に次のidGenタグが見つかったらコピーを終了してファイルに書き出す
            write_to_file($file_counter, \@lines_to_copy, $template_fh);
            $file_counter++;
            @lines_to_copy = (); 		# 配列をクリア
        }
        # コピーを開始する
        $copying = 1;
        push @lines_to_copy, $prev_line if $prev_line ne '';
    }

    if ($copying) {
        # コピー中なら行を配列に追加する
        push @lines_to_copy, $line;
    }

    $prev_line = $line; # 現在の行を次のループのために保存
}

# 最後のコピー対象もファイルに書き出す
write_to_file($file_counter, \@lines_to_copy, $template_fh) if $copying;


# 関数定義 ------------------------------------------------------------------------------------------------------
sub write_to_file {
    my ($counter, $lines_ref, $template_fh) = @_;
    my $filename = sprintf("04_output/$koumoku_content[4]/item/xhtml/p-%03d.xtml", $counter);
    open(my $output_fh, '>:encoding(UTF-8)', $filename) or die "Could not open output file '$filename': $!";    
    # ファイル名を配列に追加
    push @$filenames_ref, $filename;
    
    # コピー対象の行を1つの文字列に結合
    my $content_to_insert = join("\n", @$lines_ref);

    # プレースホルダーをエスケープ
    my $placeholder = quotemeta('▼本文挿入位置▼');

    # テンプレートファイルの内容を読み込み、プレースホルダーを置換して出力ファイルに書き込む
    seek($template_fh, 0, 0); # テンプレートファイルの読み込み位置をリセット
    while (my $temp_line = <$template_fh>) {
        chomp $temp_line;
        $temp_line =~ s/$placeholder/$content_to_insert/;
        print $output_fh "$temp_line\n";
    }

    close($output_fh);
}

		# ファイルハンドルを閉じる
		close($input_fh);
		close($template_fh);

	# 出力ファイル名を表示する（必要に応じて他の場所で使用可能）
#		print "Output files:\n";
#		print "$_\n" for @output_filenames;

		print "HTML operation end\n";
   }


#    standard.opfの読み込み部分    ===========================================================================

    sub make_opf {   				 

   	 open(IN_STD, "<:encoding(UTF-8)", "01_templates/standard.opf")  or die "cant open opf\n";
   	 @standard_opf = <IN_STD>;
   	 close(IN_STD);


   	foreach (@standard_opf)   	 
   		 {
   			&umekomi; 
   			s/▼著者情報テキスト挿入位置▼/join "", @go_opf_chosha/eg;   			 #	サブルーチン chosha_divide の生成テキストを挿入    

#			s/▼画像ファイルタグ印字位置▼/join "", $gazou_to_insert/eg;
 
   		 }

	fill_opf(\@standard_opf, \@output_filenames);
	&gazou_glob;

# OPFファイルに書き戻し
	open($opf_out_fh, '>:encoding(UTF-8)', "04_output/$koumoku_content[4]/item/standard.opf") or die "Could not open OPF output file: $!";
	print $opf_out_fh @standard_opf;
	close($opf_out_fh);

   	@go_opf_chosha = ();											#　opfに埋め込む著者情報の配列を初期化


    }


#  opf用のxhtml／spineタグ整形    ===========================================================================

sub fill_opf {

    my ($opf_content_ref, $output_filenames_ref) = @_;

    # <item>タグと<itemref>タグを生成
    my (@item_tags, @spine_tags);
    foreach my $filename (@$output_filenames_ref) {
        (my $id = $filename) =~ s/\.html$//;
        push @item_tags, qq(<item media-type="application/xhtml+xml" id="$id" href="xhtml/$id.xhtml"/>);
        push @spine_tags, qq(<itemref linear="yes" idref="$id"/>);
    }

    # <item>タグと<itemref>タグを1つの文字列に結合
    my $items_to_insert = join("\n", @item_tags);
    my $spines_to_insert = join("\n", @spine_tags);

    # 新しい配列を作成してプレースホルダーを置換
    my @new_opf_content;
    my $opf_placeholder = quotemeta('▼xhtmlファイルタグ印字位置▼');
    my $spine_placeholder = quotemeta('▼spineタグ印字位置▼');
    foreach my $line (@$opf_content_ref) {
        $line =~ s/$opf_placeholder/$items_to_insert/;
        $line =~ s/$spine_placeholder/$spines_to_insert/;
        push @new_opf_content, $line;
    }

    # 新しい内容を元の配列に戻す
    @$opf_content_ref = @new_opf_content;

}

# opf用の画像情報を作成    ===========================================================================

sub gazou_glob {
    my ($opf_content_ref) = @_;

    # jpg のファイル数を取得
    my @gazou_files = glob("03_materials/image/*.jpg"); # 出力フォルダ内画像

    # 画像ファイル名を基にした<item>タグを生成
    my @gazou_tags;
    foreach my $file (@gazou_files) {
        # ファイル名からパスを削除
        my ($filename) = $file =~ m{.*/(.*)\.jpg};
        push @gazou_tags, qq(<item media-type="image/jpeg" id="$filename" href="image/$filename.jpg"/>);
    }

    # 生成した<item>タグを1つの文字列に結合
    my $gazou_to_insert = join("\n", @gazou_tags);
    my $opf_placeholder = quotemeta('▼画像ファイルタグ印字位置▼');
    
    # OPFコンテンツ内のプレースホルダーを置き換え
    foreach my $line (@$opf_content_ref) {
        $line =~ s/$opf_placeholder/$gazou_to_insert/;
    }
}



#    出力    ===========================================================================

#    フォルダ・画像類の出力・コピー    ------------------------------------------

    sub output_folders{

#   	 $koumoku_name[4];   							 #話のファイル名

   	 mkdir("04_output/$koumoku_content[4]", 0755) or die "話のフォルダを作成できませんでした\n";
   	 mkdir("04_output/$koumoku_content[4]/item", 0755) or die "itemフォルダを作成できませんでした\n";
   	 mkdir("04_output/$koumoku_content[4]/META-INF", 0755) or die "META-INFのフォルダを作成できませんでした\n";
   	 mkdir("04_output/$koumoku_content[4]/item/xhtml", 0755) or die "xmlフォルダを作成できませんでした\n";
   	 mkdir("04_output/$koumoku_content[4]/item/style", 0755) or die "styleのフォルダを作成できませんでした\n";
   	 mkdir("04_output/$koumoku_content[4]/item/image", 0755) or die "話の画像のフォルダを作成できませんでした\n";

   	 #    テンプレよりテキスト類のコピー    -----------    

   	 rcopy("01_templates/META-INF/container.xml","04_output/$koumoku_content[4]/META-INF") or die "container.xmlをコピーできません\n";
   	 rcopy("01_templates/mimetype","04_output/$koumoku_content[4]") or die "mimetypeをコピーできません\n";
   	 rcopy("01_templates/style","04_output/$koumoku_content[4]/item/style") or die "styleをコピーできません\n";
#   	 rcopy("01_templates/item/navigation-documents.xhtml","04_output/$koumoku_content[4]/item") or die "styleをコピーできません\n";

  	 #    画像ファイルコピー    -----------    

   	 rcopy("03_materials/image","04_output/$koumoku_content[4]/item/image") or die "$koumoku_content[4]の画像をコピーできません\n";
					#注意：英数字以外のファイル名が引っかかるっぽい

  	 #    shosi.csvを生成xhtml階層にログ的コピー保存    -----------    

   	 rcopy("03_materials/shosi.csv","04_output") or die "shosiを履歴用にコピーできません\n";

    }


    #    テキスト類の出力    ----------------------------------------------------------------------------
    
   	 sub output_txts{

   	 open(OUT_STD, ">:encoding(UTF-8)", "04_output/$koumoku_content[4]/item/standard.opf") or die "cant make opf\n";   		 #opfファイルの出力
   	 print OUT_STD @standard_opf;
   	 close(OUT_STD);

   	 open(OUT_01, ">:encoding(UTF-8)", "04_output/$koumoku_content[4]/item/xhtml/p-001.xhtml") or die "cant make xhtml\n";   	 #001のxhtmlファイルの出力
   	 print OUT_01 @xhtml_one;
   	 close(OUT_01);

    }


# サブルーチン　文字変換    ===========================================================================

sub umekomi {
    s/●タイトル名●/$koumoku_content[0]/g;   			 #2L以上は使わない
    s/●話巻順番●/$koumoku_content[1]/g;   			 #2L以上は使わない
    s/●タイトル名カタカナ●/$koumoku_content[7]/g;   	 #2L以上は使わない
    s/●話数3桁●/$koumoku_content[2]/g;   			 	#2L以上は使わない

    s/●出版社名●/$koumoku_content[9]/g;   			 #2L以上は使わない
    s/●出版社名カタカナ●/$koumoku_content[11]/g;   	 #2L以上は使わない

    s/●読み方向●/$koumoku_content[5]/g;   	 		#2L以上は使わない

}


# サブルーチン　ログ出力    ===========================================================================

    sub output_log{

   	 push(@log, "$koumoku_content[4]," . "$koumoku_content[0],". "$koumoku_content[2]\n");   		#0901 update

	}


# サブルーチン　著者分割    ===========================================================================
#	12から23が著者名と著者名カタカナに交互に並ぶ。
#	人数分出力と、カウント回し

    sub chosha_divide{
    
    	  @chosha_mei = ($koumoku_content[14], 
		  					$koumoku_content[16], 
							$koumoku_content[18], 
							$koumoku_content[20], 
							$koumoku_content[22],    	  
							$koumoku_content[24]);    	  
    	  @chosha_katakana = ($koumoku_content[15], 
								$koumoku_content[17], 
								$koumoku_content[19], 
								$koumoku_content[21], 
								$koumoku_content[23],
								$koumoku_content[25]);

		my @chosha_meibo;  # 空の配列を初期化する

		# 特定のインデックスから始まる要素をチェックし、カラであればループを終了する
			for my $index (14, 16, 18, 20, 22, 24) {
   				my $element = $koumoku_content[$index];
				last unless defined $element && $element ne '';  # カラでないことをチェックしてループを終了する
    			push @chosha_meibo, $element;  # 配列に要素を追加する
			}

			my $chosha_counter = 0;

   			while ($chosha_counter < @chosha_meibo){
   			 
				my $fig_counter = $chosha_counter + 1;
#				print $fig_counter . "回目\n";
				
    			open(CHOSHA_TEMP, "<:encoding(UTF-8)", "01_templates/opf_choshamei.txt") or die "cant open opf_choshamei\n";		#著者情報のテンプレを読み込み
   	 			@chosha_temp = <CHOSHA_TEMP>;
    			close(CHOSHA_TEMP);

				foreach(@chosha_temp){

						s/●作家名●/$chosha_mei[$chosha_counter]/g;   			 						#サブルーチンに移管
						s/●作家名カタカナ●/$chosha_katakana[$chosha_counter]/g;   							#サブルーチンに移管
						s/▼作家順番▼/$fig_counter/g;
				}

   				push(@go_opf_chosha, @chosha_temp);
    	     	@chosha_temp = ();

    	     	$chosha_counter ++;
    	     	   	     
  		 	}
	}



# 	サブルーチン　目次のnavigation-documents.xhtml作成  	===========================================================================
#	
	sub make_mokuji	{

    open(IN_MOKUJI_LIST, "<:encoding(UTF-8)", "03_materials/$koumoku_content[4]/front_end/mokuji.csv") or die "cant open mokuji_csv\n";
    @mokuji_list = <IN_MOKUJI_LIST>;
    close(IN_MOKUJI_LIST);

    open(IN_NAVIG_LIST, "<:encoding(UTF-8)", "01_templates/navigation-documents.xhtml") or die "cant open navigation_documents_xhtml\n";
    @navig_list = <IN_NAVIG_LIST>;
    close(IN_NAVIG_LIST);

#			サンプル：<li><a href="xhtml/p-001.xhtml">「おいしい」はうれしい！</a></li>
#			サンプル：my $temp_row = '<itemref linear="yes" idref="p-%03d" properties="page-spread-%s"/>';
			my $temp_row = '<li><a href="xhtml/p-%03d.xhtml">%s</a></li>';

		my $mokuji_i = 0;

		while ($mokuji_i < @mokuji_list) {
			my $mokuji_phrase = $mokuji_list[0];
			my $nonble = $mokuji_list[1];
			push @go_mokuji, sprintf $temp_row, $nonble, $mokuji_phrase;
			}


		foreach(@navig_list){

   			s/▼目次行印字位置▼/join "", @go_mokuji/eg;   		 #環境変数から用意

		}
	
	}






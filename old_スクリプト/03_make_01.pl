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


#	================================================================================================================================
#    my @;

	
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

   		 &gazou_glob;   					#prcs03		画像情報の取得
   		 
   		 &make_xhtml_one;   				#prcs04		p-001xhtmlのセッティング

   		 &make_xhtml_extra;   				#prcs05		p-002以降のxhtmlのセッティング

   		 &make_opf;   						#prcs06		opfファイルのセッティング

		 &make_mokuji;
   		 
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

# 画像情報を作成    ===========================================================================
    sub gazou_glob{

    # jpg のファイル数を取得    -----------------------------
   	 my @gazou_files = glob("04_output/$koumoku_content[4]/item/image/*.jpg");   		 #outpubフォルダ内画像

#   	 print @gazou_files;   						 #テスト　画像ファイル名取得の確認

   	 # ファイル数カウント    -----------------------------
   	 $count = 0;

   	 while ($count < @gazou_files){

   		 my $img_count = $count + 1;
   		 my $sanketa_number = sprintf("%03d", $img_count);    				#ファイル名が000の3桁なので。

   		 rename $gazou_files[$count], "04_output/$koumoku_content[4]/item/image/i-$sanketa_number.jpg";
		 																		#画像リネーム 

   			 $count ++;

   		 }
   		 
   		 my $gazou_count = $count;   												#確定の画像数
#  		 print "$koumoku_content[4] gazou count ha $gazou_count\n";   				 #確認用

   		 $page_count = $gazou_count - 1;   						 #画像数-1、が作るxhtmlページ数
#  		 print "page_count ha $page_count\n";   				 #確認用

     }


#    p-001.xhtmlの読み込み部分    ===========================================================================

    sub make_xhtml_one{
    
#	htmlとxhtmlテンプレを開く	------------------------------------

   	 open(IN_HTML, "<:encoding(UTF-8)", "01_templates/target.html") or die "cant open html\n";
   	 @moto_html = <IN_HTML>;
   	 close(IN_HTML);

   	 open(IN_XHTML, "<:encoding(UTF-8)", "01_templates/p-00n.xhtml") or die "cant open 0n_xhtml\n";
   	 @xhtml_enu = <IN_XHTML>;
   	 close(IN_XHTML);


#	<h1>でhtmlを切り出し    ------------------------------------

# HTMLパーサーを作成し、HTMLコンテンツを解析
my $tree = HTML::TreeBuilder->new;
$tree->parse_content($html_content);

# コピーするコンテンツを保存するための配列
my @sections;

# h1, h2タグを順に処理
my @headings = $tree->look_down(_tag => qr/^h[12]$/);
foreach my $heading (@headings) {
    my $section = $heading->as_HTML;
    
    # 次のh1, h2タグまでの内容をコピー
    for (my $sib = $heading->right; $sib; $sib = $sib->right) {
        last if $sib->tag =~ /^h[12]$/;
        $section .= $sib->as_HTML;
    }
    
    push @sections, $section;
}

# セクションをXHTMLテンプレートに挿入
my $insert_position = index($xhtml_content, '</body>');
substr($xhtml_content, $insert_position, 0, join("\n", @sections));

# 出力ファイルに書き込み
open my $output_fh, '>', $output_file or die "Cannot open $output_file: $!";
print $output_fh $xhtml_content;
close $output_fh;

print "Output written to $output_file\n";


#	<h1>でhtmlを切り出し


   	 foreach(@xhtml_enu){

   			 &umekomi;   								 
  			s/▼縦サイズ▼/$ichi_height/g;   			#環境変数から用意
  			s/▼横サイズ▼/$width/g;   			 	#環境変数から用意_1030に幅700pix（仕様）戻しに伴い修正追加
#			$ichi_height = ();

   		 }
    }


#    standard.opfの読み込み部分    ===========================================================================

    sub make_opf{   				 

   	 open(IN_STD, "<:encoding(UTF-8)", "01_templates/standard.opf")  or die "cant open opf\n";
   	 @standard_opf = <IN_STD>;
   	 close(IN_STD);

#   		 print $standard_opf[0];   											 #確認用

   	 $image_count = $page_count - 1;

   	 push(my @cut_img_list, @img_list[0..$image_count]);   					 #画像枚数だけ、imgタグを出力（imageだけ１回少なく）
   	 push(my @cut_xhtml_list, @xhtml_list[0..$page_count]);   				 #画像枚数だけ、xhtmlタグを出力
   	 push(@cut_spine_list, @spine_list[0..$page_count]);   				 #画像枚数だけ、spineタグを出力
   				 
#   	 print @cut_img_list;   												 #確認用

	&make_spine;

   	foreach(@standard_opf)   	 
   		 {
   			 &umekomi;   												 #

   			s/▼著者情報テキスト挿入位置▼/join "", @go_opf_chosha/eg;   			 #サブルーチン chosha_divide の生成テキストを挿入

   			s/▼画像ファイルタグ印字位置▼/join "", @cut_img_list/e;   			 #これがいちばんマシ

   			s/▼xhtmlファイルタグ印字位置▼/join "", @cut_xhtml_list/eg;   		 #環境変数から用意
 
#   		s/▼spineタグ印字位置▼/join "", @go_spine_list/eg;   				 #環境変数から用意。古い書き方
			my $replacement = join "\n", @go_spine_list; 				# 改行で結合
			s/▼spineタグ印字位置▼/$replacement/g;

   		 }
   		 
   	@go_opf_chosha = ();											#opfに埋め込む著者情報の配列を初期化
   		 
    }



#    toc.ncxの読み込み部分    ===========================================================================

#    sub make_tocncx{   				 

#   	 open(IN_STD, "<:encoding(UTF-8)", "01_templates/toc.ncx")  or die "cant open ncx\n";
#   	 @toc_ncx = <IN_STD>;
#   	 close(IN_STD);




#	}



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
   	 rcopy("01_templates/item/style","04_output/$koumoku_content[4]/item/style") or die "styleをコピーできません\n";
#   	 rcopy("01_templates/item/navigation-documents.xhtml","04_output/$koumoku_content[4]/item") or die "styleをコピーできません\n";

  	 #    画像ファイルコピー    -----------    

   	 rcopy("03_materials/$koumoku_content[4]","04_output/$koumoku_content[4]/item/image") or die "$koumoku_content[4]の画像をコピーできません\n";
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

    s/●読み方向●/$koumoku_content[5]/g;   	 #2L以上は使わない

}


# サブルーチン　ログ出力    ===========================================================================

    sub output_log{

   	 push(@log, "$koumoku_content[4]," . "$koumoku_content[0],". "$koumoku_content[2]\n");   		#0901 update

	}


# サブルーチン　著者分割    ===========================================================================
#	12から23が著者名と著者名カタカナに交互に並ぶ。
#	人数分出力と、カウント回し

    sub chosha_divide{
    
    	  @chosha_mei = ($koumoku_content[12], 
		 					$koumoku_content[14], 
		  					$koumoku_content[16], 
							$koumoku_content[18], 
							$koumoku_content[20], 
							$koumoku_content[22]);    	  
    	  @chosha_katakana = ($koumoku_content[13], 
								$koumoku_content[15], 
								$koumoku_content[17], 
								$koumoku_content[19], 
								$koumoku_content[21], 
								$koumoku_content[23]);

		my @chosha_meibo;  # 空の配列を初期化する

		# 特定のインデックスから始まる要素をチェックし、カラであればループを終了する
			for my $index (12, 14, 16, 18, 20, 22) {
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


# 	サブルーチン　opfのspine作成  	===========================================================================
#		ltr・rtlの分岐とleft・rightの交互出力

	sub make_spine{

		# 画像の数
#			my $image_count = 10;
		# 読み方向 (ltr または rtl)
			my $reading_direction = 'ltr'; # or 'rtl'

		# 基本のタグテンプレート
			my $template = '<itemref linear="yes" idref="p-%03d" properties="page-spread-%s"/>';

		# 初期のプロパティを決定
			my $left_property = 'left';
			my $right_property = 'right';

		# 読み方向がrtlの場合、プロパティを反転
			if ($reading_direction eq 'rtl') {
				 ($left_property, $right_property) = ($right_property, $left_property);
			}

		# 配列にタグを格納する
#			my @itemref_tags;

		# 画像の数だけタグを生成して配列に追加
#	for my $i (@cut_spine_list) {

	my $spine_i = 0;

	while ($spine_i < @cut_spine_list) {
		my $index = $cut_spine_list[$spine_i];
		my $content = $spine_i;
		last unless defined $content && $content ne '';  # カラでないことをチェックしてループを終了する
		my $property = ($spine_i % 2 == 0) ? $left_property : $right_property;
		push @go_spine_list, sprintf $template, $content, $property;

	    $spine_i++;
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






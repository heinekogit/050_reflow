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
use Data::Dumper;  # デバッグ用に追加

# 未解決 --------------------------------------------------------------------------------
#   ・奥付の縦横をどうするか（作品毎、あるいはテンプレ的に決まっている場合
#       現在、テンプレの横書き設定がイキ。変換するにしても、どこ指示？　書誌？
#   ・
# 
#  --------------------------------------------------------------------------------------

#	グローバル変数　========================================================================================================
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

our @output_filenames;
my @new_opf_content;
my $opf_out_fh;

my @item_tags;
my @spine_tags;

my @page_title;
my @page_cover;
my @page_ptoc;
my @page_colophon;

my $current_template;
my $template_fh;

my @id_to_filename;

my @content_colophon;

my $lines_to_copy_ref;
my $id_to_filename_ref;

my @annotations;

#	============================================================================================================
#	パス：C:\Users\tomoki.kawakubo\050
#	============================================================================================================
#	素材の取り込み 

    open(IN_TRGT, "<:encoding(UTF-8)", "05_assemble/target.xhtml") or die "cant open target_html\n";
    @trgt_html = <IN_TRGT>;
    close(IN_TRGT);

#	==============================================================================================================
#	目次に使う目次素材テキスト & navigation-documents.xhtml & toc.ncxの取り込み    

#    open(IN_MOKUJI_LIST, "<:encoding(UTF-8)", "05_assemble/mokuji.csv") or die "cant open mokuji_csv\n";
#    @mokuji_list = <IN_MOKUJI_LIST>;
#    close(IN_MOKUJI_LIST);

#    open(IN_NAVIG_LIST, "<:encoding(UTF-8)", "00_templates/navigation-documents.xhtml") or die "cant open navigation_documents_xhtml\n";
#    @navig_list = <IN_NAVIG_LIST>;
#    close(IN_NAVIG_LIST);


#    shosi.csvの読み込み部分   	 ===========================================================================

    open(IN_SHOSI, "<:encoding(UTF-8)", "05_assemble/shosi.csv") or die "cant open shosi\n";
    @shosi = <IN_SHOSI>;
    close(IN_SHOSI);

    foreach(@shosi)   	 
   	 {
   		@koumoku_content = split(/,/);
   		 
   		&pre_check;						#prcs00		書誌とデータのチェック
   		 
   		&chosha_divide;					#prcs01		著者複数の場合

   		&output_folders;   				#prcs02		フォルダ類＆画像ファイルを出力
   		 
		&make_page_cover;			# カバーページ
		&make_page_title;			# タイトルページ
		&make_page_colophon;		# 奥付

   		&make_xhtml;   					#prcs04		xhtmlのセッティング・出力
			# |_ &write_to_file 		
		 
   		&make_opf;   						#prcs06		opfファイルのセッティング
			# |_ $fill_opf 
			# |_ &gazou_glob 

        # （機能目次）navigationの生成
		update_navigation(\@id_to_filename, "00_templates/navigation-documents.xhtml", "06_output/$koumoku_content[3]/item/navigation-documents.xhtml", "05_assemble/go_navigation.xhtml");

        # （目次ページ）tocの生成
		update_toc(\@id_to_filename, "00_templates/p-toc.xhtml", "06_output/$koumoku_content[3]/item/xhtml/p-toc.xhtml", "05_assemble/go_toc.xhtml");

        # （単体の注釈ページがアリの場合）annotationの生成
		make_page_annotation(\@id_to_filename, "00_templates/p-annotation.xhtml", "06_output/$koumoku_content[3]/item/xhtml/p-annotation.xhtml", "05_assemble/go_annotation.xhtml");
#        if ($koumoku_content[6] eq 'yes') {
#            &make_page_annotation;
#        }
 
   		&output_log;						#prcs08		ログファイルの出力

   	 }

   	 open(LOGS, ">:encoding(UTF-8)", "06_output/used_sozai_$koumoku_content[3]/log.txt") or die "cant open log_file\n";   	 #002以降xhtmlファイルの出力
   	 print LOGS @log;
   	 close(LOGS);


# 事前チェック    ===========================================================================
    sub pre_check{
		
		opendir(DIRHANDLE, "05_assemble");		# ディレクトリエントリの取得

		foreach(readdir(DIRHANDLE)){
			next if /^\.{1,2}$/;				# '.'や'..'をスキップ
#			print "$_\n";
		}

		my $data = $koumoku_content[3];
		
		for (@mate_folders) {

		if ($_ eq $data){
  				print "ok\n";
			} else {
  				print "$data nai\n";
			}
		}
	}


# xhtmlの加工    ===========================================================================

sub make_xhtml {
    # 素材htmlを読み込み
    open(my $input_fh, '<:encoding(UTF-8)', "05_assemble/target.xhtml") or die "Cannot open file input_file: $!";

    # 出力ファイルの連番用カウンタ
    my $file_counter = 1;

    # コピーを開始するフラグとコピー対象の行を格納する変数
    my $copying = 0;
    my @lines_to_copy;
    my $current_template = '';
    my %id_to_filename;             # IDからファイル名へのマッピング

    while (my $line = <$input_fh>) {
        chomp $line;

        if ($line =~ m/<div class="_idGen[^"]*">/) {
            if ($copying) {
                # 余分な空行を削除
                while (@lines_to_copy && $lines_to_copy[-1] =~ /^\s*$/) {
                    pop @lines_to_copy;
                }

                # 現在のテンプレートファイルを開き、xhtml出力の処理を呼び出す
                open(my $template_fh, '<:encoding(UTF-8)', $current_template) or die "Cannot open file $current_template: $!";
                
                # 書き込み処理と注釈処理
                write_to_file($file_counter, \@lines_to_copy, $template_fh, \@output_filenames);
                close($template_fh);
                $file_counter++;
                @lines_to_copy = ();  # 配列をクリア
            }

            # テンプレートファイルを選択する（→ 画像ページかテキストページに分岐）
            if ($line =~ m/<div class="_idGenObject[^"]*">/) {
                $current_template = "00_templates/p-gazou.xhtml";
            } else {
                $current_template = "00_templates/p-text.xhtml";
            }

            # コピーを開始する
            $copying = 1;
            @lines_to_copy = ();  # 配列をクリア
        }

        if ($copying) {
            # コピー中なら行を配列に追加する
            push @lines_to_copy, $line;
        }
    }

    # 最後のコピー対象もファイルに書き出す ----------------------------------------------------------
    if ($copying && @lines_to_copy) {  # 配列が空でない場合
        # 余分な空行を削除
        while (@lines_to_copy && $lines_to_copy[-1] =~ /^\s*$/) {
            pop @lines_to_copy;
        }

        # 最後のテンプレートで出力処理
        open(my $template_fh, '<:encoding(UTF-8)', $current_template) or die "Cannot open file $current_template: $!";
        write_to_file($file_counter, \@lines_to_copy, $template_fh, \@output_filenames);
        close($template_fh);

        $file_counter++;  # ファイルカウンタを更新
    }

    # ファイルハンドルを閉じる
    close($input_fh);

    print "HTML operation end\n";
}


# xhtmlページファイル出力 =========================================
# make_xhtml 内の入れ子のサブルーチン

sub write_to_file {
    my ($counter, $lines_ref, $template_fh, $filenames_ref, $id_to_filename_ref, $koumoku_content) = @_;

    # 出力ファイルのパスを作成
    my $filename = sprintf("06_output/%s/item/xhtml/p-%03d.xhtml", $koumoku_content[3], $counter);
    open(my $output_fh, '>:encoding(UTF-8)', $filename) or die "Could not open output file '$filename': $!";

    # ファイル名をリストに追加

    my $current_index = sprintf("p-%03d.xhtml", $counter);  # 3桁にフォーマット
    push @$filenames_ref, $current_index;

    # コピー対象の行を結合し、target.xhtml の記述を置換
    my $content_to_insert = join("\n", @$lines_ref);
    $content_to_insert =~ s{href="target\.xhtml(#[^"]*)?"}{href="$current_index$1"}g;

    # `target.xhtml` の置換対象を限定（テンプレートの読み込み前に実施）
    my @template_lines;
    while (my $temp_line = <$template_fh>) {
        chomp $temp_line;
        push @template_lines, $temp_line;
    }

    # テンプレート側でも target.xhtml を適切に置換
    for my $temp_line (@template_lines) {
        $temp_line =~ s/(href|src)="target\.xhtml"/$1="$filename"/g;
    }

    # toc_id の取得
    my $found_id = '';
    if ($content_to_insert =~ /<a id="(toc-\d+)"><\/a>/) {
        $found_id = $1;
        push @$id_to_filename_ref, { id => $found_id, filename => $filename };
    }

    # プレースホルダー置換と出力
    foreach my $temp_line (@template_lines) {
        $temp_line =~ s/▼本文挿入位置▼/$content_to_insert/;
        if ($found_id) {
            $temp_line =~ s/●toc_id●/id="$found_id"/;
        } else {
            $temp_line =~ s/●toc_id●//;
        }

		$temp_line =~ s/●タイトル名●/$koumoku_content[0]/;		# 標準的な文字置き換えがここで可

        # $temp_line =~ s/●方向●/$koumoku_content[4]/;			# _idGenStoryDirection-2でなかった場合、と改修。
        if ($temp_line =~ /●方向●/) {
            if ($content_to_insert =~ m/<div class="_idGenStoryDirection-2">/) {            # オリジナル
                if ($koumoku_content[4] eq 'vrtl') {
                    $temp_line =~ s/●方向●/hltr/;
                } elsif ($koumoku_content[4] eq 'hltr') {
                    $temp_line =~ s/●方向●/vrtl/;
                }
            } elsif ($content_to_insert =~ m/<div class="_idGenObjectLayout-1">/) {
                $temp_line =~ s/●方向●/$koumoku_content[4]/;
            } else {
                $temp_line =~ s/●方向●/$koumoku_content[4]/;
            }
        }

        print $output_fh "$temp_line\n";
    }

    close($output_fh);
#        print "Wrote $filename\n";      # デバック用
    return $filename;
}


#    standard.opfの読み込み部分    ===========================================================================

    sub make_opf {   				 

   	 open(IN_STD, "<:encoding(UTF-8)", "00_templates/standard.opf")  or die "cant open opf\n";
   	 @standard_opf = <IN_STD>;
   	 close(IN_STD);

# 呼び出し前に @output_filenames の内容を確認
#	print "Output filenames before calling fill_opf:\n";
#	print "$_\n" for @output_filenames;

# サブルーチンを呼び出して配列リファレンスを取得
my ($item_tags_ref, $spine_tags_ref) = fill_opf(\@standard_opf, \@output_filenames);

# 取得した配列を用いて処理を行う
my @modified_opf;
# 画像タグを取得
my $gazou_tags_ref = gazou_glob(\@standard_opf);

# タグの配列を一つの文字列に結合
my $item_tags_str = join "\n", @$item_tags_ref;
my $spine_tags_str = join "\n", @$spine_tags_ref;

foreach my $line (@standard_opf) {
	$line =~ s/●タイトル名●/$koumoku_content[0]/g;
    $line =~ s/●話巻順番●/$koumoku_content[1]/g;   			 #2L以上は使わない
    $line =~ s/●タイトル名カタカナ●/$koumoku_content[9]/g;   	 #2L以上は使わない
    $line =~ s/●話数3桁●/$koumoku_content[2]/g;   			 	#2L以上は使わない
    $line =~ s/●出版社名●/$koumoku_content[11]/g;   			 #2L以上は使わない
    $line =~ s/●出版社名カタカナ●/$koumoku_content[13]/g;   	 #2L以上は使わない
    $line =~ s/●読み方向●/$koumoku_content[4]/g;

	$line =~ s/▼著者情報テキスト挿入位置▼/join "", @go_opf_chosha/eg;   		#	サブルーチン chosha_divide   

    $line =~ s/▼xhtmlファイルタグ印字位置▼/$item_tags_str/eg;
    $line =~ s/▼spineタグ印字位置▼/$spine_tags_str/eg;
    $line =~ s/▼画像ファイルタグ印字位置▼/join "\n", @$gazou_tags_ref/eg;

    # annotationの処理
    if ($koumoku_content[6] eq "yes") {         
        my $annotation_xhtml_tag = '<item media-type="application/xhtml+xml" id="p-annotation" href="xhtml/p-annotation.xhtml"/>';
        my $annotation_spine_tag = '<itemref linear="yes" idref="p-annotation"/>';
        $line =~ s/▼annotationのxhtmlタグ印字位置▼/$annotation_xhtml_tag/;
        $line =~ s/▼annotatiのspineタグ印字位置▼/$annotation_spine_tag/;
    } else {
        $line =~ s/▼annotationのxhtmlタグ印字位置▼\n?//;
        $line =~ s/▼annotatiのspineタグ印字位置▼\n?//;
    }

	# 現在の日時を取得
	my $dt = DateTime->now;
	# ISO 8601形式で出力
	my $iso8601_string = $dt->iso8601 . 'Z';
    $line =~ s/●作業日時●/$iso8601_string/g;   	 

    push @modified_opf, $line;
}

# 結果を出力ファイルに保存
open(OUT, ">:encoding(UTF-8)", "06_output/$koumoku_content[3]/item/standard.opf") or die "cant open output file\n";
print OUT @modified_opf;
close(OUT);

   	@go_opf_chosha = ();											#　opfに埋め込む著者情報の配列を初期化

    }


#  opf用のxhtml／spineタグ整形 ===========================================================================

sub fill_opf {
    my ($opf_content_ref, $output_filenames_ref) = @_;

    # デバッグ用に $output_filenames_ref の内容を出力
#    print "Output filenames:\n";
#    print "$_\n" for @$output_filenames_ref;

    # <item>タグと<itemref>タグを生成
    my (@item_tags, @spine_tags);
    foreach my $filename (@$output_filenames_ref) {
#        (my $id = $filename) =~ s/\.xhtml$//;
#        push @item_tags, qq(<item media-type="application/xhtml+xml" id="$id" href="xhtml/$id.xhtml"/>);
#        push @item_tags, qq(<item media-type="application/xhtml+xml" id="$id" href="xhtml/$id.xhtml"/>);
#        push @spine_tags, qq(<itemref linear="yes" idref="$id"/>);
    # ファイル名だけを取得
    my $basename = basename($filename, '.xhtml');
    push @item_tags, qq(<item media-type="application/xhtml+xml" id="$basename" href="xhtml/$basename.xhtml"/>);
    push @spine_tags, qq(<itemref linear="yes" idref="$basename"/>);
    }

    # 生成したタグの内容を出力
#    print "Item Tags:\n";
#    print "$_\n" for @item_tags;

#    print "\nSpine Tags:\n";
#    print "$_\n" for @spine_tags;

    # タグを1つの文字列に結合するのではなく、タグの配列を返す
    return (\@item_tags, \@spine_tags);
}

# opf用の画像情報を作成 ===========================================================================

sub gazou_glob {
    my ($opf_content_ref) = @_;

    # jpg のファイル数を取得
    my @gazou_files = glob("05_assemble/image/*.jpg"); # 出力フォルダ内画像

    # 画像ファイル名を基にした<item>タグを生成
    my @gazou_tags;
    foreach my $file (@gazou_files) {
        # ファイル名からパスを削除
        my ($filename) = $file =~ m{.*/(.*)\.jpg};
        push @gazou_tags, qq(<item media-type="image/jpeg" id="$filename" href="image/$filename.jpg"/>);
    }

    # 生成したタグの内容を出力
#    print "Gazou Tags:\n";
#    print "$_\n" for @gazou_tags;

    # タグの配列を返す
    return \@gazou_tags;
}

#    フォルダ・ファイルの出力    ===========================================================================

#    フォルダ・画像類の出力・コピー    ------------------------------------------

    sub output_folders{

#   	 $koumoku_name[4];   							 #話のファイル名

   	 mkdir("06_output/$koumoku_content[3]", 0755) or die "話のフォルダを作成できませんでした\n";
   	 mkdir("06_output/$koumoku_content[3]/item", 0755) or die "itemフォルダを作成できませんでした\n";
   	 mkdir("06_output/$koumoku_content[3]/META-INF", 0755) or die "META-INFのフォルダを作成できませんでした\n";
   	 mkdir("06_output/$koumoku_content[3]/item/xhtml", 0755) or die "xmlフォルダを作成できませんでした\n";
   	 mkdir("06_output/$koumoku_content[3]/item/style", 0755) or die "styleのフォルダを作成できませんでした\n";
   	 mkdir("06_output/$koumoku_content[3]/item/image", 0755) or die "話の画像のフォルダを作成できませんでした\n";

   	 mkdir("06_output/used_sozai_$koumoku_content[3]", 0755) or die "使用済データのフォルダを作成できませんでした\n";

   	 #    テンプレよりテキスト類のコピー    -----------    

   	 rcopy("00_templates/META-INF/container.xml","06_output/$koumoku_content[3]/META-INF") or die "container.xmlをコピーできません\n";
   	 rcopy("00_templates/mimetype","06_output/$koumoku_content[3]") or die "mimetypeをコピーできません\n";
   	 rcopy("00_templates/style","06_output/$koumoku_content[3]/item/style") or die "styleをコピーできません\n";
#   	 rcopy("00_templates/item/navigation-documents.xhtml","06_output/$koumoku_content[3]/item") or die "styleをコピーできません\n";

  	 #    画像ファイルコピー    -----------    

   	 rcopy("05_assemble/image_fixity","06_output/$koumoku_content[3]/item/image") or die "$koumoku_content[3]の固定画像をコピーできません\n";
   	 rcopy("05_assemble/image","06_output/$koumoku_content[3]/item/image") or die "$koumoku_content[3]の画像をコピーできません\n";
					#注意：英数字以外のファイル名が引っかかるっぽい

  	 #    shosi.csvを生成xhtml階層にログ的コピー保存    -----------    

   	 rcopy("05_assemble/shosi.csv","06_output/used_sozai_$koumoku_content[3]") or die "shosiを履歴用にコピーできません\n";
   	 rcopy("05_assemble/go_navigation.xhtml","06_output/used_sozai_$koumoku_content[3]") or die "go_navigation.xhtmlを履歴用にコピーできません\n";
   	 rcopy("05_assemble/go_toc.xhtml","06_output/used_sozai_$koumoku_content[3]") or die "go_toc.xhtmlを履歴用にコピーできません\n";
   	 rcopy("05_assemble/target.xhtml","06_output/used_sozai_$koumoku_content[3]") or die "target.xhtmlを履歴用にコピーできません\n";

    }


    #    テキスト類の出力    ----------------------------------------------------------------------------
    
   	 sub output_txts{

   	 open(OUT_STD, ">:encoding(UTF-8)", "06_output/$koumoku_content[3]/item/standard.opf") or die "cant make opf\n";   		 #opfファイルの出力
   	 print OUT_STD @standard_opf;
   	 close(OUT_STD);

   	 open(OUT_01, ">:encoding(UTF-8)", "06_output/$koumoku_content[3]/item/xhtml/p-001.xhtml") or die "cant make xhtml\n";   	 #001のxhtmlファイルの出力
   	 print OUT_01 @xhtml_one;
   	 close(OUT_01);

    }


# サブルーチン 文字変換    ===========================================================================

sub umekomi {
    s/●タイトル名●/$koumoku_content[0]/g;   			 #2L以上は使わない
    s/●タイトル名カタカナ●/$koumoku_content[9]/g;   	 #2L以上は使わない
    s/●話数3桁●/$koumoku_content[2]/g;   			 	#2L以上は使わない

    s/●出版社名●/$koumoku_content[11]/g;   			 #2L以上は使わない
    s/●出版社名カタカナ●/$koumoku_content[13]/g;   	 #2L以上は使わない

    s/●読み方向●/$koumoku_content[4]/g;   	 		#2L以上は使わない

}


# サブルーチン ログ出力    ===========================================================================

    sub output_log{

   	 push(@log, "$koumoku_content[3]," . "$koumoku_content[0],". "$koumoku_content[2]\n");   		#0901 update

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
				
    			open(CHOSHA_TEMP, "<:encoding(UTF-8)", "00_templates/opf_choshamei.txt") or die "cant open opf_choshamei\n";		#著者情報のテンプレを読み込み
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


# 	サブルーチン 前付・後付ページs作成  	===========================================================================

# カバーページ ---------------------------------------------------------------------------------------
sub make_page_cover {

# テンプレートファイルを読み込む
open(IN_COVER, '<:encoding(UTF-8)', "00_templates/p-cover.xhtml") or die "Cannot open temp p-cover: $!";
@page_cover = <IN_COVER>;
close(IN_COVER);

#	カバー画像のサイズを取得    ------------------------------------

   	 my $zeroone = glob("06_output/$koumoku_content[3]/item/image/i-cover.jpg");   				#
   	 # .jpg のサイズを取得
   		 (my $cover_width, my $cover_height) = imgsize("06_output/$koumoku_content[3]/item/image/i-cover.jpg");		#パターンa	001を直で指定	イキ

   	 foreach(@page_cover){
   			&umekomi;   								 
  			s/▼縦サイズ▼/$cover_height/g;   			#環境変数から用意
  			s/▼横サイズ▼/$cover_width/g;   			 	#環境変数から用意_1030に幅700pix（仕様）戻しに伴い修正追加
   		 }

   	 open(OUT_COVER, ">:encoding(UTF-8)", "06_output/$koumoku_content[3]/item/xhtml/p-cover.xhtml") or die "cant make p-cover.xhtml\n";   	 #001のxhtmlファイルの出力
   	 print OUT_COVER @page_cover;
   	 close(OUT_COVER);
}

# タイトルページ ---------------------------------------------------------------------------------------
sub make_page_title {

# テンプレートファイルを読み込む
open(IN_TITLE, '<:encoding(UTF-8)', "00_templates/p-titlepage.xhtml") or die "Cannot open temp p-titlepage: $!";
@page_title = <IN_TITLE>;
close(IN_TITLE);

   	 foreach(@page_title){
   			 &umekomi;   								 
   		 }

   	 open(OUT_TITLE, ">:encoding(UTF-8)", "06_output/$koumoku_content[3]/item/xhtml/p-titlepage.xhtml") or die "cant make p-titlepage.xhtml\n";   	 #001のxhtmlファイルの出力
   	 print OUT_TITLE @page_title;
   	 close(OUT_TITLE);
}

# 奥付 ---------------------------------------------------------------------------------------
sub make_page_colophon {

# 奥付用を読み込む
open(GO_COLOPHON, '<:encoding(UTF-8)', "05_assemble/go_colophon.xhtml") or die "Cannot open go_colophon: $!";
@content_colophon = <GO_COLOPHON>;
close(GO_COLOPHON);

    # 改行を除去
    chomp(@content_colophon);

# テンプレートファイルを読み込む
open(IN_COLOPHON, '<:encoding(UTF-8)', "00_templates/p-colophon.xhtml") or die "Cannot open temp p-colophon: $!";
@page_colophon = <IN_COLOPHON>;
close(IN_COLOPHON);

    # 奥付内容を1行の文字列にする
    my $cont_colophon = join("\n", @content_colophon);

   	 foreach(@page_colophon){
   			&umekomi;   								 
            s/▼奥付内容の印字位置▼/$cont_colophon/;
   		}

   	 open(OUT_COLOPHON, ">:encoding(UTF-8)", "06_output/$koumoku_content[3]/item/xhtml/p-colophon.xhtml") or die "cant make p-colophon.xhtml\n";   	 #001のxhtmlファイルの出力
   	 print OUT_COLOPHON @page_colophon;
   	 close(OUT_COLOPHON);
}


# navigation（navigation-documents.xhtml）を生成・出力するサブルーチン =====================================================

sub update_navigation {
    my ($id_to_filename_ref, $template_path, $output_path, $navigation_data_path) = @_;
    
    # 目次データを読み込む
    open(my $nav_fh, '<:encoding(UTF-8)', $navigation_data_path) or die "Cannot open file $navigation_data_path: $!";
    my @nav_lines = <$nav_fh>;
    close($nav_fh);

    # テンプレートファイルを読み込む
    open(my $template_fh, '<:encoding(UTF-8)', $template_path) or die "Cannot open file $template_path: $!";
    my @template_lines = <$template_fh>;
    close($template_fh);

    # 目次リストを生成
    my @toc_list;
    for my $line (@nav_lines) {
        chomp $line;
        if ($line =~ m/href="target\.xhtml#(toc-\d+)"/) {
            my $toc_id = $1;
            my ($id_entry) = grep { $_->{id} eq $toc_id } @$id_to_filename_ref;
            if ($id_entry) {
                my $filename = $id_entry->{filename};
                $filename =~ s|^.*?/item/||;  # フォルダ名を除去
                $line =~ s/href="target\.xhtml/href="$filename/;
            }
        }
        push @toc_list, $line;
    }
    
    my $toc_content = join("\n", @toc_list);
    my $placeholder = quotemeta('▼目次リスト印字位置▼');
    
    # テンプレートファイルの内容を読み込み、プレースホルダーを置換して出力ファイルに書き込む
    open(my $output_fh, '>:encoding(UTF-8)', $output_path) or die "Could not open output file '$output_path': $!";
    for my $temp_line (@template_lines) {
        chomp $temp_line;
        $temp_line =~ s/$placeholder/$toc_content/;
        print $output_fh "$temp_line\n";
    }
    close($output_fh);
}

# toc（p-toc.xhtml）を生成・出力するサブルーチン ===========================================================================

sub update_toc {
    my ($id_to_filename_ref, $template_path, $output_path, $toc_data_path) = @_;
    
    # 目次データを読み込む
    open(my $nav_fh, '<:encoding(UTF-8)', $toc_data_path) or die "Cannot open file $toc_data_path: $!";
    my @nav_lines = <$nav_fh>;
    close($nav_fh);

    # テンプレートファイルを読み込む
    open(my $template_fh, '<:encoding(UTF-8)', $template_path) or die "Cannot open file $template_path: $!";
    my @template_lines = <$template_fh>;
    close($template_fh);


    # 目次リストを生成
    my @toc_list;
    for my $line (@nav_lines) {
        chomp $line;
        if ($line =~ m/href="target\.xhtml#(toc-\d+)"/) {
            my $toc_id = $1;
            my ($id_entry) = grep { $_->{id} eq $toc_id } @$id_to_filename_ref;
            if ($id_entry) {
                my $filename = $id_entry->{filename};
                $filename =~ s|^.*?/item\/xhtml/||;         # フォルダ名を除去
                $line =~ s/href="target\.xhtml/href="$filename/;
                
            }
        }
        push @toc_list, $line;
    }
    
    my $toc_content = join("\n", @toc_list);
    my $placeholder = quotemeta('▼目次コンテンツ挿入位置▼');
    
    # テンプレートファイルの内容を読み込み、プレースホルダーを置換して出力ファイルに書き込む
    open(my $output_fh, '>:encoding(UTF-8)', $output_path) or die "Could not open output file '$output_path': $!";
    for my $temp_line (@template_lines) {
        chomp $temp_line;
        
        $temp_line =~ s/●タイトル名●/$koumoku_content[0]/g;   			 #2L以上は使わない
        
        $temp_line =~ s/$placeholder/$toc_content/;
        print $output_fh "$temp_line\n";
    }
    close($output_fh);
}

# annotation（p-annotation.xhtml）を生成・出力するサブルーチン ===========================================================================

sub make_page_annotation {
#    print "Annotation ari\n";

    my ($id_to_filename_ref, $template_path, $output_path, $annotation_data_path) = @_;
    
    #脚注データを読み込む
    open(my $annot_fh, '<:encoding(UTF-8)', $annotation_data_path) or die "Cannot open file $annotation_data_path: $!";
    my @nav_lines = <$annot_fh>;
    close($annot_fh);

    # テンプレートファイルを読み込む
    open(my $template_fh, '<:encoding(UTF-8)', $template_path) or die "Cannot open file $template_path: $!";
    my @template_lines = <$template_fh>;
    close($template_fh);


    # 目次リストを生成
    my @anno_list;
    for my $line (@nav_lines) {
        chomp $line;
        if ($line =~ m/href="target\.xhtml#(toc-\d+)"/) {
            my $toc_id = $1;
            my ($id_entry) = grep { $_->{id} eq $toc_id } @$id_to_filename_ref;
            if ($id_entry) {
                my $filename = $id_entry->{filename};
                $filename =~ s|^.*?/item\/xhtml/||;         # フォルダ名を除去
                $line =~ s/href="target\.xhtml/href="$filename/;
                
            }
        }
        push @anno_list, $line;
    }
    
    my $anno_content = join("\n", @anno_list);
    my $placeholder = quotemeta('▼注釈コンテンツ挿入位置▼');
    
    # テンプレートファイルの内容を読み込み、プレースホルダーを置換して出力ファイルに書き込む
    open(my $output_fh, '>:encoding(UTF-8)', $output_path) or die "Could not open output file '$output_path': $!";
    for my $temp_line (@template_lines) {
        chomp $temp_line;
        
        $temp_line =~ s/●タイトル名●/$koumoku_content[0]/g;   			 #2L以上は使わない
        $temp_line =~ s/●方向●/$koumoku_content[4]/;			
        
        $temp_line =~ s/$placeholder/$anno_content/;
        print $output_fh "$temp_line\n";
    }
    close($output_fh);


}







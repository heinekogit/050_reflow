use strict;
use warnings;
use File::Copy;  # ファイルコピーのためにFile::Copyモジュールを使用

# 素材テキストを読み込んで変換 ---------------------------------------------------------------------------------------

my $input_file  = "04_arrange/arrange_toc.xhtml";   # sourceの目次ファイル抜粋部分
my $output_file1 = "03_setup/backup_navigation.xhtml"; # 出力ファイル（バックアップ確認用）
my $output_file2 = "04_arrange/arrange_navigation.xhtml"; # 出力ファイル

# ファイルが存在するか確認
unless (-e $input_file) {
    my $source_file = "00_templates/navigation-documents_no_toc.xhtml";
    my $destination_file = "05_assemble/navigation-documents_no_toc.xhtml";
    
    # ファイルをコピーしてリネーム
    copy($source_file, $destination_file) or die "Error: Failed to copy $source_file to $destination_file: $!";
    print "File copied and renamed to $destination_file\n";
    
    # スクリプトを終了
    exit;
}

open my $in,  '<', $input_file  or die "Cannot open $input_file: $!";
open my $out1, '>', $output_file1 or die "Cannot open $output_file1: $!";
open my $out2, '>', $output_file2 or die "Cannot open $output_file2: $!";

# 変換ルールの定義（キーが正規表現、値が置換後のテキスト）
while (<$in>) {
    # リンク部分の変換
    if (/<a href="([^"]*#toc-[^"]*)".*?>(.*?)<\/a>/) {
        my $link = $1;
        my $text = $2;

        # 不要なタグを削除
        $text =~ s/<span class="tcy">(.*?)<\/span>/$1/g;
        $text =~ s/<span class="ハイパーリンク _idGenCharOverride-.">(.*?)<\/span>/$1/g;
        $text =~ s/<span class="ハイパーリンク">(.*?)<\/span>/$1/g;
        $text =~ s/<span class="_idGenCharOverride-1">/<span class="tcy">/g;
        $text =~ s/<span class="ハイパーリンク">&#9;&#9;<\/span>//g;
        $text =~ s/<span class="…">&#9;&#9;&#9;<\/span>//g;
        $text =~ s/<span class="…">&#9;&#9;<\/span>//g;
        $text =~ s/<span class="…">&#9;<\/span>//g;

        # 最後にリンク部分を含んだ行を整形
        my $output_line = "<li><a href=\"$link\">$text</a></li>\n";
        
        # テキストを含まない行を削除
        unless ($output_line =~ m|<li><a href="[^"]*"></a></li>|) {
            print $out1 $output_line;
            print $out2 $output_line;
        }
    }
}

close $in;
close $out1;
close $out2;

print "Extraction complete. Output saved to:\n";
print "  - $output_file1\n";
print "  - $output_file2\n";

use strict;
use warnings;

# 素材テキストを読み込んで変換 ---------------------------------------------------------------------------------------

my $input_file  = "01_onmark/arrange_mokuji.txt";   # sourceの目次ファイル抜粋部分
my $output_file1 = "01_onmark/onmark_navigation.html"; # 出力ファイル
my $output_file2 = "02_getset/getset_navigation.html"; # 出力ファイル

open my $in,  '<', $input_file  or die "Cannot open $input_file: $!";
open my $out1, '>', $output_file1 or die "Cannot open $output_file1: $!";
open my $out2, '>', $output_file2 or die "Cannot open $output_file2: $!";

#   print $out "<html>\n<head><title>Navigation</title></head>\n<body>\n";

while (<$in>) {
    if (/<a href="([^"]*#_idTextAnchor[^"]*)".*?>(.*?)<\/a>/) {
        my $link = $1;
        my $text = $2;
        $link =~ s/#_idTextAnchor/#toc-/g;
        my $output_line = "<li><a href=\"$link\">$text</a></li>\n";

        print $out1 $output_line;
        print $out2 $output_line;
    }
}

close $in;
close $out1;
close $out2;

print "Extraction complete. Output saved to:\n";
print "  - $output_file1\n";
print "  - $output_file2\n";
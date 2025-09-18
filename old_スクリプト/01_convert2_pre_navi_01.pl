use strict;
use warnings;

# 素材テキストを読み込んで変換 ---------------------------------------------------------------------------------------

my $input_file  = "01_adjust/arrange_mokuji.txt";   # sourceの目次ファイル抜粋部分
my $output_file = "01_adjust/pre_navigation.html"; # 出力ファイル

open my $in,  '<', $input_file  or die "Cannot open $input_file: $!";
open my $out, '>', $output_file or die "Cannot open $output_file: $!";

#   print $out "<html>\n<head><title>Navigation</title></head>\n<body>\n";

while (<$in>) {
    if (/<a href="([^"]*#_idTextAnchor[^"]*)".*?>(.*?)<\/a>/) {
        my $link = $1;
        my $text = $2;
        $link =~ s/#_idTextAnchor/#toc-/g;
        print $out "<li><a href=\"$link\">$text</a></li>\n";
    }
}

#   print $out "</body>\n</html>\n";

close $in;
close $out;

print "Extraction complete. Output saved to $output_file\n";

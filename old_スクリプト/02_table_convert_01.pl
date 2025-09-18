use strict;
use warnings;

# 素材テキストを読み込んで変換

    #テスト用
    open my $in, '<', '02_arrange/source_original.html' or die "Cannot open source: $!";
    #本番用
#   open my $in, '<', '02_arrange/source.html' or die "Cannot open source: $!";
    open my $out, '>', '02_arrange/output.html' or die "Cannot open output: $!";
while (<$in>) {
    my $content = $_;  # 読み込んだ行を変数に格納

    # 置換
    $content =~ s/<rt class="_idGenRuby-.">/<rt>/g;
    $content =~ s/<img class="_idGenObjectAttribute-\d+" src="(.*?)\/(.*?)" alt="" \/>/<img src="..\/$2" alt="" class="fit" \/>/g;

    # 変換後の内容を書き出す
    print $out $content;
}
close $in;
close $out;

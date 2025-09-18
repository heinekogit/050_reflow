use strict;
use warnings;

my %table;

# 変換テーブルを読み込む
open my $fh, '<', '02_arrange/table.tsv' or die "Cannot open table: $!";
while (<$fh>) {
    chomp;
    next if /^\s*$/; # 空行をスキップ
    my ($from, $to) = split(/\t/, $_, 2);
    next unless defined $from and defined $to; # どちらかが未定義ならスキップ
    next if $from eq ""; # 空のキーをスキップ
    $table{$from} = $to;
}
close $fh;

# 素材テキストを読み込んで変換
open my $in, '<', '02_arrange/source.html' or die "Cannot open source: $!";
open my $out, '>', '02_arrange/output.html' or die "Cannot open output: $!";
while (<$in>) {
    my $content = $_; # 読み込んだ行を変数に格納
    foreach my $from (keys %table) {
        my $to = $table{$from};
        $content =~ s/$from/$to/eg; # `e` で `$1`, `$2` を展開
#        $content =~ s/$from/$to/ee; # `ee` で `$to` の `$2` も展開
#   print "DEBUG: from=$from, to=$to\n";
#        $content =~ s/$from/$to/eeg; # `g` を追加して複数回適用
            }
    print $out $content; # 変換後の内容を書き出す
}
close $in;
close $out;

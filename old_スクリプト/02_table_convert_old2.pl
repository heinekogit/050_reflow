use strict;
use warnings;

my %table;

# 変換テーブルを読み込む
open my $fh, '<', '02_arrange/table.tsv' or die "Cannot open table: $!";
while (<$fh>) {
    chomp;
    next if $_ =~ /^\s*$/; # 空行をスキップ
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
    my $line = $_;  # 現在の行
    my $original_line = $line;  # 元の行（デバッグ用）
    
    # 変換テーブルに基づいた置換を行う
    foreach my $from (keys %table) {
        my $to = $table{$from};

        # 変換前の行をデバッグ表示
        print "Before: $line\n" if $line =~ /$from/;

        # 正規表現による置換
        $line =~ s/\Q$from\E/$to/g;

        # 変換後の行をデバッグ表示
        print "After: $line\n" if $line =~ /$to/;
    }
    
    # 出力ファイルに書き込む
    print $out $line;

    # 変換されていない場合にデバッグ表示
    print "No changes: $original_line\n" if $line eq $original_line;
}

close $in;
close $out;

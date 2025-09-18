#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use File::Find;
use File::Basename;

# チェック対象のディレクトリ
my $dir = 'C:/Users/tomoki.kawakubo/050/06_output/miagete/item/xhtml';

# ログファイルのパス
my $log_file = 'C:/Users/tomoki.kawakubo/050/06_output/check_log.txt';

# ログファイルを開く
open(my $log_fh, '>:encoding(UTF-8)', $log_file) or die "Could not open log file '$log_file': $!";

# ディレクトリ内のファイルをチェック
find(\&check_file, $dir);

# ログファイルを閉じる
close($log_fh);

print "check end. logfile is $log_file\n";

# ファイルをチェックするサブルーチン
sub check_file {
    return unless -f;  # ファイルのみを対象とする
    return unless /\.xhtml$/;  # 拡張子がxhtmlのファイルのみを対象とする

    my $file = $File::Find::name;
    open(my $fh, '<:encoding(UTF-8)', $file) or die "Could not open file '$file': $!";

    my $div_open_count = 0;
    my $div_close_count = 0;

    while (my $line = <$fh>) {
        $div_open_count += () = $line =~ /<div\b/g;
        $div_close_count += () = $line =~ /<\/div>/g;
    }

    close($fh);

    my $filename = basename($file);
    if ($div_open_count == $div_close_count) {
        print $log_fh "$filename\t<div = $div_open_count\t</div> = $div_close_count\t同数\n";
    } else {
        print $log_fh "$filename\t<div = $div_open_count\t</div> = $div_close_count\t数が一致しない\n";
    }
}
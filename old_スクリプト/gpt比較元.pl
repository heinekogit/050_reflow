    sub make_xhtml{

# 素材htmlを読み込み
open(my $input_fh, '<:encoding(UTF-8)', "03_materials/target.html") or die "Cannot open file input_file: $!";
# テンプレートファイルを読み込む
open(my $template_fh, '<:encoding(UTF-8)', "01_templates/p-text.xhtml") or die "Cannot open file template_file: $!";

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
			# xhtml出力のサブルーチンへ　--------------------------------------------------------------＞＞＞＞＞
            write_to_file($file_counter, \@lines_to_copy, $template_fh, \@output_filenames);	
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
write_to_file($file_counter, \@lines_to_copy, $template_fh, \@output_filenames) if $copying;

# ファイルハンドルを閉じる
close($input_fh);
close($template_fh);

# 出力ファイル名を表示する（必要に応じて他の場所で使用可能）
#	print "Output files:\n";
#	print "$_\n" for @output_filenames;

print "HTML operation end\n";

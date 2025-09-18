sub make_xhtml {
    # 素材htmlを読み込み
    open(my $input_fh, '<:encoding(UTF-8)', "03_materials/target.html") or die "Cannot open file input_file: $!";
    # テンプレートファイルを読み込む

    # 出力ファイルの連番用カウンタ
    my $file_counter = 1;

    # コピーを開始するフラグとコピー対象の行を格納する変数
    my $copying = 0;
    my @lines_to_copy;
    my $current_template = '';

    while (my $line = <$input_fh>) {
        chomp $line;

        if ($line =~ m/<div class="_idGen[^"]*">/) {
            if ($copying) {


                # 配列の末尾から空行を削除
                while (@lines_to_copy && $lines_to_copy[-1] =~ /^\s*$/) {
                    pop @lines_to_copy;
                }

                # 配列を逆順にする
                my @reversed_lines = reverse @lines_to_copy;

                # 逆順にした配列から1回だけマッチする </div> タグを削除
                if (@reversed_lines && $reversed_lines[0] =~ m|</div>|) {
                    shift @reversed_lines;  # 逆順配列から最初の要素（元の配列の末尾）を削除
                }

                # 再び元の順序に戻す
                @lines_to_copy = reverse @reversed_lines;

                # コピー中に次のidGenタグが見つかったらコピーを終了してファイルに書き出す
                open(my $template_fh, '<:encoding(UTF-8)', $current_template) or die "Cannot open file $current_template: $!";

                # xhtml出力のサブルーチンへ　-----＞＞
                write_to_file($file_counter, \@lines_to_copy, $template_fh, \@output_filenames, \@id_to_filename);

                close($template_fh);
                $file_counter++;
                @lines_to_copy = ();  # 配列をクリア
            }

            # テンプレートファイルを選択する
            if ($line =~ m/<div class="_idGenObject[^"]*">/) {
                $current_template = "01_templates/p-gazou.xhtml";
            } else {
                $current_template = "01_templates/p-text.xhtml";
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

    # 最後のコピー対象もファイルに書き出す
    if ($copying) {
        # 配列の末尾から空行を削除
        while (@lines_to_copy && $lines_to_copy[-1] =~ /^\s*$/) {
            pop @lines_to_copy;
        }

        # 配列を逆順にする
        my @reversed_lines = reverse @lines_to_copy;

        # 逆順にした配列から1回だけマッチする </div> タグを削除
        if (@reversed_lines && $reversed_lines[0] =~ m|</div>|) {
            shift @reversed_lines;  # 逆順配列から最初の要素（元の配列の末尾）を削除
        }

        # 再び元の順序に戻す
        @lines_to_copy = reverse @reversed_lines;

        open(my $template_fh, '<:encoding(UTF-8)', $current_template) or die "Cannot open file $current_template: $!";
        write_to_file($file_counter, \@lines_to_copy, $template_fh, \@output_filenames);
        close($template_fh);
    }

    # ファイルハンドルを閉じる
    close($input_fh);

    print "HTML operation end\n";
}

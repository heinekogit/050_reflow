use strict;
use warnings;
use Encode;
use utf8;
use File::Copy;

# 入力・出力ファイル
my $input_file = '04_arrange/arrange_target.xhtml';
my $output_file = '04_arrange/adjust_link_target.xhtml';

# 入力ファイルを読み込む
open my $in, '<:encoding(UTF-8)', $input_file or die "Cannot open $input_file: $!";
my @lines = <$in>;
close $in;

my $note_id = 1;
my $noteref_id = 1;

# 各行を処理
foreach my $line (@lines) {
    # <span class="noteref"> を変換
    $line =~ s{<span class="noteref">(.*?)</span>}{
        my $new_a = sprintf('<a class="noteref" href="target.xhtml#note-%03d" id="noteref-%03d">%s</a>', $noteref_id, $noteref_id, $1);
        $noteref_id++;
        $new_a;
    }ge;

    # <p class="note"> を変換
    $line =~ s{<p class="note">(.*?)</p>}{
        my $new_a = sprintf('<a class="note" href="target.xhtml#noteref-%03d" id="note-%03d">%s</a>', $note_id, $note_id, $1);
        $note_id++;
        "<p class=\"note\">$new_a</p>";
    }ge;

    # 行頭のタブを削除
    $line =~ s/^\t//;
    $line =~ s/^\s+//;
}

# 出力ファイルのタイトルを変更
foreach my $line (@lines) {
    $line =~ s/arrange_link_targetのhtml/adjust_link_targetのhtml/;
}

# 出力ファイルに保存
open my $out, '>:encoding(UTF-8)', $output_file or die "Cannot open $output_file: $!";
print $out @lines;
close $out;

print "Processing complete. Output saved to $output_file\n";

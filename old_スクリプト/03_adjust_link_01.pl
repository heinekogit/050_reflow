use strict;
use warnings;
use Encode;
use utf8;
use File::Copy;

# 入力ファイルと出力ファイルのパスを定義
my $input_file = '04_arrange/arrange_target.xhtml';
my $output_file = '04_arrange/linked_target.xhtml';

# 入力ファイルを開く
open my $in, '<:encoding(UTF-8)', $input_file or die "Cannot open $input_file: $!";
# 出力ファイルを開く
open my $out, '>:encoding(UTF-8)', $output_file or die "Cannot open $output_file: $!";

my $note_id = 1;
my $noteref_id = 1;

while (<$in>) {
    my $content = $_;

    # <span class="noteref"> を <a> に変換
    $content =~ s|<span class="noteref">(.*?)</span>|'<a class="noteref" id="noteref-' . sprintf("%03d", $noteref_id) . '" href="linked_target.xhtml#note-' . sprintf("%03d", $noteref_id++) . '">' . $1 . '</a>'|ge;

    # <p class="note"> を <a> に変換
    $content =~ s|<p class="note">(.*?)</p>|'<a class="note" id="note-' . sprintf("%03d", $note_id) . '" href="linked_target.xhtml#noteref-' . sprintf("%03d", $note_id++) . '">' . $1 . '</a>'|ge;

    print $out $content;
}

# ファイルを閉じる
close $in;
close $out;

print "Processing complete. Output saved to $output_file\n";
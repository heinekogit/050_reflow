use strict;
use warnings;
use Encode;
use utf8;
use File::Copy;
use HTML::TreeBuilder;
use HTML::Element;

# 入力・出力ファイル
my $input_file = '04_arrange/arrange_target.xhtml';
my $output_file = '04_arrange/adjust_target.xhtml';

# 入力ファイルを読み込む
open my $in, '<:encoding(UTF-8)', $input_file or die "Cannot open $input_file: $!";
my $html_content = do { local $/; <$in> };
close $in;

# HTMLをパース
my $tree = HTML::TreeBuilder->new;
$tree->parse_content($html_content);

my $note_id = 1;
my $noteref_id = 1;

# <span class="noteref"> を変換
for my $span ($tree->look_down(_tag => 'span', class => 'noteref')) {
    my $new_a = HTML::Element->new('a', class => 'noteref', id => sprintf("noteref-%03d", $noteref_id), 
                                   href => "linked_target.xhtml#note-" . sprintf("%03d", $noteref_id++));
    $new_a->push_content($span->content_list);
    $span->replace_with($new_a);
}

# <p class="note"> を変換
for my $p ($tree->look_down(_tag => 'p', class => 'note')) {
    my $new_a = HTML::Element->new('a', class => 'note', id => sprintf("note-%03d", $note_id), 
                                   href => "linked_target.xhtml#noteref-" . sprintf("%03d", $note_id++));
    $new_a->push_content($p->content_list);
#    $p->replace_with($new_a);
    $p->replace_with("\n", $new_a);
}

# 変換後のHTMLを取得
my $new_html = $tree->as_HTML('<>&', '  ', {});
$tree = $tree->delete;  # メモリ解放

# 行頭のタブを削除
$new_html =~ s/^\t</</gm;
$new_html =~ s/^\s+//gm;

# 出力ファイルに保存
open my $out, '>:encoding(UTF-8)', $output_file or die "Cannot open $output_file: $!";
print $out $new_html;
close $out;

print "Processing complete. Output saved to $output_file\n";

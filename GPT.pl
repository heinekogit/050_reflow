use strict;
use warnings;
use File::Basename;

my %footnote_links_to_pages;  # 脚注リンクとページ対応を格納

# 既存の処理: XHTML 分割処理
foreach my $counter (0 .. $#split_contents) {
    my $current_index = sprintf("p-%03d.xhtml", $counter + 1);
    my @lines_to_copy = @{$split_contents[$counter]};
    
    # noteref の検索と ID 取得
    foreach my $line (@lines_to_copy) {
        if ($line =~ /<a[^>]+?href="#[^"]+"[^>]*?class="noteref"[^>]*?id="([^"]+)"/i) {
            my $note_id = $1;
            $footnote_links_to_pages{$note_id} = $current_index;
        }
        elsif ($line =~ /<a[^>]+?href="#[^"]+"[^>]*?class="note"[^>]*?id="([^"]+)"/i) {
            my $note_id = $1;
            $footnote_links_to_pages{$note_id} = $current_index;
        }
    }
    
    # 分割ファイルの書き出し
    write_to_file($counter, \@lines_to_copy, $template_fh, $counter, \%footnote_links_to_pages);
}

# ここで `p-annotation.xhtml` の処理を行う（別ファイルとして実装済み）
if ($koumoku_content[4] eq 'yes') {
    process_annotation_page(\%footnote_links_to_pages);
}

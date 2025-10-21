#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open IO => ':utf8';

use File::Basename qw(fileparse);
use File::Path qw(make_path);
use Getopt::Long;

# ======== 既定パス（あなたの指定） ========
my $ROOT    = 'C:\Users\tomoki.kawakubo\050_reflow';
my $RULES   = $ROOT . '\\03_setup\toolbox\rules\word_left_patterns.tsv';
my $TARGET  = $ROOT . '\\03_setup\word.html';
my $SUFFIX  = '_norm';       # 出力ファイル名のサフィックス
my $ENC     = 'utf-8';       # HTMLエンコーディング想定（暫定）
my $DRYRUN  = 0;
my $VERBOSE = 0;

GetOptions(
  'rules=s'  => \$RULES,
  'target=s' => \$TARGET,
  'suffix=s' => \$SUFFIX,
  'encoding=s' => \$ENC,
  'dry-run!' => \$DRYRUN,
  'verbose!' => \$VERBOSE,
) or die "Invalid options\n";

# ======== 変換ルール読込（TSV：pattern \t replacement \t flags \t #comment） ========
sub load_rules {
  my ($path) = @_;
  open my $fh, '<', $path or die "[ERR] Cannot open rules: $path\n";
  my @rules;
  my $lineno = 0;
  while (my $line = <$fh>) {
    $lineno++;
    chomp $line;
    next if $line =~ /^\s*$/;      # blank
    next if $line =~ /^\s*#/;      # comment
    my ($pat,$rep,$flags,$comment) = split(/\t/, $line, 4);
    unless (defined $rep) {
      warn "[WARN] Skip invalid rule at line $lineno (missing columns)\n";
      next;
    }
    $flags  //= 'g';
    $comment//= '';
    push @rules, { n=>$lineno, pat=>$pat, rep=>$rep, flags=>$flags, comment=>$comment };
  }
  close $fh;
  return \@rules;
}

# ======== 置換適用 ========
sub apply_rules {
  my ($html, $rules) = @_;
  my $total_changed = 0;
  my @log;

  RULE: for my $r (@$rules) {
    my ($n,$pat,$rep,$flags) = @$r{qw/n pat rep flags/};

    # s{}{}flags を eval で適用（TSVの正規表現をそのまま使えるように）
    my $code = "\$html =~ s{$pat}{$rep}$flags;";
    my $changed = eval $code;
    if ($@) {
      push @log, sprintf("[ERR] rule line %d eval error: %s", $n, $@);
      next RULE;
    }
    $total_changed += ($changed // 0);
    push @log, sprintf("[OK ] L%-4d  hits=%d  %s", $n, ($changed // 0), ($r->{comment}||''))
      if $VERBOSE;
  }
  return ($html, $total_changed, \@log);
}

# ======== 対象ファイル列挙 ========
sub list_html_targets {
  my ($path) = @_;

  if (-d $path) {
    opendir(my $dh, $path) or die "[ERR] Cannot open target dir: $path\n";
    my @files = grep { /\.(?:html?|HTML?)$/ && -f "$path\\$_" } readdir($dh);
    closedir $dh;
    return [ map { "$path\\$_" } @files ];
  }

  if (-f $path) {
    die "[ERR] Target file is not HTML: $path\n" unless $path =~ /\.(?:html?|HTML?)$/;
    return [ $path ];
  }

  die "[ERR] Target not found: $path\n";
}

# ======== メイン ========
die "[ERR] Rules not found: $RULES\n"  unless -f $RULES;
my $rules = load_rules($RULES);
print "[INFO] Loaded rules: ", scalar(@$rules), " from $RULES\n";

my $files = list_html_targets($TARGET);
if (!@$files) {
  print "[INFO] No HTML files in $TARGET\n";
  exit 0;
}
print "[INFO] Found ", scalar(@$files), " files in $TARGET\n";

my $grand_changes = 0;
for my $infile (@$files) {
  # 読み込み
  open my $in, '<:encoding(UTF-8)', $infile or die "[ERR] Cannot read $infile\n";
  my $html = do { local $/; <$in> };
  close $in;

  my ($name,$path,$suffix) = fileparse($infile, qr/\.[^.]*/);
  my $outfile = $path . $name . $SUFFIX . '.html';

  my ($out_html, $changed, $log) = apply_rules($html, $rules);
  $grand_changes += $changed;

  if ($VERBOSE) {
    print "[FILE] $infile\n";
    print "$_\n" for @$log;
  }
  if ($DRYRUN) {
    print "[DRY] $infile  (changes: $changed)  → SKIPPED write\n";
  } else {
    open my $out, '>:encoding(UTF-8)', $outfile or die "[ERR] Cannot write $outfile\n";
    print {$out} $out_html;
    close $out;
    print "[OUT ] $outfile  (changes: $changed)\n";
  }
}

print "[DONE] Total replacements: $grand_changes\n";
exit 0;

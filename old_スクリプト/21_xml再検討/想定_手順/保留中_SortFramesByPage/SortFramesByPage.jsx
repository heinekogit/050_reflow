var doc = app.activeDocument;
var frames = doc.textFrames.everyItem().getElements();

// ページ順にソート
frames.sort(function (a, b) {
    return a.parentPage.index - b.parentPage.index;
});

// XML形式の出力を構築
var xmlOutput = '<?xml version="1.0" encoding="UTF-8"?>\n<root>\n';

// 各ページごとに処理
for (var i = 0; i < frames.length; i++) {
    var frame = frames[i];
    try {
        if (frame.contents && frame.contents.length > 0) { // 空フレームをスキップ
            var pageNumber = frame.parentPage ? frame.parentPage.name : "NoPage";
            var sanitizedContents = sanitizeText(frame.contents);

            // ページ内での章や段落の見出しを検出（仮に<h1>や<h2>タグを想定）
            var chapterHeader = getChapterHeader(frame);  // この関数を作成して見出しを抽出

            xmlOutput += "  <page number=\"" + pageNumber + "\">\n";
            
            // 見出しがある場合は追加
            if (chapterHeader) {
                xmlOutput += "    <chapter>" + chapterHeader + "</chapter>\n";
            }
            
            xmlOutput += "    <content>" + sanitizedContents + "</content>\n";
            xmlOutput += "  </page>\n";
        }
    } catch (e) {
        alert("エラーが発生しました: " + e.message + "\nフレームをスキップします。");
    }
}

xmlOutput += '</root>';

// ファイルに保存
var outputFile = File(Folder.myDocuments + "/Output.xml");
if (outputFile.open("w", "TEXT", "???")) { // UTF-8エンコーディングを指定
    outputFile.encoding = 'UTF-8'; // 明示的にUTF-8で設定
    outputFile.write(xmlOutput);
    outputFile.close();
    alert("XML形式で保存しました: " + outputFile.fsName);
} else {
    alert("エラー: ファイルを開けません");
}

// XML用に特殊文字をエスケープする関数
function sanitizeText(text) {
    return text.replace(/[\u0000-\u001F\u007F]/g, "") // 制御文字を削除
               .replace(/&/g, "&amp;")
               .replace(/</g, "&lt;")
               .replace(/>/g, "&gt;")
               .replace(/"/g, "&quot;")
               .replace(/'/g, "&apos;");
}

// 章や見出しをフレームから取得する関数
function getChapterHeader(frame) {
    var contents = frame.contents;
    var headerMatch = contents.match(/^(第.*章[^\n]+)/);  // 章や見出しを正規表現で検出
    if (headerMatch) {
        return headerMatch[1];  // 見出しの部分を返す
    }
    return null;  // 見出しがなければnullを返す
}

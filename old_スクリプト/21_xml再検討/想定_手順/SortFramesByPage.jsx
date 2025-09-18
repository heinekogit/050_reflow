var doc = app.activeDocument;
var frames = doc.textFrames.everyItem().getElements();

// ページ順にソート
frames.sort(function (a, b) {
    return a.parentPage.index - b.parentPage.index;
});

// XML形式の出力を構築
var xmlOutput = '<?xml version="1.0" encoding="UTF-8"?>\n<root>\n';

for (var i = 0; i < frames.length; i++) {
    var frame = frames[i];
    try {
        if (frame.contents && frame.contents.length > 0) { // 空フレームをスキップ
            var pageNumber = frame.parentPage ? frame.parentPage.name : "NoPage";
            var sanitizedContents = sanitizeText(frame.contents);
            xmlOutput += "  <page number=\"" + pageNumber + "\">\n";
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

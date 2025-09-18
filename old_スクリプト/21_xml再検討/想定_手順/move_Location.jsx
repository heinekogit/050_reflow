var doc = app.activeDocument;
var frames = doc.textFrames.everyItem().getElements();

// ページ順にソート（上から下、左から右）
frames.sort(function(a, b) {
    // 位置を基準にソートします
    var aTop = a.geometricBounds[0]; // 上端
    var bTop = b.geometricBounds[0];
    
    if (aTop === bTop) {
        return a.geometricBounds[1] - b.geometricBounds[1]; // 左端でソート
    } else {
        return aTop - bTop;
    }
});

// 新しいXMLドキュメントを作成
var xmlDoc = app.xmlDocuments.add();

// <root>ノードを作成
var rootElement = xmlDoc.xmlElements.add("root");

// テキストフレーム順にXML要素を構築
for (var i = 0; i < frames.length; i++) {
    var frame = frames[i];
    if (frame.contents && frame.contents.length > 0) { // 空フレームをスキップ
        var pageNumber = frame.parentPage ? frame.parentPage.name : "NoPage";

        // 新しいページ要素を作成
        var pageElement = rootElement.xmlElements.add("page");
        pageElement.attributes.add("number", pageNumber);

        // 新しいcontent要素を作成
        var contentElement = pageElement.xmlElements.add("content");
        contentElement.contents = frame.contents;
    }
}

// ファイルに保存
var outputFile = File(Folder.myDocuments + "/Output.xml");
if (outputFile.open("w")) {
    outputFile.write(xmlDoc.toXMLString());
    outputFile.close();
    alert("XML形式で保存しました: " + outputFile.fsName);
} else {
    alert("エラー: ファイルを開けません");
}

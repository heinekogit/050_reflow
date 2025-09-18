// スタイル名を取得して、テキストファイルに書き出すスクリプト

var doc = app.activeDocument;
var styleNames = [];
var file = File.saveDialog("スタイル名を保存するファイルを選択");

if (file != null) {
    file.open('w'); // 書き込みモードでファイルを開く

    // 段落スタイルを取得
    for (var i = 0; i < doc.paragraphStyles.length; i++) {
        styleNames.push(doc.paragraphStyles[i].name);
    }

    // 文字スタイルを取得
    for (var j = 0; j < doc.characterStyles.length; j++) {
        styleNames.push(doc.characterStyles[j].name);
    }

    // スタイル名をファイルに書き込む
    for (var k = 0; k < styleNames.length; k++) {
        file.writeln(styleNames[k]);
    }

    file.close(); // ファイルを閉じる
    alert("スタイル名の抽出が完了しました！");
} else {
    alert("ファイルの保存先を選択してください。");
}

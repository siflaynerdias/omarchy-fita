import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.LocalStorage
import Quickshell
import "Engine.js" as Engine
import "DateUtils.js" as Dates

Item {
    id: root
    property var shell: null
    property var manifest: null
    readonly property alias contentItem: canvas
    property var evaluation: ({rows: [], total: "0,00", error: ""})
    property string storageError: ""
    property int dateSortDirection: 0
    property bool ready: false
    property var history: []
    property var future: []
    property bool darkMode: true
    readonly property real tableWidth: Math.min(canvas.width - 52, 850)
    readonly property real descriptionWidth: tableWidth - 400
    property color ink: darkMode ? "#f4f7fc" : "#283747"
    property color muted: darkMode ? "#aebfd0" : "#728079"
    property color green: darkMode ? "#71dbb3" : "#167461"
    property color paper: darkMode ? "#172330" : "#e7f2fc"
    property color focusFill: darkMode ? "#2c4052" : "#edf2e9"
    property color heading: darkMode ? "#ffffff" : "#111111"
    property color errorColor: darkMode ? "#ff9098" : "#b54b47"
    function open(payload) { window.visible = true }
    function close() { persist(); window.visible = false }
    function dismiss() {
        close();
        if (shell && typeof shell.hide === "function") shell.hide("silfayner.fita");
        else Qt.quit();
    }
    function snapshot() {
        var rows = [];
        for (var i = 0; i < tape.count; i++) {
            var r = tape.get(i); rows.push({op: r.op, value: r.value, note: r.note, dateText: r.dateText || ""});
        }
        return rows;
    }
    function checkpoint() { history = history.concat([snapshot()]).slice(-100); future = [] }
    function resetTape() {
        checkpoint();
        restore([{op: "+", value: "", note: "", dateText: ""}]);
        persist();
        Qt.callLater(function() {
            list.positionViewAtBeginning(); list.forceLayout();
            var item = list.itemAtIndex(0); if (item) item.focusValue();
        });
    }
    function restore(rows) { dateSortDirection = 0; tape.clear(); rows.forEach(function(r) { tape.append({op: r.op, value: r.value, note: r.note, dateText: r.dateText || ""}) }); changed() }
    function undo() {
        if (!history.length) return;
        future = future.concat([snapshot()]); var rows = history[history.length - 1];
        history = history.slice(0, -1); restore(rows);
    }
    function redo() {
        if (!future.length) return;
        history = history.concat([snapshot()]); var rows = future[future.length - 1];
        future = future.slice(0, -1); restore(rows);
    }
    function changed() { evaluation = Engine.calculate(snapshot()); if (ready) saveTimer.restart() }
    function edit(index, key, value) {
        if (tape.get(index)[key] === value) return;
        checkpoint(); dateSortDirection = 0; tape.setProperty(index, key, value); changed();
    }
    function sortByDate() {
        checkpoint();
        var direction = dateSortDirection === 1 ? -1 : 1;
        restore(Dates.sortRows(snapshot(), direction));
        dateSortDirection = direction;
    }
    function add(op) {
        checkpoint(); tape.append({op: op, value: "", note: "", dateText: ""}); changed();
        Qt.callLater(function() { list.positionViewAtEnd(); list.forceLayout(); var item = list.itemAtIndex(tape.count - 1); if (item) item.focusValue() });
    }
    function insertBelow(index) {
        checkpoint();
        tape.insert(index + 1, {op: "+", value: "", note: "", dateText: ""}); changed();
        Qt.callLater(function() {
            list.positionViewAtIndex(index + 1, ListView.Contain); list.forceLayout();
            var item = list.itemAtIndex(index + 1); if (item) item.focusValue();
        });
    }
    component PastelButton: Button {
        id: control
        property color tint: "#abe8ce"
        property int labelSize: 14
        implicitHeight: 36
        implicitWidth: Math.max(42, contentItem.implicitWidth + 24)
        opacity: enabled ? 1 : 0.45
        contentItem: Text {
            text: control.text; color: "#24435a"; font.family: "Liberation Sans"; font.pixelSize: control.labelSize; font.bold: true
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        }
        background: Item {
            RectangularShadow { anchors.fill: parent; offset: Qt.vector2d(0, 4); radius: 10; blur: 12; spread: 1; color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.85) }
            Rectangle { anchors.fill: parent; radius: 10; color: control.down ? Qt.darker(control.tint, 1.1) : control.hovered ? Qt.lighter(control.tint, 1.05) : control.tint; border.width: control.activeFocus ? 2 : 0; border.color: "#4d80a2" }
        }
    }
    function db() { return LocalStorage.openDatabaseSync("silfayner-fita", "1.0", "Fita calculator", 1000000) }
    function persist() {
        if (!ready) return;
        try {
            var data = JSON.stringify({title: title.text, darkMode: darkMode, rows: snapshot()});
            db().transaction(function(tx) { tx.executeSql("CREATE TABLE IF NOT EXISTS tape (id INTEGER PRIMARY KEY, data TEXT)"); tx.executeSql("INSERT OR REPLACE INTO tape VALUES (1, ?)", [data]); });
            storageError = "";
        } catch (e) { storageError = "Não foi possível salvar: " + e.message }
    }
    Component.onCompleted: {
        try {
            db().transaction(function(tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS tape (id INTEGER PRIMARY KEY, data TEXT)");
                var result = tx.executeSql("SELECT data FROM tape WHERE id = 1");
                if (result.rows.length) {
                    var saved = JSON.parse(result.rows.item(0).data);
                    root.darkMode = saved.darkMode !== undefined ? saved.darkMode : true;
                    title.text = (saved.title === "Minha fita" || saved.title === "CALCULATOR") ? "CALCULATOR - DATE | VALUE | DESCRIPTION" : saved.title; saved.rows.forEach(function(r) { tape.append({op: r.op, value: r.value, note: r.note, dateText: r.dateText || ""}) });
                }
            });
        } catch (e) { storageError = "Não foi possível abrir a fita: " + e.message }
        if (!tape.count) tape.append({op: "+", value: "", note: "", dateText: ""});
        ready = true; changed();
    }
    Timer { id: saveTimer; interval: 300; onTriggered: root.persist() }
    ListModel { id: tape }
    FloatingWindow {
        id: window
        visible: false
        title: "CALCULATOR - DATE | VALUE | DESCRIPTION"
        implicitWidth: 850; implicitHeight: 700
        minimumSize: Qt.size(760, 440)
        color: root.paper
        onClosed: root.dismiss()
        Shortcut { sequence: "Ctrl+Z"; onActivated: root.undo() }
        Shortcut { sequence: "Ctrl+Shift+Z"; onActivated: root.redo() }
        Shortcut { sequence: "Ctrl+Return"; onActivated: root.add("=") }
        Shortcut { sequence: "Ctrl+S"; onActivated: root.persist() }
        Rectangle {
            id: canvas
            anchors.fill: parent
            color: root.paper
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 26; spacing: 16
            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: title; text: "CALCULATOR - DATE | VALUE | DESCRIPTION"; Layout.fillWidth: true
                    font.pixelSize: 23; font.bold: true; color: root.ink
                    background: Item {}
                    onTextEdited: saveTimer.restart()
                }
                PastelButton {
                    text: root.darkMode ? "☀ Light" : "☾ Dark"
                    tint: "#b8ccff"
                    onClicked: { root.darkMode = !root.darkMode; root.persist() }
                }
                Label { text: "FITA / 01"; color: root.muted; font.letterSpacing: 2 }
            }
            GridLayout {
                columns: 7; columnSpacing: 12; rowSpacing: 12
                PastelButton { text: "+ Row"; onClicked: root.add("+") }
                PastelButton { tint: "#b8ccff"; text: "= Subtotal"; onClicked: root.add("=") }
                PastelButton { tint: "#ffd49e"; text: "New calculation"; onClicked: { root.add("novo"); root.add("+") } }
                PastelButton { tint: "#dec5f6"; labelSize: 28; text: "↶"; enabled: root.history.length > 0; onClicked: root.undo(); ToolTip.text: "Undo"; ToolTip.visible: hovered }
                PastelButton { tint: "#dec5f6"; labelSize: 28; text: "↷"; enabled: root.future.length > 0; onClicked: root.redo(); ToolTip.text: "Redo"; ToolTip.visible: hovered }
                PastelButton { tint: "#a5dfe9"; text: "Copy"; onClicked: {
                    var rows = root.snapshot(); var output = title.text + "\n\n";
                    rows.forEach(function(r, i) { output += r.op === "novo" ? "\n" + r.note + "\n" : r.op + "\t" + r.dateText + "\t" + (r.op === "=" ? root.evaluation.rows[i].text : r.value) + "\t" + r.note + "\n" });
                    clipboard.text = output; clipboard.selectAll(); clipboard.copy();
                } }
                PastelButton {
                    tint: "#ffb9c1"; text: "Reset"
                    onClicked: root.resetTape()
                    ToolTip.text: "Clear all calculations · Ctrl+Z to undo"
                    ToolTip.visible: hovered
                }
            }
            RowLayout {
                Layout.topMargin: 32
                Layout.preferredWidth: root.tableWidth
                Layout.maximumWidth: root.tableWidth
                spacing: 8
                Label { text: "OP."; Layout.minimumWidth: 28; Layout.maximumWidth: 28; Layout.preferredWidth: 28; color: root.heading; font.bold: true }
                Button {
                    Layout.minimumWidth: 146; Layout.maximumWidth: 146; Layout.preferredWidth: 146
                    leftPadding: 6
                    text: "DATE " + (root.dateSortDirection === 1 ? "↑" : root.dateSortDirection === -1 ? "↓" : "↕")
                    Accessible.name: "Sort by date " + (root.dateSortDirection === 1 ? "descending" : "ascending")
                    contentItem: Text { text: parent.text; color: root.heading; font.bold: true; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 4; color: parent.hovered || parent.activeFocus ? root.focusFill : "transparent" }
                    onClicked: root.sortByDate()
                    ToolTip.visible: hovered
                    ToolTip.text: "Toggle date order · Undated first · Keeps calculations and subtotals separate"
                }
                Label { text: "VALUE"; Layout.minimumWidth: 166; Layout.maximumWidth: 166; Layout.preferredWidth: 166; horizontalAlignment: Text.AlignRight; color: root.heading; font.bold: true }
                Label { text: "DESCRIPTION"; Layout.minimumWidth: root.descriptionWidth; Layout.maximumWidth: root.descriptionWidth; Layout.preferredWidth: root.descriptionWidth; leftPadding: 6; color: root.heading; font.bold: true }
                Item { Layout.minimumWidth: 28; Layout.maximumWidth: 28; Layout.preferredWidth: 28 }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#7eabc7" }
            ListView {
                id: list; Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; model: tape; spacing: 2
                ScrollBar.vertical: ScrollBar {}
                delegate: Column {
                    id: row
                    required property int index
                    required property string op
                    required property string value
                    required property string note
                    required property string dateText
                    width: root.tableWidth; spacing: 2
                    property string issue: root.evaluation.rows[index] ? root.evaluation.rows[index].error : ""
                    function focusValue() { amount.forceActiveFocus() }
                    Rectangle { width: parent.width; height: row.op === "=" || row.op === "novo" ? 1 : 0; color: "#7eabc7" }
                    RowLayout {
                        width: parent.width; height: 24; spacing: 8
                        Item {
                            Layout.minimumWidth: 28; Layout.maximumWidth: 28; Layout.preferredWidth: 28; Layout.preferredHeight: 24
                            Button {
                                id: operation
                                width: 24; height: 24
                                property color tint: row.op === "+" ? "#36a875" : row.op === "−" ? "#e2626b" : "#bed6f4"
                                Accessible.name: "Operation " + row.op
                                contentItem: Text { text: row.op === "novo" ? "↳" : row.op; font.family: "Liberation Sans"; font.pixelSize: 18; font.bold: true; color: row.op === "+" || row.op === "−" ? "white" : "#284b68"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Item {
                                    RectangularShadow { anchors.fill: parent; offset: Qt.vector2d(0, 2); radius: 12; blur: 8; spread: 0; color: Qt.rgba(operation.tint.r, operation.tint.g, operation.tint.b, 0.65) }
                                    Rectangle { anchors.fill: parent; radius: width / 2; color: operation.tint; border.width: operation.activeFocus ? 2 : 0; border.color: "#24435a" }
                                }
                                onClicked: operationMenu.open()
                                Menu {
                                    id: operationMenu
                                    y: operation.height
                                    Repeater {
                                        model: ["+", "−", "×", "÷", "=", "novo"]
                                        MenuItem { required property string modelData; text: modelData === "novo" ? "New calculation" : modelData; onTriggered: root.edit(row.index, "op", modelData) }
                                    }
                                }
                            }
                        }
                        DateField {
                            id: dateEditor
                            Layout.minimumWidth: 146; Layout.maximumWidth: 146; Layout.preferredWidth: 146; Layout.preferredHeight: 24
                            darkMode: root.darkMode
                            value: row.dateText
                            onEdited: function(value) { root.edit(row.index, "dateText", value) }
                            onAccepted: root.insertBelow(row.index)
                        }
                        TextField {
                            id: amount
                            Layout.minimumWidth: 166; Layout.maximumWidth: 166; Layout.preferredWidth: 166; Layout.preferredHeight: 24; topPadding: 0; bottomPadding: 0
                            text: row.op === "=" ? (root.evaluation.rows[row.index] || {}).text || "0,00" : row.value
                            readOnly: row.op === "=" || row.op === "novo"
                            horizontalAlignment: TextInput.AlignRight
                            font.family: "Liberation Sans"; font.pixelSize: 20; font.bold: row.op === "="
                            color: row.issue || row.op === "−" ? root.errorColor : row.op === "=" ? root.green : root.ink
                            placeholderText: row.op === "novo" ? "" : "0,00"
                            background: Rectangle { color: parent.activeFocus ? root.focusFill : "transparent"; radius: 4 }
                            onTextEdited: root.edit(row.index, "value", text)
                            onEditingFinished: {
                                if (!readOnly && text.trim()) {
                                    try { root.edit(row.index, "value", Engine.format(Engine.parse(text))) } catch (e) {}
                                }
                            }
                            onAccepted: root.insertBelow(row.index)
                        }
                        TextField {
                            id: description
                            Component.onCompleted: cursorPosition = 0
                            onActiveFocusChanged: { if (!activeFocus) cursorPosition = 0 }
                            Layout.minimumWidth: root.descriptionWidth; Layout.maximumWidth: root.descriptionWidth; Layout.preferredWidth: root.descriptionWidth; Layout.preferredHeight: 24; leftPadding: 6; topPadding: 0; bottomPadding: 0; text: row.note; color: root.ink; font.family: "Liberation Sans"; font.pixelSize: 16; clip: true; selectByMouse: true
                            background: Rectangle { color: parent.activeFocus ? root.focusFill : "transparent"; radius: 4 }
                            onTextEdited: root.edit(row.index, "note", text)
                            onAccepted: root.insertBelow(row.index)
                        }
                        ToolButton { text: "×"; Layout.minimumWidth: 28; Layout.maximumWidth: 28; Layout.preferredWidth: 28; Layout.preferredHeight: 24; contentItem: Text { text: "×"; color: "#cf354b"; font.pixelSize: 22; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } onClicked: { root.checkpoint(); tape.remove(row.index); root.changed() } ToolTip.text: "Delete row"; ToolTip.visible: hovered }
                    }
                    Label { visible: row.issue !== ""; text: row.issue; color: root.errorColor; leftPadding: 36; font.pixelSize: 12 }
                    Item { width: 1; height: 24; visible: row.op === "=" && row.index < tape.count - 1 }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#7eabc7" }
            Label {
                text: root.storageError || "Salvamento automático · Ctrl+Enter: subtotal"
                color: root.storageError ? root.errorColor : root.muted
                font.pixelSize: 11; wrapMode: Text.Wrap; Layout.fillWidth: true
            }
        }
        }
        TextEdit { id: clipboard; visible: false }
    }
}

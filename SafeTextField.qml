import QtQuick

// Clipboard-free text editor. QtQuick.TextInput automatically queries the
// native clipboard whenever it changes, so this component deliberately uses
// keyboard editing on a plain Item instead.
Item {
    id: root

    property string text: ""
    property string placeholderText: ""
    property int maximumLength: 32767
    property bool readOnly: false
    property color color: "#283747"
    property color placeholderColor: "#8090a0"
    property color backgroundColor: "transparent"
    property font font: Qt.font({ family: "Liberation Sans", pixelSize: 16 })
    property enumeration horizontalAlignment: Text.AlignLeft
    property alias hovered: mouse.containsMouse
    property int cursorPosition: 0
    property string editText: text

    signal textEdited(string value)
    signal accepted()
    signal editingFinished()

    implicitHeight: 24
    implicitWidth: 80
    focus: false
    activeFocusOnTab: true

    onTextChanged: {
        if (!activeFocus) {
            editText = text;
            cursorPosition = Math.min(editText.length, cursorPosition);
        }
    }
    onActiveFocusChanged: {
        if (activeFocus) {
            editText = text;
            cursorPosition = Math.min(editText.length, cursorPosition);
        } else {
            editText = text;
            editingFinished();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.backgroundColor
        radius: 4
    }

    Text {
        id: display
        anchors.fill: parent
        leftPadding: 6
        rightPadding: 6
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: root.horizontalAlignment
        color: root.editText.length ? root.color : root.placeholderColor
        font: root.font
        text: root.editText.length ? root.editText : root.placeholderText
        elide: Text.ElideRight
        clip: true
    }

    Rectangle {
        visible: root.activeFocus && !root.readOnly
        x: Math.min(root.width - 2, 6 + display.contentWidth)
        y: 3
        width: 1
        height: Math.max(1, root.height - 6)
        color: root.color
    }

    Keys.onPressed: function(event) {
        if (root.readOnly) return;

        var next = root.editText;
        var position = root.cursorPosition;
        var handled = true;

        if (event.key === Qt.Key_Left) {
            root.cursorPosition = Math.max(0, position - 1);
        } else if (event.key === Qt.Key_Right) {
            root.cursorPosition = Math.min(next.length, position + 1);
        } else if (event.key === Qt.Key_Home) {
            root.cursorPosition = 0;
        } else if (event.key === Qt.Key_End) {
            root.cursorPosition = next.length;
        } else if (event.key === Qt.Key_Backspace && position > 0) {
            root.editText = next.slice(0, position - 1) + next.slice(position);
            root.cursorPosition = position - 1;
        } else if (event.key === Qt.Key_Delete && position < next.length) {
            root.editText = next.slice(0, position) + next.slice(position + 1);
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.accepted();
            root.editingFinished();
        } else if (!event.modifiers && event.text && event.text.length > 0 && next.length < root.maximumLength) {
            var room = root.maximumLength - next.length;
            var inserted = event.text.slice(0, room);
            root.editText = next.slice(0, position) + inserted + next.slice(position);
            root.cursorPosition = position + inserted.length;
        } else {
            handled = false;
        }

        if (handled) {
            root.textEdited(root.editText);
            event.accepted = true;
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        onClicked: {
            root.forceActiveFocus();
            root.cursorPosition = root.editText.length;
        }
    }
}

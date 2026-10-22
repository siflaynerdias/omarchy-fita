import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "DateUtils.js" as Dates

RowLayout {
    id: root
    property string value: ""
    property bool darkMode: false
    readonly property color ink: darkMode ? "#f4f7fc" : "#283747"
    readonly property color focusFill: darkMode ? "#2c4052" : "#edf2e9"
    readonly property alias input: field
    signal edited(string value)
    signal accepted()
    spacing: 2
    function openCalendar() {
        var selected = Dates.parse(root.value) || new Date();
        calendar.year = selected.getFullYear(); calendar.month = selected.getMonth(); calendar.open();
    }
    function selectDate(date) {
        root.edited(Dates.format(date));
        calendar.close(); field.forceActiveFocus();
    }
    SafeTextField {
        id: field
        objectName: "dateInput"
        Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 118; Layout.preferredHeight: 24
        text: root.value
        font.family: "Liberation Sans"; font.pixelSize: 16
        maximumLength: 10
        clip: true
        backgroundColor: field.activeFocus ? root.focusFill : "transparent"
        color: text && !Dates.parse(text) ? (root.darkMode ? "#ff9098" : "#b54b47") : root.ink
        Accessible.name: "Date, day month and year"
        onTextEdited: root.edited(value)
        onEditingFinished: {
            var normalized = Dates.normalize(editText);
            if (normalized !== editText) root.edited(normalized);
        }
        onAccepted: { if (!editText || Dates.parse(Dates.normalize(editText))) root.accepted() }
    }
    ToolButton {
        Layout.minimumWidth: 26; Layout.maximumWidth: 26; Layout.preferredWidth: 26; Layout.preferredHeight: 24
        Accessible.name: "Open calendar"
        contentItem: Text { text: "▦"; font.pixelSize: 22; color: root.darkMode ? "#a5d7ff" : "#316a95"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        onClicked: root.openCalendar()
    }
    Popup {
        id: calendar
        objectName: "dateCalendar"
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 330; padding: 16
        modal: true; focus: true
        palette.text: root.ink
        palette.windowText: root.ink
        palette.buttonText: root.ink
        palette.button: root.darkMode ? "#30465b" : "#d5e7fa"
        property int year: new Date().getFullYear()
        property int month: new Date().getMonth()
        function moveMonth(delta) {
            var next = new Date(year, month + delta, 1, 12);
            if (next.getFullYear() < 1000 || next.getFullYear() > 9999) return;
            year = next.getFullYear(); month = next.getMonth();
        }
        background: Rectangle { color: root.darkMode ? "#223344" : "#f4f9ff"; radius: 16; border.color: "#7eabc7" }
        contentItem: ColumnLayout {
            spacing: 10
            RowLayout {
                ToolButton { text: "‹"; font.pixelSize: 24; Accessible.name: "Previous month"; onClicked: calendar.moveMonth(-1) }
                Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.locale("en_GB").standaloneMonthName(calendar.month) + " " + calendar.year; color: root.ink; font.bold: true }
                ToolButton { text: "›"; font.pixelSize: 24; Accessible.name: "Next month"; onClicked: calendar.moveMonth(1) }
            }
            GridLayout {
                columns: 7; columnSpacing: 3; rowSpacing: 3
                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    Label { required property string modelData; text: modelData; Layout.preferredWidth: 39; horizontalAlignment: Text.AlignHCenter; color: root.darkMode ? "#afc9df" : "#52718b"; font.bold: true }
                }
                Repeater {
                    model: 42
                    Button {
                        id: dayButton
                        required property int index
                        readonly property date day: Dates.cell(calendar.year, calendar.month, index)
                        readonly property bool selected: root.value === Dates.format(day)
                        Layout.preferredWidth: 39; Layout.preferredHeight: 34
                        enabled: day.getFullYear() >= 1000 && day.getFullYear() <= 9999
                        Accessible.name: Dates.format(day)
                        contentItem: Text { text: dayButton.day.getDate(); color: dayButton.selected ? "white" : dayButton.day.getMonth() === calendar.month ? root.ink : "#91a4b5"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: 9; color: dayButton.selected ? "#36a875" : dayButton.hovered ? root.focusFill : "transparent"; border.width: dayButton.activeFocus || Dates.format(dayButton.day) === Dates.format(new Date()) ? 1 : 0; border.color: "#36a875" }
                        onClicked: root.selectDate(day)
                    }
                }
            }
            RowLayout {
                Button { text: "Today"; onClicked: root.selectDate(new Date()) }
                Item { Layout.fillWidth: true }
                Button { text: "Clear"; onClicked: { root.edited(""); calendar.close(); field.forceActiveFocus() } }
            }
        }
    }
}

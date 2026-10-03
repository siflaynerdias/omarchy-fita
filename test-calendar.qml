import QtQuick
import QtQuick.Controls
import Quickshell
ShellRoot {
    FloatingWindow {
        visible: true; implicitWidth: 500; implicitHeight: 480
        Rectangle {
            id: surface; anchors.fill: parent; color: "#e7f2fc"
            DateField { id: editor; width: 160; value: "02/10/2026"; onEdited: function(value) { editor.value = value } }
        }
    }
    Timer { interval: 300; running: true; onTriggered: { editor.openCalendar(); capture.start() } }
    Timer { id: capture; interval: 500; onTriggered: {
        editor.selectDate(new Date(2024, 1, 29, 12));
        if (editor.value !== "29/02/2024") throw new Error("Calendar selection failed");
        editor.openCalendar(); done.start();
    } }
    Timer { id: done; interval: 300; onTriggered: { console.log("CALENDAR_OK"); Qt.quit() } }
}

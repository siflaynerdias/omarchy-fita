import QtQuick

Item {
    id: icon
    width: 22
    height: 22
    property color color: "#a5d7ff"

    // Compact calendar-days icon: cover, binding rings and day marks.
    Rectangle {
        x: 2; y: 4; width: 18; height: 16
        radius: 2
        color: "transparent"
        border.width: 1.8
        border.color: icon.color
    }
    Rectangle {
        x: 3; y: 7; width: 16; height: 2
        color: icon.color
    }
    Rectangle {
        x: 5; y: 2; width: 3; height: 6
        radius: 1.5
        color: icon.color
    }
    Rectangle {
        x: 14; y: 2; width: 3; height: 6
        radius: 1.5
        color: icon.color
    }

    Repeater {
        model: [
            {x: 5, y: 11}, {x: 10, y: 11}, {x: 15, y: 11},
            {x: 5, y: 15}, {x: 10, y: 15}, {x: 15, y: 15}
        ]
        Rectangle {
            required property var modelData
            x: modelData.x; y: modelData.y
            width: 2.5; height: 2.5
            radius: 0.7
            color: icon.color
        }
    }
}

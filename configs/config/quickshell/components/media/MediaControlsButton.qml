pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

RowLayout {
    id: root
    spacing: 2
    visible: MprisService.hasPlayer

    // Play/Pause button
    BarButton {
        id: playButton
        contentItem: playIcon
        onClicked: {
            if (MprisService.activePlayer)
                MprisService.activePlayer.isPlaying = !MprisService.activePlayer.isPlaying;
        }

        Text {
            id: playIcon
            anchors.centerIn: parent
            text: MprisService.isPlaying ? "󰏤" : "󰐎"
            font.family: Config.font
            font.pixelSize: Config.fontSizeIcon
            color: playButton.hovered ? Config.textColor : Config.textColor
        }

        QsToolTip {
            shown: playButton.hovered
            text: MprisService.isPlaying ? "Pause" : "Play"
            delay: 500
        }
    }

    // Previous button
    BarButton {
        id: prevButton
        contentItem: prevIcon
        onClicked: {
            if (MprisService.activePlayer)
                MprisService.activePlayer.previous();
        }

        Text {
            id: prevIcon
            anchors.centerIn: parent
            text: "󰒮"
            font.family: Config.font
            font.pixelSize: Config.fontSizeIcon
            color: Config.textColor
        }

        QsToolTip {
            shown: prevButton.hovered
            text: "Previous"
            delay: 500
        }
    }

    // Next button
    BarButton {
        id: nextButton
        contentItem: nextIcon
        onClicked: {
            if (MprisService.activePlayer)
                MprisService.activePlayer.next();
        }

        Text {
            id: nextIcon
            anchors.centerIn: parent
            text: "󰒭"
            font.family: Config.font
            font.pixelSize: Config.fontSizeIcon
            color: Config.textColor
        }

        QsToolTip {
            shown: nextButton.hovered
            text: "Next"
            delay: 500
        }
    }
}

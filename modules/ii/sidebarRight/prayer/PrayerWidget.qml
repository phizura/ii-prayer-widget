pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        // Header: kota + tanggal
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4

            StyledText {
                text: PrayerTimes.locationName || "Jadwal Sholat"
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: PrayerTimes.dateLabel
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }

        // Pesan status (belum ada data / error / belum dikonfigurasi)
        StyledText {
            visible: PrayerTimes.prayers.length === 0
            Layout.fillWidth: true
            Layout.margins: 4
            wrapMode: Text.Wrap
            text: PrayerTimes.statusMessage
            color: Appearance.colors.colSubtext
        }

        // Lima waktu sholat
        Repeater {
            model: PrayerTimes.prayers

            delegate: Rectangle {
                id: row
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 42
                radius: Appearance.rounding.small
                // highlight untuk waktu yang sedang dituju
                color: modelData.isNext ? Appearance.colors.colSecondaryContainer : "transparent"
                // waktu yang sudah lewat diredupkan
                opacity: modelData.isPassed ? 0.5 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    StyledText {
                        text: row.modelData.label
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.bold: row.modelData.isNext
                        color: row.modelData.isNext ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        visible: row.modelData.isNext
                        text: PrayerTimes.countdownText
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSecondaryContainer
                        opacity: 0.8
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: row.modelData.time
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.bold: row.modelData.isNext
                        color: row.modelData.isNext ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

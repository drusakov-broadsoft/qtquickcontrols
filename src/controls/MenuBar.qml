/****************************************************************************
**
** Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the Qt Quick Controls module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Digia Plc and its Subsidiary(-ies) nor the names
**     of its contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.0
import QtQuick.Controls.Private 1.0
import "Styles/Settings.js" as Settings

/*!
    \qmltype MenuBar
    \inqmlmodule QtQuick.Controls 1.0
    \ingroup applicationwindow
    \inherits Item
    \brief The MenuBar item provides a horizontal menu bar.

    \code
    MenuBar {
        Menu {
            text: "File"
            MenuItem { text: "Open..." }
            MenuItem { text: "Close" }
        }

        Menu {
            text: "Edit"
            MenuItem { text: "Cut" }
            MenuItem { text: "Copy" }
            MenuItem { text: "Paste" }
        }
    }
    \endcode

    \sa ApplicationWindow::menuBar
*/

MenuBarPrivate {
    id: root

    property Component style: Qt.createComponent(Settings.THEME_PATH + "/MenuBarStyle.qml", root)

    //! \internal
    __contentItem: Loader {
        id: topLoader
        sourceComponent: __menuBarComponent
        active: !root.__isNative
        focus: true
    }

    //! \internal
    property Component __menuBarComponent: Loader {
        id: menuBarLoader

        property Style __style: styleLoader.item
        property Component menuItemStyle: __style ? __style.menuItem : null

        property var control: root
        onStatusChanged: if (status === Loader.Error) console.error("Failed to load panel for", root)

        visible: status === Loader.Ready
        active: !root.isNative
        sourceComponent: __style ? __style.frame : undefined

        Loader {
            id: styleLoader
            sourceComponent: root.style
            onStatusChanged: {
                if (status === Loader.Error)
                    console.error("Failed to load Style for", root)
            }
        }

        property int openedMenuIndex: -1
        property bool preselectMenuItem: false
        property alias contentHeight: row.height

        Binding {
            // Make sure the styled menu bar is in the background
            target: menuBarLoader.item
            property: "z"
            value: menuMouseArea.z - 1
        }

        focus: openedMenuIndex !== -1

        Keys.onLeftPressed: {
            if (openedMenuIndex > 0) {
                preselectMenuItem = true
                openedMenuIndex--
            }
        }

        Keys.onRightPressed: {
            if (openedMenuIndex < root.menus.length - 1) {
                preselectMenuItem = true
                openedMenuIndex++
            }
        }

        MouseArea {
            id: menuMouseArea
            anchors.fill: parent
            hoverEnabled: true

            Row {
                id: row

                Repeater {
                    id: itemsRepeater
                    model: root.menus
                    Loader {
                        id: menuItemLoader

                        property var menuItem: modelData
                        property bool selected: menuItem.__popupVisible || itemMouseArea.pressed || menuBarLoader.openedMenuIndex === index

                        sourceComponent: menuBarLoader.menuItemStyle

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill:parent
                            hoverEnabled: true

                            onClicked: {
                                menuBarLoader.preselectMenuItem = false
                                menuBarLoader.openedMenuIndex = index
                            }
                            onPositionChanged: {
                                if ((pressed || menuMouseArea.pressed || menuBarLoader.openedMenuIndex !== -1)
                                        && menuBarLoader.openedMenuIndex !== index) {
                                    menuBarLoader.openedMenuIndex = index
                                    menuBarLoader.preselectMenuItem = false
                                }
                            }
                        }

                        Connections {
                            target: menuBarLoader
                            onOpenedMenuIndexChanged: {
                                if (menuBarLoader.openedMenuIndex === index) {
                                    menuItem.__popup(0, menuBarLoader.height, 0)
                                    if (menuBarLoader.preselectMenuItem)
                                        menuItem.__currentIndex = 0
                                } else {
                                    menuItem.__closeMenu()
                                }
                            }
                        }

                        Connections {
                            target: menuItem
                            onPopupVisibleChanged: {
                                if (!menuItem.__popupVisible && menuBarLoader.openedMenuIndex === index)
                                    menuBarLoader.openedMenuIndex = -1
                            }
                        }

                        Component.onCompleted: {
                            menuItem.__visualItem = menuItem.visualParent = menuItemLoader
                            menuItem.__menuBar = menuBarLoader
                        }
                    }
                }
            }
        }
    }
}
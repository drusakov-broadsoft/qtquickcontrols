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
import "Styles/Settings.js" as Settings

/*!
    \qmltype Menu
    \inqmlmodule QtQuick.Controls 1.0
    \ingroup applicationwindow
    \inherits MenuItem
    \brief Menu provides a menu component for use in menu bars, context menus, and other popup menus.

    \code
    Menu {
        text: "Edit"

        MenuItem {
            text: "Cut"
            shortcut: "Ctrl+X"
            onTriggered: ...
        }

        MenuItem {
            text: "Copy"
            shortcut: "Ctrl+C"
            onTriggered: ...
        }

        MenuItem {
            text: "Paste"
            shortcut: "Ctrl+V"
            onTriggered: ...
        }

        MenuSeparator { }

        Menu {
            text: "More Stuff"

            MenuItem {
                text: "Do Nothing"
            }
        }
    }
    \endcode

    \sa MenuBar, MenuItem, MenuSeparator
*/
MenuPrivate {
    id: root

    //! \internal
    property Component style: Qt.createComponent(Settings.THEME_PATH + "/MenuStyle.qml", root)

    //! \internal
    property var __menuBar: null
    //! \internal
    property int __currentIndex: -1
    //! \internal
    on__MenuClosed: __currentIndex = -1

    //! \internal
    __contentItem: Loader {
        sourceComponent: __menuComponent
        active: !root.__isNative && root.__popupVisible
        focus: true
    }

    //! \internal
    property Component __menuComponent: Loader {
        id: menuFrameLoader

        property Style __style: styleLoader.item
        property Component menuItemStyle: __style ? __style.menuItem : null

        property var control: root
        property alias contentWidth: column.width
        property alias contentHeight: column.height

        property int subMenuXPos: width + (item && item["subMenuOverlap"] || 0)

        visible: status === Loader.Ready
        sourceComponent: __style ? __style.frame : undefined

        Loader {
            id: styleLoader
            active: !root.isNative
            sourceComponent: root.style
            onStatusChanged: {
                if (status === Loader.Error)
                    console.error("Failed to load Style for", root)
            }
        }

        focus: true
        Keys.forwardTo: __menuBar ? [__menuBar] : []
        Keys.onEscapePressed: root.__dismissMenu()

        Keys.onDownPressed: {
            if (root.__currentIndex < 0) {
                root.__currentIndex = 0
                return
            }

            for (var i = root.__currentIndex + 1;
                 i < root.items.length && !canBeHovered(i); i++)
                ;
        }

        Keys.onUpPressed: {
            for (var i = root.__currentIndex - 1;
                 i >= 0 && !canBeHovered(i); i--)
                ;
        }

        function canBeHovered(index) {
            var item = itemsRepeater.itemAt(index)
            if (!item["isSeparator"] && item.enabled) {
                root.__currentIndex = index
                return true
            }
            return false
        }

        Keys.onLeftPressed: {
            if (root.__parentMenu)
                __closeMenu()
        }

        Keys.onRightPressed: {
            var item = itemsRepeater.itemAt(root.__currentIndex)
            if (item && item.hasSubmenu) {
                item.showSubMenu(true)
                item.menuItem.__currentIndex = 0
            }
        }

        Keys.onSpacePressed: menuFrameLoader.triggerAndDismiss()
        Keys.onReturnPressed: menuFrameLoader.triggerAndDismiss()
        Keys.onEnterPressed: menuFrameLoader.triggerAndDismiss()

        function triggerAndDismiss() {
            var item = itemsRepeater.itemAt(root.__currentIndex)
            if (item && !item.isSeparator) {
                item.menuItem.trigger()
                root.__dismissMenu()
            }
        }

        Binding {
            // Make sure the styled frame is in the background
            target: menuFrameLoader.item
            property: "z"
            value: menuMouseArea.z - 1
        }

        MouseArea {
            id: menuMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons

            onPositionChanged: updateCurrentItem(mouse)
            onReleased: menuFrameLoader.triggerAndDismiss()

            property Item currentItem: null

            function updateCurrentItem(mouse) {
                var pos = mapToItem(column, mouse.x, mouse.y)
                if (!currentItem || !currentItem.contains(Qt.point(pos.x - currentItem.x, pos.y - currentItem.y))) {
                    if (currentItem && !pressed && currentItem.hasSubmenu)
                        currentItem.closeSubMenu()
                    currentItem = column.childAt(pos.x, pos.y)
                    if (currentItem) {
                        root.__currentIndex = currentItem.menuItemIndex
                        if (currentItem.hasSubmenu && !currentItem.menuItem.popupVisible)
                            currentItem.showSubMenu(false)
                    } else {
                        root.__currentIndex = -1
                    }
                }
            }

            // Each menu item has its own mouse area, and for events to be
            // propagated to the menu mouse area, they need to be embedded.
            Column {
                id: column

                Repeater {
                    id: itemsRepeater
                    model: root.items

                    Loader {
                        id: menuItemLoader

                        property var menuItem: modelData
                        property bool isSeparator: menuItem ? !menuItem.hasOwnProperty("text") : false
                        property bool hasSubmenu: menuItem ? !!menuItem["items"] : false
                        property bool selected: !isSeparator && root.__currentIndex === index

                        property int menuItemIndex: index

                        sourceComponent: menuFrameLoader.menuItemStyle
                        enabled: !isSeparator && !!menuItem && menuItem.enabled

                        function showSubMenu(immediately) {
                            if (immediately) {
                                if (root.__currentIndex === menuItemIndex)
                                    menuItem.__popup(menuFrameLoader.subMenuXPos, 0, -1)
                            } else {
                                openMenuTimer.start()
                            }
                        }

                        Timer {
                            id: openMenuTimer
                            interval: 50
                            onTriggered: menuItemLoader.showSubMenu(true)
                        }

                        function closeSubMenu() { closeMenuTimer.start() }

                        Timer {
                            id: closeMenuTimer
                            interval: 1
                            onTriggered: {
                                if (root.__currentIndex !== menuItemIndex)
                                    menuItem.__closeMenu()
                            }
                        }

                        Component.onCompleted: {
                            menuItem.__visualItem = menuItemLoader
                            if (hasSubmenu)
                                menuItem.visualParent = menuItemLoader
                        }
                    }
                }

                onWidthChanged: {
                    for (var i = 0; i < children.length; i++) {
                        var item = children[i]["item"]
                        if (item)
                            item.implicitWidth = Math.max(root.__minimumWidth, implicitWidth)
                    }
                }
            }
        }
    }
}
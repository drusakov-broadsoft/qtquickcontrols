/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the Qt Quick Controls module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL3$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see http://www.qt.io/terms-conditions. For further
** information use the contact form at http://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPLv3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or later as published by the Free
** Software Foundation and appearing in the file LICENSE.GPL included in
** the packaging of this file. Please review the following information to
** ensure the GNU General Public License version 2.0 requirements will be
** met: http://www.gnu.org/licenses/gpl-2.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.1
import QtQuick.Controls.Private 1.0

/*!
    \qmltype MenuBar
    \inqmlmodule QtQuick.Controls
    \since 5.1
    \ingroup applicationwindow
    \brief Provides a horizontal menu bar.

    \image menubar.png

    MenuBar can be added to an \l ApplicationWindow, providing menu options
    to access additional functionality of the application.

    \code
    ApplicationWindow {
        ...
        menuBar: MenuBar {
            Menu {
                title: "File"
                MenuItem { text: "Open..." }
                MenuItem { text: "Close" }
            }

            Menu {
                title: "Edit"
                MenuItem { text: "Cut" }
                MenuItem { text: "Copy" }
                MenuItem { text: "Paste" }
            }
        }
    }
    \endcode

    \sa ApplicationWindow::menuBar
*/

MenuBarPrivate {
    id: root

    /*! \qmlproperty Component MenuBar::style
        \since QtQuick.Controls.Styles 1.2

        The style Component for this control.
        \sa {MenuBarStyle}

    */
    property Component style: Settings.styleComponent(Settings.style, "MenuBarStyle.qml", root)

    /*! \internal */
    property QtObject __style: styleLoader.item

    __isNative: !__style.hasOwnProperty("__isNative") || __style.__isNative

    /*! \internal */
    __contentItem: Loader {
        id: topLoader
        sourceComponent: __menuBarComponent
        active: !root.__isNative
        focus: true
        Keys.forwardTo: [item]
        property real preferredWidth: parent && active ? parent.width : 0
        property bool altPressed: item ? item.__altPressed : false
        Loader {
            id: styleLoader
            property alias __control: topLoader.item
            sourceComponent: root.style
            onStatusChanged: {
                if (status === Loader.Error)
                    console.error("Failed to load Style for", root)
            }
        }
    }

    /*! \internal */
    property Component __menuBarComponent: Loader {
        id: menuBarLoader

        Accessible.role: Accessible.MenuBar

        onStatusChanged: if (status === Loader.Error) console.error("Failed to load panel for", root)

        visible: status === Loader.Ready
        sourceComponent: d.style ? d.style.background : undefined

        width: implicitWidth || root.__contentItem.preferredWidth
        height: Math.max(row.height + d.heightPadding, item ? item.implicitHeight : 0)

        Binding {
            // Make sure the styled menu bar is in the background
            target: menuBarLoader.item
            property: "z"
            value: menuMouseArea.z - 1
        }

        QtObject {
            id: d

            property Style style: __style

            property int openedMenuIndex: -1
            property int menuIndex: -1
            property bool preselectMenuItem: false
            property real heightPadding: style ? style.padding.top + style.padding.bottom : 0

            property bool altPressed: false
            property var mnemonicsMap: ({})
            property var extensionMnemonicsMap: ({})

            property Timer delayedTriggerTimer: Timer {
                interval: 1
                repeat: false
                property var action: null
                onActionChanged: {
                    if (action)
                        start()
                }
                onTriggered: {
                    action.trigger()
                    action = null
                }
            }

            function dismissActiveFocus(event, reason) {
                if (reason) {
                    altPressed = false
                    openedMenuIndex = -1
                    menuIndex = -1
                    root.__contentItem.parent.forceActiveFocus()
                } else {
                    event.accepted = false
                }
            }

            function maybeOpenFirstMenu(event) {
                if (altPressed && openedMenuIndex === -1) {
                    preselectMenuItem = true
                    openedMenuIndex = menuIndex
                } else {
                    event.accepted = false
                }
            }

            function setupMnemonics(item, extensionAction) {
                var title = item.title
                var ampersandPos = title.indexOf("&")
                if (ampersandPos !== -1) {
                    var mnemonic
                    for(mnemonic in mnemonicsMap) {
                        if (mnemonicsMap[mnemonic] == item.__action) {
                            mnemonicsMap[mnemonic] = null
                            break
                        }
                    }
                    for(mnemonic in extensionMnemonicsMap) {
                        if (extensionMnemonicsMap[mnemonic] == item.__action) {
                            extensionMnemonicsMap[mnemonic] = null
                            mnemonicsMap[mnemonic] = null
                            break
                        }
                    }
                    mnemonicsMap[title[ampersandPos + 1].toUpperCase()] = extensionAction ? extensionAction : item.__action
                    if (extensionAction)
                        extensionMnemonicsMap[title[ampersandPos + 1].toUpperCase()] = item.__action
                }
            }
        }
        property alias __altPressed: d.altPressed // Needed for the menu contents

        focus: true

        Keys.onPressed: {
            var action = null
            if (event.key === Qt.Key_Alt && !( event.modifiers & Qt.ControlModifier )) {
                if (!d.altPressed) {
                    d.menuIndex = 0
                    d.altPressed = true
                    forceActiveFocus(Qt.MenuBarFocusReason)
                } else
                    d.dismissActiveFocus(event, true)
            } else if (d.altPressed && (action = d.mnemonicsMap[event.text.toUpperCase()])) {
                d.preselectMenuItem = true
                action.trigger()
                event.accepted = true
                if (action == extensionButton.__menuItem.__action) {
                    if((action = d.extensionMnemonicsMap[event.text.toUpperCase()]))
                        d.delayedTriggerTimer.action = action
                }
            }
        }

        Keys.onEscapePressed: d.dismissActiveFocus(event, d.openedMenuIndex === -1)

        Keys.onUpPressed: d.maybeOpenFirstMenu(event)
        Keys.onDownPressed: d.maybeOpenFirstMenu(event)

        Keys.onLeftPressed: {
            if (d.openedMenuIndex > 0) {
                var idx = d.openedMenuIndex - 1
                while (idx >= 0 && !(root.menus[idx].enabled && root.menus[idx].visible && row.children[idx].menuFitsInBar))
                    idx--
                if (idx >= 0) {
                    d.preselectMenuItem = true
                    d.openedMenuIndex = idx
                    d.menuIndex = idx
                }
            } else if (d.menuIndex > 0) {
                var idx = d.menuIndex - 1
                while (idx >= 0 && !(root.menus[idx].enabled && root.menus[idx].visible && row.children[idx].menuFitsInBar))
                    idx--
                if (idx >= 0) {
                    d.menuIndex = idx
                }
            } else {
                event.accepted = false;
            }
        }

        Keys.onRightPressed: {
            if (d.openedMenuIndex === -1 && d.menuIndex === extensionButton.__menuItemIndex) {
                Keys.onDownPressed(event)
            } else if (d.openedMenuIndex !== -1 && d.openedMenuIndex < root.menus.length - 1) {
                var idx = d.openedMenuIndex + 1
                while (idx < root.menus.length && !(root.menus[idx].enabled && root.menus[idx].visible))
                    idx++
                if (idx < root.menus.length) {
                    d.preselectMenuItem = true
                    if (row.children[idx].menuFitsInBar) {
                        d.openedMenuIndex = idx
                        d.menuIndex = idx
                    } else {
                        d.openedMenuIndex = extensionButton.__menuItemIndex
                        d.menuIndex = extensionButton.__menuItemIndex
                    }
                }
            } else if (d.menuIndex !== -1 && d.menuIndex < root.menus.length - 1) {
                var idx = d.menuIndex + 1
                while (idx < root.menus.length && !(root.menus[idx].enabled && root.menus[idx].visible))
                    idx++
                if (idx < root.menus.length) {
                    if (row.children[idx].menuFitsInBar) {
                        d.menuIndex = idx
                    } else {
                        d.menuIndex = extensionButton.__menuItemIndex
                    }
                }
            } else {
                event.accepted = false;
            }
        }

        function getExtensionMenuItem(identifier) {
            for (var j=0; j < extensionButton.__menuItem.items.length; ++j) {
                if (extensionButton.__menuItem.items[j].identifier === identifier) {
                    return extensionButton.__menuItem.items[j]
                }
            }
            return null
        }

        function populateExtensionMenu() {
            for (var i = 0; i < row.children.length - 1; ++i) {
                if (row.children[i] !== itemsRepeater) {
                    var it
                    if (row.children[i].__menuItem.visible && !row.children[i].menuFitsInBar) {
                        it = getExtensionMenuItem(row.children[i].__menuItem.identifier)
                        if (it === null) {
                            var insertIndex = 0
                            for (var l = 0; l < i; ++l) {
                                if (getExtensionMenuItem(row.children[l].__menuItem.identifier) !== null) {
                                    ++insertIndex
                                }
                            }
                            it = extensionButton.__menuItem.insertMenu(insertIndex, row.children[i].__menuItem.title)
                            it.identifier = row.children[i].__menuItem.identifier
                        } else if (it.title !== row.children[i].__menuItem.title) {
                            it.title = row.children[i].__menuItem.title
                        }
                        d.setupMnemonics(it, extensionButton.__menuItem.__action)

                        for (var j = it.items.length; row.children[i].__menuItem.items.length; ++j) {
                            var it2 = row.children[i].__menuItem.items[0]
                            row.children[i].__menuItem.removeItem(it2)
                            it.insertItem(j, it2)
                        }
                    } else {
                        it = getExtensionMenuItem(row.children[i].__menuItem.identifier)
                        if (it !== null) {
                            extensionButton.__menuItem.removeItem(it)
                            for (var k = 0; k < it.items.length; ++k) {
                                row.children[i].__menuItem.insertItem(k, it.items[k])
                            }
                            d.setupMnemonics(row.children[i].__menuItem)
                        }
                    }
                }
            }
        }

        Keys.forwardTo: d.openedMenuIndex !== -1 ? [root.menus[d.openedMenuIndex].__contentItem] : []

        Row {
            id: row
            x: d.style ? d.style.padding.left : 0
            y: d.style ? d.style.padding.top : 0
            width: parent.width - (d.style ? d.style.padding.left + d.style.padding.right : 0)
            LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
            onWidthChanged: menuBarLoader.populateExtensionMenu()

            property double extButtonWidth: 0
            property int lastItemIndex: -1

            Repeater {
                id: itemsRepeater
                model: root.menus
                Loader {
                    id: menuItemLoader

                    Accessible.role: Accessible.MenuItem
                    Accessible.name: StyleHelpers.removeMnemonics(opts.text)
                    Accessible.onPressAction: d.openedMenuIndex = opts.index

                    property var styleData: QtObject {
                        id: opts
                        readonly property int index: __menuItemIndex
                        readonly property string text: !!__menuItem && __menuItem.title
                        readonly property bool enabled: !!__menuItem && __menuItem.enabled
                        readonly property bool selected: menuMouseArea.hoveredItem === menuItemLoader || d.altPressed && d.menuIndex === index
                        readonly property bool open: !!__menuItem && __menuItem.__popupVisible || d.openedMenuIndex === index
                        readonly property bool underlineMnemonic: d.altPressed
                    }

                    height: Math.max(menuBarLoader.height - d.heightPadding,
                                     menuItemLoader.item ? menuItemLoader.item.implicitHeight : 0)

                    readonly property var __menuItem: modelData
                    readonly property int __menuItemIndex: index
                    sourceComponent: d.style ? d.style.itemDelegate : null
                    property bool lastMenu: false
                    property bool menuFitsInBar: {
                        var sum = 0
                        var fits = true
                        for (var i = 0; i < __menuItemIndex && fits; ++i) {
                            if (row.children[i] !== itemsRepeater) {
                                if (!row.children[i].menuFitsInBar) {
                                    fits = false
                                } else if (row.children[i].__menuItem.visible) {
                                    sum += row.children[i].width + row.spacing
                                    if (sum > row.width - row.extButtonWidth) {
                                        fits = false
                                    }
                                }
                            }
                        }
                        return fits && sum + row.children[__menuItemIndex].width <= row.width - (row.lastItemIndex == __menuItemIndex ? 0 : row.extButtonWidth + row.spacing)
                    }
                    onMenuFitsInBarChanged: {
                        if (menuFitsInBar)
                            __menuItem.itemsChanged.disconnect(menuBarLoader.populateExtensionMenu)
                        else
                            __menuItem.itemsChanged.connect(menuBarLoader.populateExtensionMenu)
                    }
                    visible: __menuItem.visible && menuFitsInBar

                    Connections {
                        target: d
                        onOpenedMenuIndexChanged: {
                            if (!__menuItem.enabled)
                                return;
                            if (d.openedMenuIndex === index) {
                                timerToOpenMenu.item = __menuItem
                                timerToOpenMenu.restart()
                            } else if (__menuItem.__popupVisible) {
                                __menuItem.__dismissMenu()
                                __menuItem.__destroyAllMenuPopups()
                            }
                        }
                    }

                    Timer {
                        id: timerToOpenMenu
                        property var item: null
                        interval: 10
                        running: false
                        repeat: false
                        onTriggered: {
                            if (item.__usingDefaultStyle)
                                item.style = d.style.menuStyle
                            item.__popup(Qt.rect(row.LayoutMirroring.enabled ? menuItemLoader.width : 0,
                                               menuBarLoader.height - d.heightPadding, 0, 0), 0)
                            if (d.preselectMenuItem)
                                item.__currentIndex = 0
                        }
                    }

                    Timer {
                        id: dismissMenuAndDestroyMenuPopupsTimer
                        interval: 100
                        onTriggered: {
                            __menuItem.__dismissMenu()
                            __menuItem.__destroyAllMenuPopups()
                        }
                    }

                    Connections {
                        target: __menuItem
                        onPopupVisibleChanged: {
                            if (!__menuItem.__popupVisible && d.openedMenuIndex === index) {
                                dismissMenuAndDestroyMenuPopupsTimer.start()
                                d.openedMenuIndex = -1
                            }
                        }
                        onTitleChanged: {
                            menuBarLoader.populateExtensionMenu()
                            d.setupMnemonics(__menuItem)
                        }
                        onVisibleChanged: {
                            var result = -1
                            for (var i = 0; i < row.children.length; ++i) {
                                if (row.children[i] !== itemsRepeater && row.children[i].__menuItem.visible) {
                                    result = i
                                }
                            }
                            row.lastItemIndex = result
                        }
                    }

                    Connections {
                        target: __menuItem.__action
                        onTriggered: {
                            d.menuIndex = __menuItemIndex
                            d.openedMenuIndex = __menuItemIndex
                        }
                    }

                    Component.onCompleted: {
                        __menuItem.__visualItem = menuItemLoader
                        __menuItem.__handleMouseMovedInRelease = false
                        d.setupMnemonics(__menuItem)
                    }
                }
            }
        }
        Loader {
            id: extensionButton
            height: row.height
            anchors.right: parent.right

            Accessible.role: Accessible.MenuItem
            Accessible.name: StyleHelpers.removeMnemonics(opts.text)
            Accessible.onPressAction: d.openedMenuIndex = opts.index

            property var styleData: QtObject {
                id: opts
                readonly property int index: extensionButton.__menuItemIndex
                readonly property string text: !!extensionButton.__menuItem && extensionButton.__menuItem.title
                readonly property bool enabled: !!extensionButton.__menuItem && extensionButton.__menuItem.enabled
                readonly property bool selected: menuMouseArea.hoveredItem === extensionButton || d.altPressed && d.menuIndex === index
                readonly property bool open: !!extensionButton.__menuItem && extensionButton.__menuItem.__popupVisible || d.openedMenuIndex === index
                readonly property bool underlineMnemonic: d.altPressed
            }

            Loader {
                id: extensionMenuLoader
                sourceComponent: Menu {
                    title: "\u226b"
                    visible: row.lastItemIndex != -1 && !row.children[row.lastItemIndex].menuFitsInBar
                    Component.onCompleted: __setParent(root)
                }
            }
            readonly property var __menuItem: extensionMenuLoader.item
            readonly property int __menuItemIndex: root.menus.length
            sourceComponent: d.style ? d.style.itemDelegate : null

            visible: __menuItem.visible
            onVisibleChanged: visibleTimer.start()
            Timer {
                id: visibleTimer
                interval: 1
                onTriggered: row.extButtonWidth = extensionButton.visible ? extensionButton.width : 0
            }

            onLoaded: {
                populateExtensionMenuWhenLoaded.start()
            }
            Timer {
                id: populateExtensionMenuWhenLoaded
                interval: 10
                onTriggered: menuBarLoader.populateExtensionMenu()
            }

            Connections {
                target: d
                onOpenedMenuIndexChanged: {
                    if (!extensionButton.__menuItem.enabled)
                        return;
                    if (d.openedMenuIndex === extensionButton.__menuItemIndex) {
                        if (extensionButton.__menuItem.__usingDefaultStyle)
                            extensionButton.__menuItem.style = d.style.menuStyle
                        extensionButton.__menuItem.__popup(Qt.rect(row.LayoutMirroring.enabled ? extensionButton.width : 0,
                                                           menuBarLoader.height - d.heightPadding, 0, 0), 0)
                        if (d.preselectMenuItem)
                            extensionButton.__menuItem.__currentIndex = 0
                    } else if (extensionButton.__menuItem.__popupVisible) {
                        extensionButton.__menuItem.__dismissMenu()
                        extensionButton.__menuItem.__destroyAllMenuPopups()
                    }
                }
            }

            Connections {
                target: extensionButton.__menuItem
                onPopupVisibleChanged: {
                    if (!extensionButton.__menuItem.__popupVisible && d.openedMenuIndex === extensionButton.__menuItemIndex)
                        d.openedMenuIndex = -1
                }
            }

            Connections {
                target: extensionButton.__menuItem.__action
                ignoreUnknownSignals: true
                onTriggered: {
                    d.menuIndex = extensionButton.__menuItemIndex
                    d.openedMenuIndex = extensionButton.__menuItemIndex
                }
            }

            Component.onCompleted: {
                extensionButton.__menuItem.__visualItem = extensionButton
                extensionButton.__menuItem.__handleMouseMovedInRelease = false
            }
        }

        MouseArea {
            id: menuMouseArea
            anchors.fill: parent
            hoverEnabled: Settings.hoverEnabled

            onPositionChanged: updateCurrentItem(mouse)
            onPressed: {
                if (updateCurrentItem(mouse)) {
                    d.preselectMenuItem = false
                    d.openedMenuIndex = currentItem.__menuItemIndex
                }
            }
            onExited: hoveredItem = null

            property Item currentItem: null
            property Item hoveredItem: null
            function updateCurrentItem(mouse) {
                var pos = mapToItem(row, mouse.x, mouse.y)
                if (!hoveredItem || !hoveredItem.contains(Qt.point(pos.x - currentItem.x, pos.y - currentItem.y))) {
                    hoveredItem = row.childAt(pos.x, pos.y)
                    if (!hoveredItem) {
                        pos = mapToItem(extensionButton, mouse.x, mouse.y)
                        hoveredItem = extensionButton.contains(Qt.point(pos.x, pos.y)) ? extensionButton : null
                        if (!hoveredItem)
                            return false;
                    }
                    currentItem = hoveredItem
                    if (d.openedMenuIndex !== -1) {
                        d.preselectMenuItem = false
                        d.openedMenuIndex = currentItem.__menuItemIndex
                    }
                }
                return true;
            }
        }
    }
}

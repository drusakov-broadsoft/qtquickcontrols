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
import QtTest 1.0
import QtQuick.Controls 1.0

TestCase {
    id: testcase
    name: "Tests_Menu"
    when: windowShown
    width: 300; height: 300

    property var itemsText: [ "apple", "banana", "clementine", "dragon fruit" ]

    property var menu
    property var menuItem

    SignalSpy {
        id: menuSpy
        target: testcase.menu
        signalName: "selectedIndexChanged"
    }

    SignalSpy {
        id: menuItemSpy
        target: testcase.menuItem
        signalName: "triggered"
    }

    Component {
        id: creationComponent
        Menu {
            MenuItem { text: "apple" }
            MenuItem { text: "banana" }
            MenuItem { text: "clementine" }
            MenuItem { text: "dragon fruit" }
        }
    }

    function init() {
        menu = creationComponent.createObject(testcase)
    }

    function cleanup() {
        menuSpy.clear()
        menuItemSpy.clear()
        menu.destroy()
    }

    function test_creation() {
        compare(menu.items.length, testcase.itemsText.length)
        for (var i = 0; i < menu.items.length; i++)
            compare(menu.items[i].text, testcase.itemsText[i])
    }

    Component {
        id: modelCreationComponent
        // TODO Update when model patch is in
        // Menu { MenuItemRepeater { model: testcase.itemsText MenuItem { text: modelData } }
        ContextMenu { model: testcase.itemsText }
    }

    function test_modelCreation() {
        var menu = modelCreationComponent.createObject(testcase)
        compare(menu.items.length, testcase.itemsText.length)
        for (var i = 0; i < menu.items.length; i++)
            compare(menu.items[i].text, testcase.itemsText[i])
        menu.destroy()
    }

    function test_trigger() {
        menuItem = menu.items[2]
        menuItem.trigger()

        compare(menuItemSpy.count, 1)
        compare(menuSpy.count, 1)
        compare(menu.selectedIndex, 2)
    }

    function test_check() {
        for (var i = 0; i < menu.items.length; i++)
            menu.items[i].checkable = true

        menuItem = menu.items[2]
        compare(menuItem.checkable, true)
        compare(menuItem.checked, false)
        menuItem.trigger()

        for (i = 0; i < menu.items.length; i++)
            compare(menu.items[i].checked, i === 2)

        menuItem = menu.items[3]
        compare(menuItem.checkable, true)
        compare(menuItem.checked, false)
        menuItem.trigger()

        for (i = 0; i < menu.items.length; i++)
            compare(menu.items[i].checked, i === 2 || i === 3)

        compare(menuItemSpy.count, 2)
        compare(menuSpy.count, 2)
        compare(menu.selectedIndex, 3)
    }

    ExclusiveGroup { id: eg }

    function test_exclusive() {
        for (var i = 0; i < menu.items.length; i++) {
            menu.items[i].checkable = true
            menu.items[i].exclusiveGroup = eg
        }

        menuItem = menu.items[2]
        compare(menuItem.checkable, true)
        compare(menuItem.checked, false)
        menuItem.trigger()

        for (i = 0; i < menu.items.length; i++)
            compare(menu.items[i].checked, i === 2)

        menuItem = menu.items[3]
        compare(menuItem.checkable, true)
        compare(menuItem.checked, false)
        menuItem.trigger()

        for (i = 0; i < menu.items.length; i++)
            compare(menu.items[i].checked, i === 3)

        compare(menuItemSpy.count, 2)
        compare(menuSpy.count, 2)
        compare(menu.selectedIndex, 3)
    }

    function test_selectedIndex() {
        for (var i = 0; i < menu.items.length; i++)
            menu.items[i].checkable = true

        menu.selectedIndex = 3
        compare(menu.selectedIndex, 3)
        verify(!menu.items[menu.selectedIndex].checked)

        menu.items[2].trigger()
        compare(menu.selectedIndex, 2)
        verify(menu.items[menu.selectedIndex].checked)
    }
}
/****************************************************************************
**
** Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** This file is part of the Qt Components project.
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
**   * Neither the name of Nokia Corporation and its Subsidiary(-ies) nor
**     the names of its contributors may be used to endorse or promote
**     products derived from this software without specific prior written
**     permission.
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
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0
import QtDesktop 0.2
import "private" as Private

Private.BasicButton {
    id:button

    property string iconName
    property string styleHint
    property url iconSource
    property string text

    delegate: StyleItem {
        id: styleitem
        anchors.fill: parent
        elementType: "toolbutton"
        on: pressed | checked
        sunken: pressed
        raised: containsMouse
        hover: containsMouse
        info: __position
        hint: button.styleHint
        contentWidth: Math.max(textitem.paintedWidth, 32)
        contentHeight: 32
        Text {
            id: textitem
            text: button.text
            anchors.centerIn: parent
            visible: button.iconSource == ""
        }
    }
    Image {
        id: themeIcon
        anchors.centerIn: parent
        opacity: enabled ? 1 : 0.5
        smooth: true
        sourceSize.width: iconSize
        //property string iconPath: "image://desktoptheme/" + button.iconName
        property int iconSize: 24 //(backgroundItem && backgroundItem.style === "mac" && button.styleHint.indexOf("segmented") !== -1) ? 16 : 24
        //source: iconPath // backgroundItem && backgroundItem.hasThemeIcon(iconName) ? iconPath : ""
        fillMode: Image.PreserveAspectFit
        Image {
            // Use fallback icon
            anchors.centerIn: parent
            sourceSize: parent.sourceSize
            visible: (themeIcon.status != Image.Ready)
            source: visible ? button.iconSource : ""
        }
    }
    Accessible.name: text
}
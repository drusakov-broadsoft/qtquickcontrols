/****************************************************************************
**
** Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the Qt Quick Controls module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Digia.  For licensing terms and
** conditions see http://qt.digia.com/licensing.  For further information
** use the contact form at http://qt.digia.com/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Digia gives you certain additional
** rights.  These rights are described in the Digia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "qtmenuitem_p.h"
#include "qtaction_p.h"
#include "qtmenu_p.h"

#include <QtGui/private/qguiapplication_p.h>
#include <QtGui/qpa/qplatformtheme.h>
#include <QtGui/qpa/qplatformmenu.h>
#include <QtQuick/QQuickItem>

QT_BEGIN_NAMESPACE

QtMenuBase::QtMenuBase(QObject *parent)
    : QObject(parent), m_visible(true),
      m_parentMenu(0), m_visualItem(0)
{
    m_platformItem = QGuiApplicationPrivate::platformTheme()->createPlatformMenuItem();
}

QtMenuBase::~QtMenuBase()
{
    delete m_platformItem;
}

void QtMenuBase::setVisible(bool v)
{
    if (v != m_visible) {
        m_visible = v;
        emit visibleChanged();
    }
}

QtMenu *QtMenuBase::parentMenu() const
{
    return m_parentMenu;
}

void QtMenuBase::setParentMenu(QtMenu *parentMenu)
{
    m_parentMenu = parentMenu;
}

void QtMenuBase::syncWithPlatformMenu()
{
    QtMenu *menu = qobject_cast<QtMenu *>(parent());
    if (menu && menu->platformMenu() && platformItem()
        && menu->m_menuItems.contains(this)) // If not, it'll be added later and then sync'ed
        menu->platformMenu()->syncMenuItem(platformItem());
}

QQuickItem *QtMenuBase::visualItem() const
{
    return m_visualItem;
}

void QtMenuBase::setVisualItem(QQuickItem *item)
{
    m_visualItem = item;
}

/*!
    \qmltype MenuSeparator
    \instantiates QtMenuSeparator
    \inqmlmodule QtQuick.Controls 1.0
    \ingroup menus
    \brief MenuSeparator provides a separator for your items inside a menu.

    \sa Menu, MenuItem
*/

QtMenuSeparator::QtMenuSeparator(QObject *parent)
    : QtMenuBase(parent)
{
    if (platformItem())
        platformItem()->setIsSeparator(true);
}

QtMenuText::QtMenuText(QObject *parent)
    : QtMenuBase(parent), m_enabled(true)
{ }

QtMenuText::~QtMenuText()
{ }

void QtMenuText::setParentMenu(QtMenu *parentMenu)
{
    QtMenuBase::setParentMenu(parentMenu);
    connect(this, SIGNAL(triggered()), parentMenu, SLOT(updateSelectedIndex()));
}

void QtMenuText::trigger()
{
    emit triggered();
}

void QtMenuText::setEnabled(bool enabled)
{
    if (enabled != m_enabled) {
        m_enabled = enabled;
        if (platformItem()) {
            platformItem()->setEnabled(m_enabled);
            syncWithPlatformMenu();
        }

        emit enabledChanged();
    }
}

void QtMenuText::setText(const QString &text)
{
    if (text != m_text) {
        m_text = text;
        if (platformItem()) {
            platformItem()->setText(m_text);
            syncWithPlatformMenu();
        }
        emit textChanged();
    }
}

void QtMenuText::setIconSource(const QUrl &iconSource)
{
    if (iconSource != m_iconSource) {
        m_iconSource = iconSource;
        if (platformItem()) {
            platformItem()->setIcon(icon());
            syncWithPlatformMenu();
        }

        emit iconSourceChanged();
    }
}

void QtMenuText::setIconName(const QString &iconName)
{
    if (iconName != m_iconName) {
        m_iconName = iconName;
        if (platformItem()) {
            platformItem()->setIcon(icon());
            syncWithPlatformMenu();
        }
        emit iconNameChanged();
    }
}

/*!
    \qmltype MenuItem
    \instantiates QtMenuItem
    \ingroup menus
    \inqmlmodule QtQuick.Controls 1.0
    \brief MenuItem provides an item to add in a menu or a menu bar.

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
    }
    \endcode

    \sa MenuBar, Menu, MenuSeparator, Action
*/

/*!
    \qmlproperty string MenuItem::text

    Text for the menu item.
*/

/*!
    \qmlproperty string MenuItem::shortcut

    Shorcut bound to the menu item.

    \sa Action::shortcut
*/

/*!
    \qmlproperty bool MenuItem::checkable

    Whether the menu item can be toggled.

    \sa checked
*/

/*!
    \qmlproperty bool MenuItem::checked

    If the menu item is checkable, this property reflects its checked state.

    \sa chekcable, Action::toggled()
*/

/*!
    \qmlproperty url MenuItem::iconSource

    \sa iconName, Action::iconSource
*/

/*!
    \qmlproperty string MenuItem::iconName

    \sa iconSource, Action::iconName
*/

/*!
    \qmlproperty Action MenuItem::action

    The action bound to this menu item.

    \sa Action
*/

/*! \qmlsignal MenuItem::triggered()

    Emitted when either the menu item or its bound action have been activated.

    \sa trigger(), Action::triggered(), Action::toggled()
*/

/*! \qmlmethod MenuItem::trigger()

    Manually trigger a menu item. Will also trigger the item's bound action.

    \sa triggered(), Action::trigger()
*/

/*! \qmlproperty ExclusiveGroup MenuItem::exclusiveGroup

    ...

    \sa checked, checkable
*/

QtMenuItem::QtMenuItem(QObject *parent)
    : QtMenuText(parent), m_action(0)
{ }

QtMenuItem::~QtMenuItem()
{
    unbindFromAction(m_action);
}

void QtMenuItem::bindToAction(QtAction *action)
{
    m_action = action;

    if (platformItem()) {
        connect(platformItem(), SIGNAL(activated()), m_action, SLOT(trigger()));
    }

    connect(m_action, SIGNAL(destroyed(QObject*)), this, SLOT(unbindFromAction(QObject*)));

    connect(m_action, SIGNAL(triggered()), this, SIGNAL(triggered()));
    connect(m_action, SIGNAL(toggled(bool)), this, SLOT(updateChecked()));
    connect(m_action, SIGNAL(exclusiveGroupChanged()), this, SIGNAL(exclusiveGroupChanged()));
    connect(m_action, SIGNAL(enabledChanged()), this, SLOT(updateEnabled()));
    connect(m_action, SIGNAL(textChanged()), this, SLOT(updateText()));
    connect(m_action, SIGNAL(shortcutChanged(QString)), this, SLOT(updateShortcut()));
    connect(m_action, SIGNAL(checkableChanged()), this, SIGNAL(checkableChanged()));
    connect(m_action, SIGNAL(iconNameChanged()), this, SLOT(updateIconName()));
    connect(m_action, SIGNAL(iconSourceChanged()), this, SLOT(updateIconSource()));

    if (m_action->parent() != this) {
        updateText();
        updateShortcut();
        updateEnabled();
        updateIconName();
        updateIconSource();
        if (checkable())
            updateChecked();
    }
}

void QtMenuItem::unbindFromAction(QObject *o)
{
    if (!o)
        return;

    if (o == m_action)
        m_action = 0;

    QtAction *action = qobject_cast<QtAction *>(o);
    if (!action)
        return;

    if (platformItem()) {
        disconnect(platformItem(), SIGNAL(activated()), action, SLOT(trigger()));
    }

    disconnect(action, SIGNAL(destroyed(QObject*)), this, SLOT(unbindFromAction(QObject*)));

    disconnect(action, SIGNAL(triggered()), this, SIGNAL(triggered()));
    disconnect(action, SIGNAL(toggled(bool)), this, SLOT(updateChecked()));
    disconnect(action, SIGNAL(exclusiveGroupChanged()), this, SIGNAL(exclusiveGroupChanged()));
    disconnect(action, SIGNAL(enabledChanged()), this, SLOT(updateEnabled()));
    disconnect(action, SIGNAL(textChanged()), this, SLOT(updateText()));
    disconnect(action, SIGNAL(shortcutChanged(QString)), this, SLOT(updateShortcut()));
    disconnect(action, SIGNAL(checkableChanged()), this, SIGNAL(checkableChanged()));
    disconnect(action, SIGNAL(iconNameChanged()), this, SLOT(updateIconName()));
    disconnect(action, SIGNAL(iconSourceChanged()), this, SLOT(updateIconSource()));
}

QtAction *QtMenuItem::action()
{
    if (!m_action)
        bindToAction(new QtAction(this));
    return m_action;
}

void QtMenuItem::setAction(QtAction *a)
{
    if (a == m_action)
        return;

    if (m_action) {
        if (m_action->parent() == this)
            delete m_action;
        else
            unbindFromAction(m_action);
    }

    bindToAction(a);
    emit actionChanged();
}

QString QtMenuItem::text() const
{
    return m_action ? m_action->text() : QString();
}

void QtMenuItem::setText(const QString &text)
{
    action()->setText(text);
}

void QtMenuItem::updateText()
{
    QtMenuText::setText(text());
}

QString QtMenuItem::shortcut() const
{
    return m_action ? m_action->shortcut() : QString();
}

void QtMenuItem::setShortcut(const QString &shortcut)
{
    action()->setShortcut(shortcut);
}

void QtMenuItem::updateShortcut()
{
    if (platformItem()) {
        platformItem()->setShortcut(QKeySequence(shortcut()));
        syncWithPlatformMenu();
    }
    emit shortcutChanged();
}

bool QtMenuItem::checkable() const
{
    return m_action ? m_action->isCheckable() : false;
}

void QtMenuItem::setCheckable(bool checkable)
{
    action()->setCheckable(checkable);
}

bool QtMenuItem::checked() const
{
    return m_action ? m_action->isChecked() : false;
}

void QtMenuItem::setChecked(bool checked)
{
    action()->setChecked(checked);
}

void QtMenuItem::updateChecked()
{
    bool checked = this->checked();
    if (platformItem()) {
        platformItem()->setChecked(checked);
        syncWithPlatformMenu();
    }
    emit toggled(checked);
}

QtExclusiveGroup *QtMenuItem::exclusiveGroup() const
{
    return m_action ? m_action->exclusiveGroup() : 0;
}

void QtMenuItem::setExclusiveGroup(QtExclusiveGroup *eg)
{
    action()->setExclusiveGroup(eg);
}

bool QtMenuItem::enabled() const
{
    return m_action ? m_action->isEnabled() : false;
}

void QtMenuItem::setEnabled(bool enabled)
{
    action()->setEnabled(enabled);
}

void QtMenuItem::updateEnabled()
{
    QtMenuText::setEnabled(enabled());
}

QUrl QtMenuItem::iconSource() const
{
    return m_action ? m_action->iconSource() : QUrl();
}

void QtMenuItem::setIconSource(const QUrl &iconSource)
{
    action()->setIconSource(iconSource);
}

void QtMenuItem::updateIconSource()
{
    QtMenuText::setIconSource(iconSource());
}

QString QtMenuItem::iconName() const
{
    return m_action ? m_action->iconName() : QString();
}

void QtMenuItem::setIconName(const QString &iconName)
{
    action()->setIconName(iconName);
}

void QtMenuItem::updateIconName()
{
    QtMenuText::setIconName(iconName());
}

QIcon QtMenuItem::icon() const
{
    return m_action ? m_action->icon() : QtMenuText::icon();
}

void QtMenuItem::trigger()
{
    if (m_action)
        m_action->trigger();
    else
        QtMenuText::trigger();
}

QT_END_NAMESPACE
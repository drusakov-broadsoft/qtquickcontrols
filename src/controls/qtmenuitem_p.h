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

#ifndef QTMENUITEM_P_H
#define QTMENUITEM_P_H

#include <QtCore/QObject>
#include <QtCore/QPointF>
#include <QtCore/QPointer>
#include <QtCore/QUrl>
#include <QtCore/QVariant>
#include <QtGui/QIcon>

QT_BEGIN_NAMESPACE

class QUrl;
class QPlatformMenuItem;
class QQuickItem;
class QtAction;
class QtExclusiveGroup;
class QtMenu;

class QtMenuBase: public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool visible READ visible WRITE setVisible NOTIFY visibleChanged)

    Q_PROPERTY(QtMenu *__parentMenu READ parentMenu CONSTANT)
    Q_PROPERTY(bool __isNative READ isNative CONSTANT)
    Q_PROPERTY(QQuickItem *__visualItem READ visualItem WRITE setVisualItem)

Q_SIGNALS:
    void visibleChanged();

public:
    QtMenuBase(QObject *parent = 0);
    ~QtMenuBase();

    bool visible() const { return m_visible; }
    void setVisible(bool);

    QtMenu *parentMenu() const;
    virtual void setParentMenu(QtMenu *parentMenu);

    inline QPlatformMenuItem *platformItem() { return m_platformItem; }
    void syncWithPlatformMenu();

    QQuickItem *visualItem() const;
    void setVisualItem(QQuickItem *item);

    virtual bool isNative() { return m_platformItem != 0; }

private:
    bool m_visible;
    QtMenu *m_parentMenu;
    QPlatformMenuItem *m_platformItem;
    QPointer<QQuickItem> m_visualItem;
};

class QtMenuSeparator : public QtMenuBase
{
    Q_OBJECT
public:
    QtMenuSeparator(QObject *parent = 0);
};

class QtMenuText: public QtMenuBase
{
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QUrl iconSource READ iconSource WRITE setIconSource NOTIFY iconSourceChanged)
    Q_PROPERTY(QString iconName READ iconName WRITE setIconName NOTIFY iconNameChanged)

    Q_PROPERTY(QVariant __icon READ iconVariant  NOTIFY __iconChanged)

public Q_SLOTS:
    virtual void trigger();

Q_SIGNALS:
    void triggered();
    void textChanged();
    void enabledChanged();

    void iconSourceChanged();
    void iconNameChanged();

    void __iconChanged();

public:
    QtMenuText(QObject *parent = 0);
    ~QtMenuText();

    virtual bool enabled() const { return m_enabled; }
    virtual void setEnabled(bool enabled);

    virtual QString text() const { return m_text; }
    virtual void setText(const QString &text);

    virtual QUrl iconSource() const { return m_iconSource; }
    virtual void setIconSource(const QUrl &icon);
    virtual QString iconName() const { return m_iconName; }
    virtual void setIconName(const QString &icon);

    void setParentMenu(QtMenu *parentMenu);

    virtual QIcon icon() const { return QIcon(); } // TODO
    QVariant iconVariant() const { return QVariant(icon()); }

private:
    QString m_text;
    bool m_enabled;
    QUrl m_iconSource;
    QString m_iconName;
};

class QtMenuItem: public QtMenuText
{
    Q_OBJECT
    Q_PROPERTY(bool checkable READ checkable WRITE setCheckable NOTIFY checkableChanged)
    Q_PROPERTY(bool checked READ checked WRITE setChecked NOTIFY toggled)
    Q_PROPERTY(QtExclusiveGroup *exclusiveGroup READ exclusiveGroup WRITE setExclusiveGroup NOTIFY exclusiveGroupChanged)
    Q_PROPERTY(QString shortcut READ shortcut WRITE setShortcut NOTIFY shortcutChanged)
    Q_PROPERTY(QtAction *action READ action WRITE setAction NOTIFY actionChanged)

public Q_SLOTS:
    void trigger();

Q_SIGNALS:
    void checkableChanged();
    void toggled(bool);
    void exclusiveGroupChanged();

    void shortcutChanged();
    void actionChanged();

public:
    QtMenuItem(QObject *parent = 0);
    ~QtMenuItem();

    bool enabled() const;
    void setEnabled(bool enabled);

    QString text() const;
    void setText(const QString &text);

    QUrl iconSource() const;
    void setIconSource(const QUrl &icon);
    QString iconName() const;
    void setIconName(const QString &icon);

    QtAction *action();
    void setAction(QtAction *a);

    QString shortcut() const;
    void setShortcut(const QString &shortcut);

    bool checkable() const;
    void setCheckable(bool checkable);

    bool checked() const;
    void setChecked(bool checked);

    QtExclusiveGroup *exclusiveGroup() const;
    void setExclusiveGroup(QtExclusiveGroup *);

    QIcon icon() const;

protected Q_SLOTS:
    virtual void updateText();
    void updateShortcut();
    void updateChecked();
    void updateEnabled();
    void updateIconName();
    void updateIconSource();
    void bindToAction(QtAction *action);
    void unbindFromAction(QObject *action);

private:
    QtAction *m_action;
};

QT_END_NAMESPACE

#endif //QTMENUITEM_P_H
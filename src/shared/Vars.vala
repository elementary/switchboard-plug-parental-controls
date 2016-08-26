// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Adam Bieńkowski (https://launchpad.net/switchboard-plug-parental-controls)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */
 
namespace PC.Vars {
    public const string LOGIN_IFACE = "org.freedesktop.login1";
    public const string LOGIN_OBJECT_PATH = "/org/freedesktop/login1";
    public const string DBUS_PROPERTIES_IFACE = "org.freedesktop.DBus.Properties";
    public const string CUPS_PK_HELPER_IFACE = "org.opensuse.CupsPkHelper.Mechanism";
    public const string PARENTAL_CONTROLS_IFACE = "org.pantheon.ParentalControls";
    public const string PARENTAL_CONTROLS_OBJECT_PATH = "/org/pantheon/ParentalControls";
    public const string PARENTAL_CONTROLS_ACTION_ID = "org.pantheon.switchboard.parental-controls.administration";
    public const string PLANK_CONF_DIR = "/.config/plank/dock1/settings";
    public const string PLANK_CONF_GROUP = "PlankDockPreferences";
    public const string PLANK_CONF_LOCK_ITEMS_KEY = "LockItems";
    public const string DAEMON_CONF_DIR = "/.config/pantheon-parental-controls-daemon.conf";
    public const string[] DAEMON_IGNORED_USERS = { "lightdm" };
    public const string DAEMON_GROUP = "PCDaemon";
    public const string DAEMON_KEY_ACTIVE = "Active";
    public const string DAEMON_KEY_TARGETS = "Targets";
    public const string DAEMON_KEY_ADMIN = "Admin";
    public const string DAEMON_KEY_BLOCK_URLS = "BlockUrls";
    public const string PAM_CONF_START = "## PANTHEON_PARENTAL_CONTROLS_START";
    public const string PAM_CONF_END = "## PANTHEON_PARENTAL_CONTROLS_END";
    public const string PAM_CONF_REGEX = PAM_CONF_START + "|" + PAM_CONF_END;
    public const string PAM_TIME_CONF_PATH = "/etc/security/time.conf";
    public const string ALL_ID = "all";
    public const string WEEKDAYS_ID = "weekdays";
    public const string WEEKENDS_ID = "weekends";
}
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
    public const string PLANK_CONF_DIR = "/.config/plank/dock1/settings";
    public const string DAEMON_CONF_DIR = "/.config/pantheon-parental-controls-daemon.conf";
    public const string DAEMON_GROUP = "PCDaemon";
    public const string DAEMON_ACTIVE = "Active";
    public const string APP_LOCK_TYPE = "Type";
    public const string APP_LOCK_TARGETS = "Targets";
    public const string APP_LOCK_ADMIN = "Admin";
    public const string PAM_CONF_START = "## PANTHEON_PARENTAL_CONTROLS_START";
    public const string PAM_CONF_END = "## PANTHEON_PARENTAL_CONTROLS_END";
    public const string PAM_CONF_REGEX = PAM_CONF_START + "|" + PAM_CONF_END;
    public const string ALL_ID = "all";
    public const string WEEKDAYS_ID = "weekdays";
    public const string WEEKENDS_ID = "weekends";
}
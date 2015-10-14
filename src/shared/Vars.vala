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
 
namespace PC {
    public class Vars : Object {
        public static const string PLANK_CONF_DIR = "/.config/plank/dock1/settings";
        public static const string APP_LOCK_CONF_DIR = "/.config/app-lock.conf";
        public static const string APP_LOCK_GROUP = "AppLock";
        public static const string APP_LOCK_TYPE = "Type";
        public static const string APP_LOCK_TARGETS = "Targets";
        public static const string APP_LOCK_ADMIN = "Admin";
        public static const string ALL_ID = "all";
        public static const string WEEKDAYS_ID = "weekdays";
        public static const string WEEKENDS_ID = "weekends";   
    }
}
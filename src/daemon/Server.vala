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

namespace PC.Daemon {
    [DBus (name = "org.pantheon.ParentalControls")]
    public class Server : Object {
        private static Server? instance = null;

        [DBus (visible = false)]
        public static Server get_default () {
            if (instance == null) {
                instance = new Server ();
            }

            return instance;
        }
        
        [DBus (visible = false)]
        public signal void authorization_ended (int client_pid);

        public signal void show_app_lock_dialog ();
        public signal void authorize (string user, string action_id);
        public signal void launch (string[] args);
        public signal void send_time_notification (int hours, int minutes);

        public void end_authorization (int client_pid) {
            authorization_ended (client_pid);
        }
    }
}
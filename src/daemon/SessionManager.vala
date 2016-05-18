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
    public class SessionManager : Object {
        public SessionHandler? current_handler = null;
        
        private IManager? manager = null;
        private DBusConnection? conn = null;

        public SessionManager () {
            try {
                manager = Bus.get_proxy_sync (BusType.SYSTEM, Vars.LOGIN_IFACE, Vars.LOGIN_OBJECT_PATH);
                conn = Bus.get_sync (BusType.SYSTEM, null);
            } catch (IOError e) {
                warning ("%s\n", e.message);
            }
        }

        public void start () {
            if (manager == null || conn == null) {
                return;
            }

            manager.session_new.connect (() => update_session ());
            manager.session_removed.connect (() => update_session ());

            conn.signal_subscribe (null,
                                Vars.DBUS_PROPERTIES_IFACE,
                                "PropertiesChanged",
                                get_current_seat_path (),
                                null,
                                0,
                                () => update_session ());
            update_session ();
        }

        private ISession? get_current_session () {
            try {
                string? seat_path = get_current_seat_path ();
                if (seat_path != null) {
                    ISeat? seat = Bus.get_proxy_sync (BusType.SYSTEM, Vars.LOGIN_IFACE, get_current_seat_path ());
                    return Bus.get_proxy_sync (BusType.SYSTEM, Vars.LOGIN_IFACE, seat.active_session.object_path);
                }
            } catch (IOError e) {
                warning ("%s\n", e.message);
            }
            
            return null;         
        }

        private string? get_current_seat_path () {
            try {
                string seat_id = "seat0";
                string? seat_variable = Environment.get_variable ("XDG_SEAT");
                if (seat_variable != null && seat_variable.has_prefix ("seat")) {
                    seat_id = seat_variable;
                }

                return manager.get_seat (seat_id);                
            } catch (Error e) {
                warning ("%s\n", e.message);
            }

            return null;
        }

        private void update_session () {
            if (current_handler != null) {
                current_handler.stop ();
                current_handler.unref ();
                current_handler = null;
            }

            var current_session = get_current_session ();
            if (current_session != null &&
                current_session.name != null &&
                current_session.name.strip () != "" &&
                !(current_session.name in Vars.DAEMON_IGNORED_USERS)) {
                current_handler = new SessionHandler (current_session);
                current_handler.start ();
            }
        }
    }
}
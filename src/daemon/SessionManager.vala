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
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

 namespace PC.Daemon {
    public class SessionManager : Object {
        public SessionHandler? current_handler = null;
        private IManager? manager = null;
        private DBusConnection? conn = null;

        private uint[] signal_ids;

        private static SessionManager? instance = null;
        public static SessionManager get_default () {
            if (instance == null) {
                instance = new SessionManager ();
            }

            return instance;
        }

        public SessionManager () {
            try {
                manager = Bus.get_proxy_sync (BusType.SYSTEM, Constants.LOGIN_IFACE, Constants.LOGIN_OBJECT_PATH);
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

            try {
                foreach (SeatStruct seat_s in manager.list_seats ()) {
                    signal_ids += conn.signal_subscribe (null,
                                    Constants.DBUS_PROPERTIES_IFACE,
                                    "PropertiesChanged",
                                    seat_s.object_path,
                                    null,
                                    0,
                                    () => update_session ());
                }
            } catch (IOError e) {
                warning (e.message);
            }

            update_session ();
        }

        public void stop () {
            foreach (uint signal_id in signal_ids) {
                conn.signal_unsubscribe (signal_id);
            }

            stop_current_handler ();
        }

        private ISession? get_current_session () {
            try {
                var structs = manager.list_sessions ();
                foreach (SessionStruct session_s in structs) {
                    ISession? session = Bus.get_proxy_sync (BusType.SYSTEM, Constants.LOGIN_IFACE, session_s.object_path);
                    if (session != null && session.active) {
                        return session;
                    }
                }
            } catch (IOError e) {
                warning ("%s\n", e.message);
            }
            
            return null;         
        }

        private void update_session () {
            var session = get_current_session ();
            if (session.id == current_handler.get_id ()) {
                return;
            }

            stop_current_handler ();

            if (session == null ||
                session.name == null ||
                session.name in Constants.DAEMON_IGNORED_USERS) {
                return;
            }

            current_handler = new SessionHandler (session);
            current_handler.start ();
        }

        private void stop_current_handler () {
            if (current_handler != null) {
                current_handler.stop ();
                current_handler = null;
            }
        }
    }
}

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
    public class Daemon : GLib.Application {
        private static Daemon? instance = null;

        private static SessionManager? session_manager = null;

        private static MainLoop loop;

        public static Daemon get_instance () {
            return instance;
        }

        public static int main (string[] args) {
            GLib.Process.signal (ProcessSignal.INT, on_exit);
            GLib.Process.signal (ProcessSignal.TERM, on_exit);

            instance = new Daemon ();
            return instance.run (args);
        }

        public static void on_exit (int signum) {
            if (session_manager != null) {
                session_manager.current_handler.stop ();
            }

            terminate ();
        }

        public override void activate () {
            loop = new MainLoop ();

            Bus.own_name (BusType.SYSTEM, Vars.PARENTAL_CONTROLS_IFACE, BusNameOwnerFlags.REPLACE,
                          on_bus_aquired,
                          () => {},
                          on_bust_lost);
            Utils.get_usermanager ().notify["is-loaded"].connect (on_usermanager_loaded);

            loop.run ();
        }

        private void on_bust_lost (DBusConnection connection, string name) {
            warning ("Could not acquire name: %s\n", name);
        }

        private void on_bus_aquired (DBusConnection connection) {
            try {
                connection.register_object (Vars.PARENTAL_CONTROLS_OBJECT_PATH, Server.get_default ());
            } catch (IOError e) {
                warning ("%s\n", e.message);
            }
        }

        private void on_usermanager_loaded () {
            if (!Utils.get_usermanager ().is_loaded) {
                return;
            }

            session_manager = new SessionManager ();
            session_manager.start ();
        }

        private static void terminate (int exit_code = 0) {
            loop.quit ();
            GLib.Process.exit (exit_code);            
        }
    }
}

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

 namespace PC.Client {
    [DBus (name = "org.pantheon.ParentalControls")]
    public interface ParentalControls : Object {
        public signal void show_app_unavailable (string path);
        public signal void app_authorize (string user, string path, string action_id);
        public signal void launch (string[] args);
        public signal void show_timeout (int hours, int minutes);

        public abstract void end_app_authorization () throws IOError;

        public abstract void enable_restriction (string username, bool enable) throws IOError;
        public abstract bool get_user_daemon_active (string username) throws IOError;
        public abstract bool get_user_daemon_admin (string username) throws IOError;
        public abstract string[] get_user_daemon_targets (string username) throws IOError;
        public abstract string[] get_user_daemon_block_urls (string username) throws IOError;
        public abstract void set_user_daemon_active (string username, bool active) throws IOError;
    }

    public class Client : Gtk.Application {
        private ParentalControls? parental_controls;
        private Polkit.Permission? permission = null;

        public static int main (string[] args) {
            Gtk.init (ref args);

            var client = new Client ();
            return client.run (args);
        }

        public override void activate () {
            try {
                parental_controls = Bus.get_proxy_sync (BusType.SYSTEM, Vars.PARENTAL_CONTROLS_IFACE, Vars.PARENTAL_CONTROLS_OBJECT_PATH);
            } catch (Error e) {
                warning ("%s\n", e.message);
                return;
            }

            if (parental_controls == null) {
                return;
            }

            parental_controls.show_app_unavailable.connect (on_show_app_lock_dialog);
            parental_controls.app_authorize.connect (on_authorize);
            parental_controls.launch.connect (on_launch);
            parental_controls.show_timeout.connect (on_send_time_notification);

            Gtk.main ();
        }

        private void on_show_app_lock_dialog (string path) {
            var app_lock_dialog = new AppLock.AppLockDialog ();
            app_lock_dialog.show_all ();
        }

        private void on_authorize (string user_name, string path, string action_id) {
            if (permission != null && permission.get_can_release ()) {
                try {
                    permission.release ();
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            }

            try {
                var user = (Polkit.UnixUser)Polkit.UnixUser.new_for_name (user_name);
                permission = new Polkit.Permission.sync (action_id,
                                        Polkit.UnixProcess.new_for_owner (Posix.getpid (), 0, user.get_uid ()));
            } catch (Error e) {
                warning ("%s\n", e.message);
            }

            permission.notify["allowed"].connect (() => {
                if (parental_controls != null) {
                    try {
                        parental_controls.end_app_authorization ();
                    } catch (IOError e) {
                        warning ("%s\n", e.message);
                    }
                }
            });

            permission.acquire_async.begin ();
        }

        private void on_launch (string[] args) {
            string[] _args = {};
            for (int i = 0; i < args.length; i++) {
                if (args[i].strip () != "") {
                    _args[i] = args[i];
                }
            }

            try {
                GLib.Process.spawn_async ("/",
                                        _args,
                                        Environ.get (),
                                        SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                        null,
                                        null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }


        private void on_send_time_notification (int hours, int minutes) {
            string hours_str = "";
            string minutes_str = "";
            string info = "";
            if (hours == 0 && minutes <= 10) {
                info = _("Make sure to close all applications before your computer will be locked.");
            }

            if (hours > 0) {
                hours_str = ngettext ("%ld hour", "%ld hours", (ulong)hours).printf ((ulong)hours);
            }

            if (minutes > 0) {
                minutes_str = ngettext ("%ld minute", "%ld minutes", (ulong)minutes).printf ((ulong)minutes);
            }

            string body = _("This computer will lock after %s %s. %s".printf (hours_str, minutes_str, info));

            var notification = new Notification (_("Time left"));
            var icon = new ThemedIcon ("dialog-warning");
            notification.set_icon (icon);

            notification.set_body (body);
            send_notification (null, notification);
        }
    }
 }

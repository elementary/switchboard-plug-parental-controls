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
    public class Client : Gtk.Application {
        private Polkit.Permission? permission = null;

        public static int main (string[] args) {
            Gtk.init (ref args);

            var client = new Client ();
            return client.run (args);
        }

        public override void activate () {
            var api = Utils.get_api ();

            api.show_app_unavailable.connect (on_show_app_unavailable);
            api.app_authorize.connect (on_authorize);
            api.launch.connect (on_launch);
            api.show_timeout.connect (on_show_timeout);

            Gtk.main ();
        }

        private void on_show_app_unavailable (string path) {
            var app_lock_dialog = new AppUnavailableDialog ();
            app_lock_dialog.show_all ();
        }

        private void on_authorize (string username, string path, string action_id) {
            if (permission != null && permission.get_can_release ()) {
                try {
                    permission.release ();
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            }

            try {
                var user = new Polkit.UnixUser.for_name (username);
                permission = new Polkit.Permission.sync (action_id,
                                        new Polkit.UnixProcess.for_owner (Posix.getpid (), 0, user.get_uid ()));
            } catch (Error e) {
                warning ("%s\n", e.message);
            }

            ulong signal_id = 0;
            signal_id = permission.notify["allowed"].connect (() => {
                Utils.get_api ().end_app_authorization.begin ();
                permission.disconnect (signal_id);
            });

            permission.acquire_async.begin ();
        }

        private void on_launch (string[] args) {
            try {
                GLib.Process.spawn_async ("/",
                                        args,
                                        Environ.get (),
                                        SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                        null,
                                        null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }


        private void on_show_timeout (int hours, int minutes) {
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

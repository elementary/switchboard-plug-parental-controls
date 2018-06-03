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

namespace PC.Client {
    public class Client : Gtk.Application {
        private Polkit.Permission? permission = null;

        public static int main (string[] args) {
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
                    critical (e.message);
                }
            }

            try {
                var user = new Polkit.UnixUser.for_name (username);
                var unixprocess = new Polkit.UnixProcess.for_owner (Posix.getpid (), 0, user.get_uid ());
                permission = new Polkit.Permission.sync (action_id, unixprocess);
            } catch (Error e) {
                critical (e.message);
            }

            ulong signal_id = 0;
            signal_id = permission.notify["allowed"].connect (() => {
                permission.disconnect (signal_id);
                Utils.get_api ().end_app_authorization.begin ();
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
            string body = _("This computer will lock after %s.");
            if (hours > 0) {
                body = body.printf (ngettext ("%lu hour", "%lu hours", (ulong)hours).printf ((ulong)hours));
            } else if (minutes > 0) {
                body = body.printf (ngettext ("%lu minute", "%lu minutes", (ulong)minutes).printf ((ulong)minutes));
                if (minutes < 10) {
                    body += "\n" + _("Make sure to close all applications before your computer will be locked.");
                }
            } else {
                return;
            }

            var notification = new Notification (_("Time left"));
            var icon = new ThemedIcon ("dialog-warning");
            notification.set_icon (icon);
            notification.set_body (body);

            send_notification ("time-reminder", notification);
        }
    }
 }

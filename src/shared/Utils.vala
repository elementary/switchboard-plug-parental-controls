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
    public class Utils : Object {
        public static Polkit.Permission? permission = null;
        public static string user_name;

        private static Act.UserManager? usermanager = null;

        public static Polkit.Permission? get_permission () {
            if (permission != null) {
                return permission;
            }

            try {
                var user = (Polkit.UnixUser)Polkit.UnixUser.new_for_name (user_name);
                permission = new Polkit.Permission.sync (Vars.PARENTAL_CONTROLS_ACTION_ID,
                                        Polkit.UnixProcess.new_for_owner (Posix.getpid (), 0, user.get_uid ()));
                return permission;
            } catch (Error e) {
                critical (e.message);
                return null;
            }
        }

        public static string create_markup (string name, string comment) {
            var escaped_name = Markup.escape_text (name);
            var escaped_comment = Markup.escape_text (comment);

            return @"<span font_weight=\"bold\" size=\"large\">$escaped_name</span>\n$escaped_comment";
        }

        public static void call_cli (string[] args) {
            string[] spawn_args = { "pkexec", "pantheon-parental-controls-cli" };
            foreach (string arg in args) {
                spawn_args += arg;
            }

            try {
                Pid child_pid;
                Process.spawn_async ("/",
                                    spawn_args,
                                    Environ.get (),
                                    SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                    null,
                                    out child_pid);
                ChildWatch.add (child_pid, (pid, status) => {
                    Process.close_pid (pid);
                });

            } catch (SpawnError e) {
                warning ("%s\n", e.message);
            }
        }

        public static unowned Act.UserManager? get_usermanager () {
            if (usermanager != null) {
                return usermanager;
            }

            usermanager = Act.UserManager.get_default ();
            return usermanager;
        }

        public static unowned Act.User? get_current_user () {
            return get_usermanager ().get_user (user_name);
        }

        public static string build_daemon_conf_path (Act.User user) {
            return Path.build_filename (user.get_home_dir (), Vars.DAEMON_CONF_DIR);
        }

        public static void set_user_name (string _user_name) {
            user_name = _user_name;
        }
    }
}

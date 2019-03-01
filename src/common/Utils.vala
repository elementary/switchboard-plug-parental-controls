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

namespace PC {
    [DBus (name = "org.opensuse.CupsPkHelper.Mechanism")]
    public interface CupsPkHelper : Object {
        public abstract void printer_set_users_allowed (string printer, string[] users) throws GLib.Error;
        public abstract void printer_set_users_denied (string printer, string[] users) throws GLib.Error;
    }

    [DBus (name = "org.pantheon.ParentalControls")]
    public interface IParentalControls : Object {
        public abstract async void add_restriction_for_user (string input, bool clean) throws GLib.Error;
        public abstract async void remove_restriction_for_user (string username) throws GLib.Error;
        public abstract async void finish_app_authorization (string username, string[] args) throws GLib.Error;
        public abstract async bool get_user_daemon_active (string username) throws GLib.Error;
        public abstract async bool get_user_daemon_admin (string username) throws GLib.Error;
        public abstract async string[] get_user_daemon_block_urls (string username) throws GLib.Error;
        public abstract async string[] get_user_daemon_targets (string username) throws GLib.Error;
        public abstract async void lock_dock_icons_for_user (string username, bool lock) throws GLib.Error;
        public abstract async void set_user_daemon_active (string username, bool active) throws GLib.Error;
        public abstract async void set_user_daemon_admin (string username, bool admin) throws GLib.Error;
        public abstract async void set_user_daemon_block_urls (string username, string[] block_urls) throws GLib.Error;
        public abstract async void set_user_daemon_targets (string username, string[] targets) throws GLib.Error;

        public signal void launch (string[] args, bool incoming);
        public signal void show_timeout (int hours, int minutes);
        public signal void user_config_changed (string username);
    }

    public class Utils {
        public class DummyParentalControls : Object, IParentalControls  {
            public async void add_restriction_for_user (string input, bool clean) throws GLib.Error {}
            public async void remove_restriction_for_user (string username) throws GLib.Error {}
            public async void finish_app_authorization (string username, string[] args) throws GLib.Error {}
            public async bool get_user_daemon_active (string username) throws GLib.Error { return false; }
            public async bool get_user_daemon_admin (string username) throws GLib.Error { return false; }
            public async string[] get_user_daemon_block_urls (string username) throws GLib.Error { return {}; }
            public async string[] get_user_daemon_targets (string username) throws GLib.Error { return {}; }
            public async void lock_dock_icons_for_user (string username, bool lock) throws GLib.Error {}
            public async void set_user_daemon_active (string username, bool active) throws GLib.Error {}
            public async void set_user_daemon_admin (string username, bool admin) throws GLib.Error {}
            public async void set_user_daemon_block_urls (string username, string[] block_urls) throws GLib.Error {}
            public async void set_user_daemon_targets (string username, string[] targets) throws GLib.Error {}
        }

        private static Polkit.Permission? permission = null;
        private static Act.UserManager? usermanager = null;
        private static IParentalControls? api = null;

        public static unowned IParentalControls? get_api () {
            if (api != null) {
                return api;
            }

            try {
                api = Bus.get_proxy_sync (BusType.SYSTEM, Constants.PARENTAL_CONTROLS_IFACE, Constants.PARENTAL_CONTROLS_OBJECT_PATH);
            } catch (Error e) {
                critical ("%s, using dummy parental controls backend", e.message);
                api = new DummyParentalControls ();
            }

            return api;
        }

        public static unowned Polkit.Permission? get_permission () {
            if (permission != null) {
                return permission;
            }

            try {
                var user = new Polkit.UnixUser.for_name (Environment.get_user_name ());
                var unixuser = new Polkit.UnixProcess.for_owner (Posix.getpid (), 0, user.get_uid ());
                permission = new Polkit.Permission.sync (Constants.PARENTAL_CONTROLS_ACTION_ID, unixuser);
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

        public static unowned Act.UserManager? get_usermanager () {
            if (usermanager != null) {
                return usermanager;
            }

            usermanager = Act.UserManager.get_default ();
            return usermanager;
        }

        public static unowned Act.User? get_current_user () {
            return get_usermanager ().get_user (Environment.get_user_name ());
        }

        /**
         * Explicitly converts the executable in the Exec field to the absolute executable path
         * while taking into account the pantheon-parental-controls-client arguments.
         */
        public static string info_to_exec_path (AppInfo info, out string[] args) {
            args = info.get_commandline ().split (" ");
            string exec = info.get_executable ();
            if (args.length > 2 && args[0] == Constants.CLIENT_PATH) {
                if (args[1] == "-d") {
                    exec = args[2];
                } else if (args[1] == "-a") {
                    string[] tokens = args[2].replace ("\"", "").split (":");
                    if (tokens.length < 3) {
                        return exec;
                    }

                    string target = tokens[2];
                    try {
                        Shell.parse_argv (target, out args);
                    } catch (ShellError e) {
                        args = exec.split (" ");
                    }

                    exec = args[0];
                }
            }

            return exec_to_path (exec);
        }
        
        private static string exec_to_path (string exec) {
            if (!exec.has_prefix (GLib.Path.DIR_SEPARATOR_S)) {
                return Environment.find_program_in_path (exec) ?? exec;
            }

            return exec;
        }

        public static string remove_comments (string str) {
            string buffer = "";

            foreach (string line in str.split ("\n")) {
                if (!line.strip ().has_prefix ("#")) {
                    buffer += line;
                    buffer += "\n";
                }
            }

            return buffer;
        }
    }
}

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
    [DBus (name = "org.opensuse.CupsPkHelper.Mechanism")]
    public interface CupsPkHelper : Object {
        public abstract void printer_set_users_allowed (string printer, string[] users) throws IOError;
        public abstract void printer_set_users_denied (string printer, string[] users) throws IOError;
    }

    [DBus (name = "org.pantheon.ParentalControls")]
    public interface IParentalControls : Object {
        public abstract async void add_restriction_for_user (string input, bool clean) throws IOError;
        public abstract async void remove_restriction_for_user (string username) throws IOError;
        public abstract async void end_app_authorization () throws IOError;
        public abstract async bool get_user_daemon_active (string username) throws IOError;
        public abstract async bool get_user_daemon_admin (string username) throws IOError;
        public abstract async string[] get_user_daemon_block_urls (string username) throws IOError;
        public abstract async string[] get_user_daemon_targets (string username) throws IOError;
        public abstract async void lock_dock_icons_for_user (string username, bool lock) throws IOError;
        public abstract async void set_user_daemon_active (string username, bool active) throws IOError;
        public abstract async void set_user_daemon_admin (string username, bool admin) throws IOError;
        public abstract async void set_user_daemon_block_urls (string username, string[] block_urls) throws IOError;
        public abstract async void set_user_daemon_targets (string username, string[] targets) throws IOError;

        public signal void app_authorize (string username, string path, string action_id);
        public signal void launch (string[] args);
        public signal void show_app_unavailable (string path);
        public signal void show_timeout (int hours, int minutes);
        public signal void user_config_changed (string username);
    }

    public class Utils {
        public class DummyParentalControls : Object, IParentalControls  {
            public async void add_restriction_for_user (string input, bool clean) throws IOError {}
            public async void remove_restriction_for_user (string username) throws IOError {}
            public async void end_app_authorization () throws IOError {}
            public async bool get_user_daemon_active (string username) throws IOError { return false; }
            public async bool get_user_daemon_admin (string username) throws IOError { return false; }
            public async string[] get_user_daemon_block_urls (string username) throws IOError { return {}; }
            public async string[] get_user_daemon_targets (string username) throws IOError { return {}; }
            public async void lock_dock_icons_for_user (string username, bool lock) throws IOError {}
            public async void set_user_daemon_active (string username, bool active) throws IOError {}
            public async void set_user_daemon_admin (string username, bool admin) throws IOError {}
            public async void set_user_daemon_block_urls (string username, string[] block_urls) throws IOError {}
            public async void set_user_daemon_targets (string username, string[] targets) throws IOError {}    
        }

        private static Polkit.Permission? permission = null;
        private static Act.UserManager? usermanager = null;
        private static IParentalControls? api = null;

        public static IParentalControls? get_api () {
            if (api != null) {
                return api;
            }

            try {
                api = Bus.get_proxy_sync (BusType.SYSTEM, Vars.PARENTAL_CONTROLS_IFACE, Vars.PARENTAL_CONTROLS_OBJECT_PATH);
            } catch (Error e) {
                critical ("%s, using dummy parental controls backend", e.message);
                api = new DummyParentalControls ();
            }

            return api;
        }

        public static Polkit.Permission? get_permission () {
            if (permission != null) {
                return permission;
            }

            try {
                var user = (Polkit.UnixUser)Polkit.UnixUser.new_for_name (Environment.get_user_name ());
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

        public static string build_daemon_conf_path (Act.User user) {
            return Path.build_filename (user.get_home_dir (), Vars.DAEMON_CONF_DIR);
        }
    }
}

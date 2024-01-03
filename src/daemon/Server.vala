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
    [DBus (name = "org.freedesktop.DBus")]
    private interface DBus : Object {
        [DBus (name = "GetConnectionUnixProcessID")]
        public abstract uint32 get_connection_unix_process_id (string name) throws GLib.Error;
        public abstract uint32 get_connection_unix_user (string name) throws GLib.Error;
    }

    [DBus (name = "org.pantheon.ParentalControls")]
    public errordomain ParentalControlsError {
        NOT_AUTHORIZED,
        NOT_IMPLEMENTED,
        USER_CONFIG_NOT_VAILD,
        DBUS_CONNECTION_FAILED
    }

    [DBus (name = "org.pantheon.ParentalControls")]
    public class Server : Object {
        private const uint CLIENT_LAUNCH_TIMEOUT = 5000;

        private static Server? instance = null;
        private DBus? bus_proxy = null;

        [DBus (visible = false)]
        public static Server get_default () {
            if (instance == null) {
                instance = new Server ();
            }

            return instance;
        }

        protected Server () {
            try {
                bus_proxy = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.DBus", "/");
            } catch (Error e) {
                warning (e.message);
                bus_proxy = null;
            }

            UserConfig.init ();

            config_changed.connect (on_config_changed);
        }

        public signal void launch (string[] args, bool incoming);
        public signal void show_timeout (int hours, int minutes);
        public signal void config_changed ();

        public void finish_app_authorization (
            BusName sender,
            string username,
            string[] args
        ) throws GLib.Error, ParentalControlsError {
            var config = UserConfig.get_for_username (username, false);
            if (config == null || !config.admin) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD (
                    "Error: config for %s is not valid or does not have an ability to authorize".printf (username)
                );
            }

            uint32 client_pid = get_pid_from_sender (sender);
            var authority = Polkit.Authority.get_sync ();
            try {
                var unix_user = new Polkit.UnixUser.for_name (username);
                var result = authority.check_authorization_sync (
                    new Polkit.UnixProcess.for_owner ((int)client_pid, 0, unix_user.get_uid ()),
                    Constants.PARENTAL_CONTROLS_ACTION_ID,
                    null,
                    Polkit.CheckAuthorizationFlags.NONE
                );
                if (result.get_is_authorized ()) {
                    string? path = GLib.Environment.find_program_in_path (args[0]);
                    if (path == null) {
                        path = args[0];
                    }

                    AccessControlLists.setfacl (username, path, "--x");
                    ulong launch_signal_id = 0U;
                    uint timeout_signal_id = 0U;

                    launch_signal_id = launch.connect ((args, incoming) => {
                        if (incoming) {
                            return;
                        }

                        disconnect (launch_signal_id);
                        if (timeout_signal_id != 0U) {
                            Source.remove (timeout_signal_id);
                        }

                        AccessControlLists.setfacl (username, path, AccessControlLists.NO_EXEC_PERMISSIONS);
                    });

                    timeout_signal_id = Timeout.add (CLIENT_LAUNCH_TIMEOUT, () => {
                        warning ("Max timeout reached (%u ms): client did not respond.", CLIENT_LAUNCH_TIMEOUT);
                        if (launch_signal_id != 0U) {
                            disconnect (launch_signal_id);
                        }

                        AccessControlLists.setfacl (username, path, AccessControlLists.NO_EXEC_PERMISSIONS);
                        return false;
                    });

                    launch (args, true);
                }
            } catch (Error e) {
                throw e;
            }
        }

        public void add_restriction_for_user (
            string input,
            bool clean,
            BusName sender
        ) throws GLib.Error, ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }

            ensure_pam_lightdm_enabled ();

            var writer = PAM.Writer.new_for_time ();
            writer.add_restriction_for_user (input, clean);
        }

        public void remove_restriction_for_user (
            string username,
            BusName sender
        ) throws GLib.Error, ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }

            var writer = PAM.Writer.new_for_time ();
            writer.remove_restriction_for_user (username);
        }

        public void lock_dock_icons_for_user (
            string username,
            bool lock,
            BusName sender
        ) throws GLib.Error, ParentalControlsError {
            throw new ParentalControlsError.NOT_IMPLEMENTED ("Error: not implemented");
        }

        public void set_user_daemon_active (
            string username,
            bool active,
            BusName sender
        ) throws GLib.Error, ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }

            var config = UserConfig.get_for_username (username, true);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD (
                    "Error: config for %s is not valid or could not be created", username
                );
            }

            config.active = active;
        }

        public void set_user_daemon_targets (
            string username,
            string[] targets,
            BusName sender
        ) throws GLib.Error, ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }

            var config = UserConfig.get_for_username (username, true);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD (
                    "Error: config for %s is not valid or could not be created", username
                );
            }

            config.targets = targets;
        }

        public void set_user_daemon_block_urls (
            string username,
            string[] block_urls,
            BusName sender
        ) throws GLib.Error, ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }

            var config = UserConfig.get_for_username (username, true);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD (
                    "Error: config for %s is not valid or could not be created", username
                );
            }

            config.block_urls = block_urls;
        }

        public void set_user_daemon_admin (
            string username,
            bool admin,
            BusName sender
        ) throws GLib.Error, ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }

            var config = UserConfig.get_for_username (username, true);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD (
                    "Error: config for %s is not valid or could not be created", username
                );
            }

            config.admin = admin;
        }

        public bool get_user_daemon_active (string username) throws GLib.Error, ParentalControlsError {
            var config = UserConfig.get_for_username (username, false);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD (
                    "Error: config for %s is not valid or does not exist", username
                );
            }

            return config.active;
        }

        public string[] get_user_daemon_targets (string username) throws GLib.Error, ParentalControlsError {
            var config = UserConfig.get_for_username (username, false);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD (
                    "Error: config for %s is not valid or does not exist", username
                );
            }

            return config.targets;
        }

        public string[] get_user_daemon_block_urls (string username) throws GLib.Error, ParentalControlsError {
            var config = UserConfig.get_for_username (username, false);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD (
                    "Error: config for %s is not valid or does not exist", username
                );
            }

            return config.block_urls;
        }

        public bool get_user_daemon_admin (string username) throws GLib.Error, ParentalControlsError {
            var config = UserConfig.get_for_username (username, false);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD (
                    "Error: config for %s is not valid or does not exist", username
                );
            }

            return config.admin;
        }

        private void on_config_changed () {
            var current_handler = SessionManager.get_default ().current_handler;
            if (current_handler != null) {
                current_handler.update ();
            }
        }

        private void ensure_pam_lightdm_enabled () {
            // Prioritize user config over system
            var config_dirs = new string [0];
            config_dirs += Environment.get_user_config_dir ();
            foreach (unowned var dir in Environment.get_system_config_dirs ()) {
                config_dirs += dir;
            }

            string? path = null;
            foreach (unowned var dir in config_dirs) {
                var file_path = Path.build_filename (dir, "pam.d", "lightdm");
                if (FileUtils.test (file_path, EXISTS)) {
                    path = file_path;
                    break;
                }
            }

            if (path == null) {
                critical ("No pam.d lightdm found");
                return;
            }

            string contents;
            try {
                FileUtils.get_contents (path, out contents);
            } catch (FileError e) {
                warning (e.message);
                return;
            }

            string conf_line = "\naccount required pam_time.so";
            if (conf_line in contents) {
                return;
            }

            contents += conf_line;

            try {
                FileUtils.set_contents (path, contents);
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }
        }

        private bool get_sender_is_authorized (BusName sender) throws ParentalControlsError {
            if (bus_proxy == null) {
                throw new ParentalControlsError.DBUS_CONNECTION_FAILED (
                    "Error: connecting to org.freedesktop.DBus failed."
                );
            }

            uint32 user = 0, pid = 0;

            try {
                pid = get_pid_from_sender (sender);
                user = bus_proxy.get_connection_unix_user (sender);
            } catch (Error e) {
                warning (e.message);
            }

            var subject = new Polkit.UnixProcess.for_owner ((int)pid, 0, (int)user);

            try {
                var authority = Polkit.Authority.get_sync (null);
                var auth_result = authority.check_authorization_sync (
                    subject,
                    Constants.PARENTAL_CONTROLS_ACTION_ID,
                    null,
                    Polkit.CheckAuthorizationFlags.NONE
                );
                return auth_result.get_is_authorized ();
            } catch (Error e) {
                warning (e.message);
            }

            return false;
        }

        private uint32 get_pid_from_sender (BusName sender) {
            uint32 pid = 0;

            try {
                pid = bus_proxy.get_connection_unix_process_id (sender);
            } catch (Error e) {
                warning (e.message);
            }

            return pid;
        }
    }
}

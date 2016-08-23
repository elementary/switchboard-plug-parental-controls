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
    [DBus (name = "org.freedesktop.DBus")]
    private interface DBus : Object {
        [DBus (name = "GetConnectionUnixProcessID")]
        public abstract uint32 get_connection_unix_process_id (string name) throws IOError;
        
        public abstract uint32 get_connection_unix_user (string name) throws IOError;
    }

    public errordomain ParentalControlsError {
        NOT_AUTHORIZED,
        NOT_IMPLEMENTED,
        USER_CONFIG_NOT_VAILD,
        DBUS_CONNECTION_FAILED
    }

    [DBus (name = "org.pantheon.ParentalControls")]
    public class Server : Object {

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
        }

        [DBus (visible = false)]
        public signal void app_authorization_ended (int client_pid);

        public signal void app_authorize (string user, string path, string action_id);
        public signal void launch (string[] args);
        public signal void show_app_unavailable (string path);
        public signal void show_timeout (int hours, int minutes);
        public signal void user_config_changed (string username);

        public void end_app_authorization (BusName sender) {
            uint32 pid = get_pid_from_sender (sender);
            app_authorization_ended ((int)pid);
        }

        public void enable_restriction (string username, bool enable, BusName sender) throws ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }
        }

        public void remove_restriction (string username, BusName sender) throws ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }
        }

        public void add_pam_restriction (string input, BusName sender) throws ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }            
        }

        public void lock_dock_icons (string username, bool lock, BusName sender) throws ParentalControlsError {
            throw new ParentalControlsError.NOT_IMPLEMENTED ("Error: not implemented");
        }

        public void set_user_daemon_active (string username, bool active, BusName sender) throws ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }

            var config = UserConfig.get_for_username (username);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD ("Error: config for %s is not valid or does not exist".printf (username));
            }

            config.set_active (active);
        }

        public void set_user_daemon_targets (string username, string[] targets, BusName sender) throws ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }

            var config = UserConfig.get_for_username (username);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD ("Error: config for %s is not valid or does not exist".printf (username));
            }

            config.set_targets (targets);
        }

        public void set_user_daemon_block_urls (string username, string[] urls, BusName sender) throws ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }  

            var config = UserConfig.get_for_username (username);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD ("Error: config for %s is not valid or does not exist".printf (username));
            }                         
        }

        public void set_user_daemon_admin (string username, bool admin, BusName sender) throws ParentalControlsError {
            if (!get_sender_is_authorized (sender)) {
                throw new ParentalControlsError.NOT_AUTHORIZED ("Error: sender not authorized");
            }

            var config = UserConfig.get_for_username (username);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD ("Error: config for %s is not valid or does not exist".printf (username));
            }

            config.set_admin (admin);
        }

        public bool get_user_daemon_active (string username) throws ParentalControlsError {
            var config = UserConfig.get_for_username (username);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD ("Error: config for %s is not valid or does not exist".printf (username));
            }

            return config.get_active ();
        }

        public string[] get_user_daemon_targets (string username) throws ParentalControlsError {
            var config = UserConfig.get_for_username (username);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD ("Error: config for %s is not valid or does not exist".printf (username));
            }

            return config.get_targets ();
        }

        public string[] get_user_daemon_block_urls (string username) throws ParentalControlsError {
            var config = UserConfig.get_for_username (username);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD ("Error: config for %s is not valid or does not exist".printf (username));
            }

            return config.get_block_urls ();
        }

        public bool get_user_daemon_admin (string username) throws ParentalControlsError {
            var config = UserConfig.get_for_username (username);
            if (config == null) {
                throw new ParentalControlsError.USER_CONFIG_NOT_VAILD ("Error: config for %s is not valid or does not exist".printf (username));
            }

            return config.get_admin ();
        }

        private bool get_sender_is_authorized (BusName sender) {
            if (bus_proxy == null) {
                throw new ParentalControlsError.DBUS_CONNECTION_FAILED ("Error: connecting to org.freedesktop.DBus failed.");
            }

            uint32 user = 0, pid = 0;

            try {
                pid = get_pid_from_sender (sender);
                user = bus_proxy.get_connection_unix_user (sender);
            } catch (Error e) {
                warning (e.message);
            }            

            var subject = Polkit.UnixProcess.new_for_owner ((int)pid, 0, (int)user);

            var authority = Polkit.Authority.get_sync (null);
            var auth_result = authority.check_authorization_sync (subject, Vars.PARENTAL_CONTROLS_ACTION_ID, null, Polkit.CheckAuthorizationFlags.NONE);

            return auth_result.get_is_authorized ();
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
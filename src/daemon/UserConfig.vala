// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015-2016 Adam Bieńkowski (https://launchpad.net/switchboard-plug-parental-controls)
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
    public class UserConfig : Object {
        public string username { get; set; }

        private static KeyFile key;
        private static List<UserConfig> config_list;

        public static UserConfig? get_for_username (string username, bool create) {
            foreach (UserConfig config in config_list) {
                if (config.username == username) {
                    return config;
                }
            }

            if (create) {
                return create_for_username (username);
            }            

            return null;
        }

        public static List<UserConfig> get_all () {
            return config_list.copy ();
        }

        public static void init () {
            config_list = new List<UserConfig> ();

            key = new KeyFile ();
            key.set_list_separator (';');

            if (!init_config_file ()) {
                return;
            }

            try {
                key.load_from_file (Constants.DAEMON_CONF_FILE, KeyFileFlags.KEEP_COMMENTS | KeyFileFlags.KEEP_TRANSLATIONS);
            } catch (KeyFileError e) {
                warning (e.message);
            } catch (FileError e) {
                warning (e.message);
            }
            
            foreach (string username in key.get_groups ()) {
                var user_config = new UserConfig (username);
                config_list.append (user_config);
            }
        }

        private static bool init_config_file () {
            var file = File.new_for_path (Constants.DAEMON_CONF_FILE);
            if (!file.query_exists ()) {
                critical ("Could not find daemon config file: %s does not exist".printf (file.get_path ()));
                return false;
            }

            return true;
        }

        private static UserConfig? create_for_username (string username) {
            var user = Utils.get_usermanager ().get_user (username);
            if (user == null) {
                return null;
            }

            var config = new UserConfig (username);
            config.set_active (false);
            config_list.append (config);
            return config;
        }

        private UserConfig (string username) {
            this.username = username;
        }

        public void set_active (bool active) {
            key.set_boolean (username, Constants.DAEMON_KEY_ACTIVE, active);
            save ();
        }

        public void set_targets (string[] targets) {
            key.set_string_list (username, Constants.DAEMON_KEY_TARGETS, targets);
            save ();
        }

        public void set_block_urls (string[] block_urls) {
            key.set_string_list (username, Constants.DAEMON_KEY_BLOCK_URLS, block_urls);
            save ();
        }

        public void set_admin (bool admin) {
            key.set_boolean (username, Constants.DAEMON_KEY_ADMIN, admin);
            save ();
        }

        public bool get_active () {
            try {
                return key.get_boolean (username, Constants.DAEMON_KEY_ACTIVE);
            } catch (KeyFileError e) {
                warning (e.message);
            }

            return false;
        }

        public string[] get_targets () {
            try {            
                return key.get_string_list (username, Constants.DAEMON_KEY_TARGETS);
            } catch (KeyFileError e) {
                warning (e.message);
            }   

            return {};         
        }

        public string[] get_block_urls () {
            try {
                return key.get_string_list (username, Constants.DAEMON_KEY_BLOCK_URLS);
            } catch (KeyFileError e) {
                warning (e.message);
            }

            return {};                
        }

        public bool get_admin () {
            try {
                return key.get_boolean (username, Constants.DAEMON_KEY_ADMIN);
            } catch (KeyFileError e) {
                warning (e.message);
            }

            return false;
        }

        private void save () {
            try {
                key.save_to_file (Constants.DAEMON_CONF_FILE);
            } catch (FileError e) {
                warning (e.message);
                return;
            }

            Server.get_default ().config_changed ();
        }
    }
}
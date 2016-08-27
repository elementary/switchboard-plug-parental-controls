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
        public string username;
        public signal void changed ();

        private KeyFile key;
        private string config_path;

        private static List<UserConfig> config_list;

        public static UserConfig? get_for_username (string username) {
            foreach (UserConfig config in config_list) {
                if (config.username == username) {
                    return config;
                }
            }

            return null;
        }

        public static List<UserConfig> get_all () {
            return config_list.copy ();
        }

        public static void init () {
            config_list = new List<UserConfig> ();

            foreach (Act.User user in Utils.get_usermanager ().list_users ()) {
                string config_path = Utils.build_daemon_conf_path (user);
                if (!FileUtils.test (config_path, FileTest.IS_REGULAR)) {
                    continue;
                }

                var key = new KeyFile ();
                key.set_list_separator (';');
                if (!key.load_from_file (config_path, KeyFileFlags.NONE)) {
                    continue;
                }

                var user_config = new UserConfig (config_path, user.get_user_name (), key);;
                config_list.append (user_config);
            }
        }

        public UserConfig (string config_path, string username, KeyFile key) {
            this.username = username;
            this.key = key;
            this.config_path = config_path;
            monitor_file ();
        }

        public void set_active (bool active) {
            key.set_boolean (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_ACTIVE, active);
            save ();
        }

        public void set_targets (string[] targets) {
            key.set_string_list (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_TARGETS, targets);
            save ();
        }

        public void set_block_urls (string[] block_urls) {
            key.set_string_list (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_BLOCK_URLS, block_urls);
            save ();
        }

        public void set_admin (bool admin) {
            key.set_boolean (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_ADMIN, admin);
            save ();
        }

        public bool get_active () {
            return key.get_boolean (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_ACTIVE);
        }

        public string[] get_targets () {
            return key.get_string_list (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_TARGETS);
        }

        public string[] get_block_urls () {
            return key.get_string_list (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_BLOCK_URLS);
        }

        public bool get_admin () {
            return key.get_boolean (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_ADMIN);
        }

        private void monitor_file () {
            var file = File.new_for_path (config_path);
            var monitor = file.monitor (FileMonitorFlags.NONE, null);
            monitor.changed.connect ((src, dest, event) => {
                if (event == FileMonitorEvent.CHANGES_DONE_HINT) {
                    update_key ();

                    Server.get_default ().user_config_changed (username);
                    changed ();
                }
            });
        } 

        private void update_key () {
            key.load_from_file (config_path, KeyFileFlags.NONE);
        }

        private void save () {
            key.save_to_file (config_path);

            Server.get_default ().user_config_changed (username);
            changed ();
        }
    }
}
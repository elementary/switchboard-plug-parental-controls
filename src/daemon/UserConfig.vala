/*-
 * Copyright 2019 elementary, Inc. (https://elementary.io)
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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class PC.Daemon.UserConfiguration : GLib.Object {
    private static GLib.KeyFile key_file;
    private static GLib.HashTable<string, UserConfiguration> configurations;

    public static unowned UserConfiguration? get_for_username (string username, bool create = false) {
        // We need this to be sure that the configurations table will be populated
        typeof(UserConfiguration).ensure ();

        unowned UserConfiguration? config = configurations[username];
        if (config == null && create) {
            // We need to ensure that the user exist before creating a configuration
            var user = Utils.get_usermanager ().get_user (username);
            if (user != null) {
                var new_config = new UserConfiguration (username);
                configurations[username] = new_config;
                config = new_config;
            }
        }

        return config;
    }

    public static Gee.ArrayList<UserConfiguration> get_all () {
        // We need this to be sure that the configurations table will be populated
        typeof(UserConfiguration).ensure ();

        var list = new Gee.ArrayList<UserConfiguration> ();
        configurations.foreach ((key, val) => {
            list.add (val);
        });

        return list;
    }

    static construct {
        configurations = new GLib.HashTable<string, UserConfiguration> (str_hash, str_equal);
        key_file = new GLib.KeyFile ();
        key_file.set_list_separator (';');

        var file = GLib.File.new_for_path (Constants.DAEMON_CONF_FILE);
        if (file.query_exists ()) {
            try {
                key_file.load_from_file (Constants.DAEMON_CONF_FILE, KeyFileFlags.KEEP_COMMENTS | KeyFileFlags.KEEP_TRANSLATIONS);
            } catch (GLib.Error e) {
                critical (e.message);
            }

            string[] usernames = key_file.get_groups ();
            foreach (unowned string username in usernames) {
                configurations[username] = new UserConfiguration (username);
            }
        } else {
            critical ("Failed to load configuration file: %s does not exist", file.get_path ());
        }
    }

    public string username { get; construct; }
    public bool active {
        get {
            try {
                return key_file.get_boolean (username, Constants.DAEMON_KEY_ACTIVE);
            } catch (Error e) {
                debug (e.message);
                return false;
            }
        }
        set {
            key_file.set_boolean (username, Constants.DAEMON_KEY_ACTIVE, value);
            save ();
        }
    }

    public string[] targets {
        owned get {
            try {
                return key_file.get_string_list (username, Constants.DAEMON_KEY_TARGETS);
            } catch (Error e) {
                debug (e.message);
                return {};
            }
        }
        set {
            key_file.set_string_list (username, Constants.DAEMON_KEY_TARGETS, value);
            save ();
        }
    }

    public string[] block_urls {
        owned get {
            try {
                return key_file.get_string_list (username, Constants.DAEMON_KEY_BLOCK_URLS);
            } catch (Error e) {
                debug (e.message);
                return {};
            }
        }
        set {
            key_file.set_string_list (username, Constants.DAEMON_KEY_BLOCK_URLS, value);
            save ();
        }
    }
    public bool admin {
        get {
            try {
                return key_file.get_boolean (username, Constants.DAEMON_KEY_ADMIN);
            } catch (Error e) {
                debug (e.message);
                return false;
            }
        }
        set {
            key_file.set_boolean (username, Constants.DAEMON_KEY_ADMIN, value);
            save ();
        }
    }

    private UserConfiguration (string username) {
        Object (username: username);
    }

    private void save () {
        try {
            key_file.save_to_file (Constants.DAEMON_CONF_FILE);
        } catch (FileError e) {
            critical (e.message);
            return;
        }

        Server.get_default ().config_changed ();
    }
}

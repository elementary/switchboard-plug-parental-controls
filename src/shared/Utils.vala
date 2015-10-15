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

namespace PC.Utils {
    public static Polkit.Permission? permission = null;

    public static Polkit.Permission? get_permission () {
            if (permission != null)
                return permission;
            try {
                var user = Polkit.UnixUser.new_for_name (Environment.get_user_name ()) as Polkit.UnixUser;
                permission = new Polkit.Permission.sync ("org.pantheon.switchboard.parental-controls.administration",
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
        string[] spawn_args = { "pkexec", "parental-control-cli" };
        foreach (string arg in args) {
            spawn_args += arg;
        }

        try {
            string[] spawn_env = Environ.get ();
            Process.spawn_async ("/",
                                spawn_args,
                                spawn_env,
                                SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                null,
                                null);
        } catch (SpawnError e) {
            warning ("%s\n", e.message);
        }
    }

    public bool list_contains (List list, List.G data) {
        foreach (var unit in list.copy ()) {
            if (unit == data) {
                return true;
            }
        }

        return false;
    }

    private static Act.UserManager? usermanager = null;

    public static unowned Act.UserManager? get_usermanager () {
        if (usermanager != null && usermanager.is_loaded) {
            return usermanager;
        }

        usermanager = Act.UserManager.get_default ();
        return usermanager;
    }

    private static Act.User? current_user = null;

    public static unowned Act.User? get_current_user () {
        if (current_user != null) {
            return current_user;
        }

        current_user = get_usermanager ().get_user (GLib.Environment.get_user_name ());
        return current_user;
    }

    public string? build_app_lock_path (Act.User user) {
        return user.get_home_dir () + Vars.APP_LOCK_CONF_DIR;
    }

    public static string get_display_manager () {
        //TODO: add file location for different, non-debian-based distros
        string file = "/etc/X11/default-display-manager";
        string output = "";

        try {
            FileUtils.get_contents (file, out output);
        } catch (Error e) {
            warning (e.message);
            return "";
        }

        output = output.slice (output.last_index_of ("/") + 1, output.length).chomp ();
        return output;
    }

    public static void try_lock_dock_for_user (string user_name, bool lock) {
        if (Utils.get_permission ().allowed) {
            Utils.call_cli ({"--home-dir", user_name, "--lock-dock", (!lock).to_string ()});
        }
    }

}

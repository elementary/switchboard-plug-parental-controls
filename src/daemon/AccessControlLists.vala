// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2019 Adam Bieńkowski (https://github.com/elementary/switchboard-plug-parental-controls)
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

public class PC.AccessControlLists {
    public const string DEFAULT_PERMISSIONS = "r-x";
    public const string NO_EXEC_PERMISSIONS = "---";

    private static AppInfo? get_match (string target, List<AppInfo> infos) {
        string basename = Path.get_basename (target);
        foreach (var info in infos) {
            if (info.should_show () && info.get_executable () == basename) {
                return info;
            }
        }

        return null;
    }

    private static File? create_desktop_files_dir (string username) {
        string local_appdir = Path.build_filename (GLib.Path.DIR_SEPARATOR_S, "home", username, ".local", "share", "applications");
        var appdir_file = File.new_for_path (local_appdir);
        if (!appdir_file.query_exists ()) {
            try {
                if (!appdir_file.make_directory_with_parents ()) {
                    return null;
                }
            } catch (Error e) {
                warning (e.message);
                return null;
            }
        }

        return appdir_file;
    }

    private static string? process_desktop_entry (string path, string target, string username, bool admin) {
        var keyfile = new KeyFile ();
        try {
            keyfile.load_from_file (path, KeyFileFlags.KEEP_COMMENTS | KeyFileFlags.KEEP_TRANSLATIONS);
        } catch (KeyFileError e) {
            warning (e.message);
            return null;
        } catch (FileError e) {
            warning (e.message);
            return null;
        }

        string[] args;
        string exec = Utils.info_to_exec_path (new DesktopAppInfo.from_keyfile (keyfile), out args);

        if (admin) {
            args[0] = exec;
            keyfile.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_EXEC,
                "%s -a \"%s:%s:%s\"".printf (Constants.CLIENT_PATH, username, Constants.PARENTAL_CONTROLS_ACTION_ID, string.joinv (" ", args)));
        } else {
            keyfile.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_EXEC,
                "%s -d %s".printf (Constants.CLIENT_PATH, exec));
        }

        return keyfile.to_data ();
    }

    public static bool get_supported () {
        return Environment.find_program_in_path ("setfacl") != null;
    }

    public static void setfacl (string username, string target, string permissions_str) {
        string r = "u:%s:%s".printf (username, permissions_str);
        try {
            Process.spawn_async (null,
                { "setfacl", "-m", r, target },
                null,
                SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                null,
                null);
        } catch (SpawnError e) {
            warning (e.message);
        }
    }

    private static void apply_permissions (string username, string[] targets, string permissions_str, bool admin) {
        foreach (var target in targets) {
            setfacl (username, target, permissions_str);
        }

        var infos = AppInfo.get_all ();
        foreach (var target in targets) {
            var match = get_match (target, infos);
            if (match == null || !(match is DesktopAppInfo)) {
                continue;
            }

            unowned string target_filename = ((DesktopAppInfo)match).get_filename ();
            if (target_filename == null) {
                continue;
            }

            var appdir_file = create_desktop_files_dir (username);
            var target_file = File.new_for_path (target_filename);
            if (!target_file.query_exists () || appdir_file == null) {
                continue;
            }

            var dest = appdir_file.get_child (target_file.get_basename ());
            if (dest.query_exists ()) {
                if (permissions_str == DEFAULT_PERMISSIONS) {
                    try {
                        dest.delete ();
                    } catch (Error e) {
                        warning (e.message);
                    }
                    
                    continue;
                }
            }

            string? contents = process_desktop_entry (target_file.get_path (), target, username, admin);
            if (contents == null) {
                continue;
            }

            try {
                var os = dest.create (FileCreateFlags.REPLACE_DESTINATION);
                os.write_all (contents.data, null);
                os.close ();
            } catch (Error e) {
                warning (e.message);
            }
        }
    }

    public static void apply_targets (string username, string[] old_targets, string[] targets, bool old_admin, bool admin) {
        apply_permissions (username, old_targets, DEFAULT_PERMISSIONS, old_admin);
        apply_permissions (username, targets, NO_EXEC_PERMISSIONS, admin);
    }
}
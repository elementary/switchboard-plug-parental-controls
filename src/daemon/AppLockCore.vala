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

namespace PC.Daemon.AppLock {
    public class AppLockCore : GLib.Object, ExecMonitor {
        private Act.User user;

        // Config info
        private string[] targets = {};
        private bool admin = false;

        // Allowed executables
        private List<string> allowed_executables;

        // If AppLock needs to watch specific user
        public bool valid = true;

        public AppLockCore (Act.User _user) {
            this.user = _user;
            this.allowed_executables = new List<string> ();

            if (user == null) {
                valid = false;
                return;
            }

            string lock_path = Path.build_filename (user.get_home_dir (), Vars.APP_LOCK_CONF_DIR);
            if (FileUtils.test (lock_path, FileTest.EXISTS)) {
                var key_file = new KeyFile ();
                try {
                    key_file.load_from_file (Utils.build_app_lock_path (user), 0);

                    targets = key_file.get_string_list (Vars.APP_LOCK_GROUP, Vars.APP_LOCK_TARGETS);
                    if (targets.length == 0) {
                        valid = false;
                    }

                    admin = key_file.get_boolean (Vars.APP_LOCK_GROUP, Vars.APP_LOCK_ADMIN);
                } catch (FileError e) {
                    warning ("%s\n", e.message);
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            }        
        }

        private void handle_pid (int pid) {
            var process = new Process (pid);

            if (process.get_command () == "") {
                return;
            }

            string[] args = process.get_command ().split (" ");
            string executable = args[0];
            foreach (string _executable in allowed_executables) {
                if (_executable == executable) {
                    allowed_executables.remove (_executable);
                    return;
                }
            }

            if (executable != null && !executable.has_prefix ("/")) {
                executable = Environment.find_program_in_path (executable);
            }

            if (executable != null && executable != "") {
                if (executable in targets) {
                    process.kill ();

                    if (admin && Utils.get_permission () != null) {
                        var permission = Utils.get_permission ();

                        if (permission.get_can_acquire ()) {
                            permission.acquire_async.begin ();
                        }

                        ulong signal_id = 0;
                        signal_id = permission.notify["allowed"].connect (() => {
                            process_permission (permission, args);
                            permission.disconnect (signal_id);
                        });
                    } else {
                        show_app_lock_dialog ();
                    }
                }
            }  
        }

        private void process_permission (Polkit.Permission permission, string[] args) {
            if (permission.get_allowed ()) {
                string[] _args = {};
                for (int i = 0; i < args.length; i++) {
                    if (args[i].strip () != "") {
                        _args[i] = args[i];
                    }
                }

                try {
                    GLib.Process.spawn_async ("/",
                                            _args,
                                            Environ.get (),
                                            SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                            null,
                                            null);
                    allowed_executables.append (args[0]);
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            }

            if (permission.get_can_release ()) {
                try {
                    permission.release ();
                } catch (Error e) {
                    warning ("%s\n", e.message);    
                }
            }
        }

        private void show_app_lock_dialog () {
            Idle.add (() => {
                var lock_dialog = new AppLockDialog ();
                lock_dialog.run ();
                return false;
            });
        }
    }
}
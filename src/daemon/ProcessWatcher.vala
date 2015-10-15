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
    public class ProcessWatcher : Object {
        private List<Process> process_list;
        private string user;

        // Represents current running pids that were unlocked by admin permission
        private Gee.ArrayList<Pid> locked_pids;
        private File proc_dir;

        // Config info
        private string[] targets = {};
        private bool admin = false;

        // If ProcessWatcher needs to watch specific user
        private bool valid = false;

        public static void watch_app_usage (string user) {
            new ProcessWatcher (user);
        }

        private ProcessWatcher (string user) {
            this.user = user;
            process_list = new List<Process> ();
            locked_pids = new Gee.ArrayList<Pid> ();

            var act_user = Utils.get_usermanager ().get_user (user);
            if (act_user != null) {
                string lock_path = act_user.get_home_dir () + Vars.APP_LOCK_CONF_DIR;
                if (FileUtils.test (lock_path, FileTest.EXISTS)) {
                    var key_file = new KeyFile ();
                    try {
                        key_file.load_from_file (Utils.build_app_lock_path (act_user), 0);

                        targets = key_file.get_string_list (Vars.APP_LOCK_GROUP, Vars.APP_LOCK_TARGETS);
                        admin = key_file.get_boolean (Vars.APP_LOCK_GROUP, Vars.APP_LOCK_ADMIN);
                    } catch (FileError e) {
                        warning ("%s\n", e.message);
                        return;
                    } catch (Error e) {
                        warning ("%s\n", e.message);
                        return;
                    }

                    valid = true;
                    proc_dir = File.new_for_path ("/proc/");
                    Timeout.add (1000, update);
                }
            }
        }

        public bool update () {
            if (valid) {
                try {
                    var dir_enumerator = proc_dir.enumerate_children ("standard::*", 0);

                    FileInfo info;

                    while ((info = dir_enumerator.next_file ()) != null) {
                        int pid = 0;

                        if ((info.get_file_type () == FileType.DIRECTORY)
                            && ((pid = int.parse (info.get_name ())) != 0)) {
                            bool has_pid = false;
                            foreach (var process in process_list) {
                                if (process.get_pid () == pid) {
                                    has_pid = true;
                                    break;
                                }
                            }

                            if (!has_pid && !locked_pids.contains (pid)) {
                                process_pid (pid);
                            }
                        }
                    }
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            }

            return valid;
        }

        private void process_pid (int pid) {
            var process = new Process (pid);
            process_list.append (process);

            if (process.get_command () == "") {
                return;
            }

            string[] args = process.get_command ().split (" ");
            string executable = args[0];

            if (executable != null && !executable.has_prefix ("/")) {
                executable = Environment.find_program_in_path (executable);
            }

            if (executable != null && executable != "") {
                if (executable in targets) {
                    process.kill ();
                    process_list.remove (process);

                    if (admin) {
                        try {
                            if (Utils.get_permission ().get_can_release ()) {
                                Utils.get_permission ().release ();
                            }

                            Utils.permission = null;
                            if (Utils.get_permission ().get_can_acquire ()) {
                                Utils.get_permission ().acquire_async.begin ();
                            }

                            Utils.get_permission ().notify["allowed"].connect (() => {
                                if (Utils.get_permission ().get_allowed ()) {
                                    try {
                                        string[] spawn_env = Environ.get ();
                                        Pid child_pid;

                                        GLib.Process.spawn_async ("/",
                                                                args,
                                                                spawn_env,
                                                                SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                                                                null,
                                                                out child_pid);
                                        locked_pids.add (child_pid);

                                        ChildWatch.add (child_pid, (pid, status) => {
                                            locked_pids.remove (pid);
                                            GLib.Process.close_pid (pid);
                                        });
                                    } catch (SpawnError e) {
                                        warning ("%s\n", e.message);
                                    }
                                }
                            });
                        } catch (Error e) {
                            warning ("%s\n", e.message);
                        }
                    } else {
                        var lock_dialog = new AppLockDialog ();
                        lock_dialog.response.connect (() => {
                            lock_dialog.destroy ();
                        });

                        lock_dialog.show_all ();
                    }
                }
            }
        }
    }
}
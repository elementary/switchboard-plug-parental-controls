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
    public class ProcessWatcher : Object {
        private List<Process> process_list;
        private string user;

        public static ProcessWatcher watch_app_usage (string user) {
            var watcher = new ProcessWatcher (user);
            return watcher;
        }

        private ProcessWatcher (string user) {
            this.user = user;
            process_list = new List<Process> ();
        }

        public void update () {
            try {
                var proc_dir = File.new_for_path ("/proc/");
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

                        if (!has_pid) {
                            process_pid (pid);
                        }
                    }
                }
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }

        private void process_pid (int pid) {
            var process = new Process (pid);
            process_list.append (process);


            string executable = process.get_command ().split (" ")[0];
            string lock_path = Utils.get_usermanager ().get_user (user).get_home_dir () + "/.config/app-lock.conf";
            if (!File.new_for_path (lock_path).query_exists ()) {
                return;
            }

            if (executable != null && !executable.has_prefix ("/")) {
                executable = Environment.find_program_in_path (executable);
            }

            var key_file = new KeyFile ();
            key_file.load_from_file (lock_path, 0);

            if (executable != null && executable in key_file.get_string_list ("AppLock", "Targets")) {
                process.kill ();
                process_list.remove (process);
            }
        }
    }
}
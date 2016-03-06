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
    public class Core : GLib.Object, ExecMonitor {
        public bool valid = true;
        public KeyFile key_file;

        private Act.User user;

        private string[] targets = {};
        private bool admin = false;

        private List<string> allowed_executables;

        private Polkit.Authority authority;
        private Server server;

        public Core (Act.User _user, Server _server) {
            user = _user;
            server = _server;
            allowed_executables = new List<string> ();
            try {
                authority = Polkit.Authority.get_sync ();
            } catch (Error e) {
                warning ("%s\n", e.message);
            }

            if (user == null) {
                valid = false;
                return;
            }

            key_file = new KeyFile ();

            string lock_path = Utils.build_daemon_conf_path (user);
            if (FileUtils.test (lock_path, FileTest.EXISTS)) {
                try {
                    key_file.load_from_file (Utils.build_daemon_conf_path (user), 0);

                    targets = key_file.get_string_list (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_TARGETS);
                    admin = key_file.get_boolean (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_ADMIN);

                    valid = targets.length > 0;
                } catch (FileError e) {
                    warning ("%s\n", e.message);
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            } else {
                valid = false;
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

                    if (admin && authority != null) {
                        server.authorize (user.get_user_name (), Vars.PARENTAL_CONTROLS_ACTION_ID);
                        ulong signal_id = 0;
                        signal_id = server.authorization_ended.connect ((client_pid) => {
                            try {
                                var result = authority.check_authorization_sync (Polkit.UnixProcess.new_for_owner (client_pid, 0, (int)user.get_uid ()),
                                                                                Vars.PARENTAL_CONTROLS_ACTION_ID,
                                                                                null,
                                                                                Polkit.CheckAuthorizationFlags.ALLOW_USER_INTERACTION);
                                if (result.get_is_authorized ()) {
                                    allowed_executables.append (args[0]);                                
                                    server.launch (args);
                                }   
                            } catch (Error e) {
                                warning ("%s\n", e.message);
                            }

                            server.disconnect (signal_id);
                        });
                    } else {
                        server.show_app_lock_dialog ();
                    }
                }
            }  
        }
    }
}
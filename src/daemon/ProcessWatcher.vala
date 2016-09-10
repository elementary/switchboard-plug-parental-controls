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
    public class ProcessWatcher : GLib.Object, ExecMonitor {
        public UserConfig? config = null;
        private List<string> allowed_executables;
        private Polkit.Authority authority;

        public ProcessWatcher () {
            allowed_executables = new List<string> ();

            try {
                authority = Polkit.Authority.get_sync ();
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }

        public void set_config (UserConfig? config) {
            this.config = config;
            allowed_executables = new List<string> ();
        }

        private void handle_pid (int pid) {
            if (config == null || !config.get_active ()) {
                return;
            }

            var process = new Process (pid);

            string? command = process.get_command ();
            if (command == null || command == "") {
                return;
            }

            string[]? args = {};
            try {
                Shell.parse_argv (command, out args);
                if (args == null || args.length < 1) {
                    return;
                }
            } catch (ShellError e) {
                warning ("%s\n", e.message);
                return;
            }                

            string executable = args[0];

            if (!executable.has_prefix (Path.DIR_SEPARATOR_S)) {
                executable = Environment.find_program_in_path (executable);
            }

            unowned List<string> link = allowed_executables.find_custom (executable, strcmp);
            if (link != null) {
                allowed_executables.remove_link (link);
                return;
            }

            if (executable != null && executable in config.get_targets ()) {
                process.kill ();

                var server = Server.get_default ();
                if (config.get_admin () && authority != null) {
                    ulong signal_id = 0;
                    signal_id = server.app_authorization_ended.connect ((client_pid) => {
                        try {
                            var unix_user = (Polkit.UnixUser)Polkit.UnixUser.new_for_name (config.username);
                            var result = authority.check_authorization_sync (Polkit.UnixProcess.new_for_owner (client_pid, 0, unix_user.get_uid ()),
                                                                            Constants.PARENTAL_CONTROLS_ACTION_ID,
                                                                            null,
                                                                            Polkit.CheckAuthorizationFlags.NONE);
                            if (result.get_is_authorized ()) {
                                allowed_executables.append (executable);
                                server.launch (args);
                            }
                        } catch (Error e) {
                            warning ("%s\n", e.message);
                        }

                        server.disconnect (signal_id);
                    });

                    server.app_authorize (config.username, executable, Constants.PARENTAL_CONTROLS_ACTION_ID);
                } else {
                    server.show_app_unavailable (executable);
                }
            }  
        }
    }
}
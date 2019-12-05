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
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

namespace PC.Daemon {
    public class AppRestriction : Restriction<string>, ExecMonitor {
        public string username { get; set; }
        public bool admin { get; set; }

        private Gee.ArrayList<string> allowed_executables;
        private Polkit.Authority authority;

        construct {
            allowed_executables = new Gee.ArrayList<string> ();

            try {
                authority = Polkit.Authority.get_sync ();
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }

        public override void start () {
            start_monitor.begin ();
        }

        public override void stop () {
            stop_monitor ();
            allowed_executables.clear ();
        }

        private void handle_pid (int pid) {
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

            if (allowed_executables.contains (executable)) {
                allowed_executables.remove (executable);
                return;
            }

            if (executable == null || targets.find_custom (executable, strcmp) == null) {
                return;
            }

            process.kill ();

            var server = Server.get_default ();
            if (!admin || authority == null) {
                server.show_app_unavailable (executable);
                return;
            }

            ulong signal_id = 0;
            signal_id = server.app_authorization_ended.connect ((client_pid) => {
                try {
                    var unix_user = new Polkit.UnixUser.for_name (username);
                    var result = authority.check_authorization_sync (
                                    new Polkit.UnixProcess.for_owner (client_pid, 0, unix_user.get_uid ()),
                                    Constants.PARENTAL_CONTROLS_ACTION_ID,
                                    null,
                                    Polkit.CheckAuthorizationFlags.NONE
                                );

                    if (result.get_is_authorized ()) {
                        allowed_executables.add (executable);
                        server.launch (args);
                    }
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }

                server.disconnect (signal_id);
            });

            server.app_authorize (username, executable, Constants.PARENTAL_CONTROLS_ACTION_ID);
        }
    }
}

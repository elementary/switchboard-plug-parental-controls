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
    public class Process : Object {
        private int pid;
        private string command = "";

        public Process (int pid) {
            this.pid = pid;

            var cmd_file = File.new_for_path ("/proc/%d/cmdline".printf (pid));
            if (!cmd_file.query_exists ()) {
                return;
            }

            try {
                var dis = new DataInputStream (cmd_file.read ());
                uint8[] data = new uint8[4097];
                var size = dis.read (data);

                if (size <= 0) {
                    command = "";
                }

                for (int pos = 0; pos < size; pos++) {
                    if (data[pos] == '\0' || data[pos] == '\n') {
                        data[pos] = ' ';
                    }
                }

                command = (string) data;
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }

        public string get_command () {
            return command;
        }

        public void kill () {
            Posix.kill (pid, Posix.SIGINT);
        }
    }
}

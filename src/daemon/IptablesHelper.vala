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

 namespace PC {
    public class IptablesHelper : Object {
        public bool valid = false;

        private const string IPTABLES_EXEC = "iptables";
        private const string HOST_EXEC = "host";
        private const int ADDRESS_INDEX = 3;
        private const int DPORT = 80;

        private string[] urls;

        public IptablesHelper (string[] urls) {
            this.urls = urls;
            valid = Environment.find_program_in_path (IPTABLES_EXEC) != null &&
                    Environment.find_program_in_path (HOST_EXEC) != null &&
                    urls.length > 0;
        }

        public void add_rules () {
            foreach (string url in urls) {
                string[] addresses = get_addresses_from_url (url);
                foreach (string address in addresses) {
                    block_address (address, "-A");
                }
            }        
        }

        private string[] get_addresses_from_url (string url) {
            string[] result = {};

            string output;
            int status;

            try {
                GLib.Process.spawn_sync ("/",
                                    { HOST_EXEC, url },
                                    Environ.get (),
                                    SpawnFlags.SEARCH_PATH,
                                    null,
                                    out output,
                                    null,
                                    out status);
            } catch (SpawnError e) {
                warning ("%s\n", e.message);
            }

            if (status != 0) {
                return result;
            }

            foreach (string line in output.split ("\n")) {
                if (line.contains ("has address")) {
                    string[] elements = line.split (" ");
                    if (elements.length >= 3) {
                        result += elements[ADDRESS_INDEX];
                    }
                }
            }

            return result;
        }

        private void block_address (string address, string option) {
            try {
                GLib.Process.spawn_sync ("/",
                                    { IPTABLES_EXEC, option, "OUTPUT", "-p", "tcp", "-d", address, "--dport", DPORT.to_string (), "-j", "REJECT" },
                                    Environ.get (),
                                    SpawnFlags.SEARCH_PATH,
                                    null,
                                    null,
                                    null,
                                    null);
            } catch (SpawnError e) {
                warning ("%s\n", e.message);
            }
        }

        public void reset () {
            foreach (string url in urls) {
                string[] addresses = get_addresses_from_url (url);
                foreach (string address in addresses) {
                    block_address (address, "-D");
                }
            }  
        }
    }
}
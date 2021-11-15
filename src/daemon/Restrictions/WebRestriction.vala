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
    public class WebRestriction : Restriction {
        private const string IPTABLES_EXEC = "iptables";
        private const int BYTES = 65535;

        public new static bool get_supported () {
            return Environment.find_program_in_path (IPTABLES_EXEC) != null;
        }

        public WebRestriction (UserConfig config) {
            base (config);
        }

        public override void start () {
            foreach (string url in config.block_urls) {
                if (check_address_from_name (url)) {
                    process_adress (url, "-A", "INPUT");
                    process_adress (url, "-A", "OUTPUT");
                }
            }
        }

        public override void stop () {
            foreach (string url in config.block_urls) {
                if (check_address_from_name (url)) {
                    process_adress (url, "-D", "INPUT");
                    process_adress (url, "-D", "OUTPUT");
                }
            }
        }

        // Check the host name before adding it to iptables
        private bool check_address_from_name (string name) {
            var resolver = Resolver.get_default ();
            try {
                var addresses = resolver.lookup_by_name (name, null);
                foreach (InetAddress address in addresses) {
                    if (address.get_family () == SocketFamily.IPV4) {
                        return true;
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }
            return false;
        }

        private void process_adress (string url, string option, string filter) {
            try {
                string[] argv = { IPTABLES_EXEC, option, filter, "-m", "string", "--string", @"$url",
                                  "--algo", "kmp", "--to", BYTES.to_string (), "-j", "DROP" };

                GLib.Process.spawn_sync ("/",
                                    argv,
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
    }
}

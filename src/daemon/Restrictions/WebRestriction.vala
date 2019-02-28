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
        private const int DPORT = 80;

        public new static bool get_supported () {
            return Environment.find_program_in_path (IPTABLES_EXEC) != null;
        }

        public WebRestriction (UserConfig config) {
            base (config);
        }

        public override void start () {
            foreach (string url in config.block_urls) {
                string[] addresses = get_addresses_from_name (url);
                foreach (string address in addresses) {
                    process_adress (address, "-A");
                }
            }      
        }

        public override void stop () {
            foreach (string url in config.block_urls) {
                string[] addresses = get_addresses_from_name (url);
                foreach (string address in addresses) {
                    process_adress (address, "-D");
                }
            }  
        }

        private string[] get_addresses_from_name (string name) {
            string[] address_list = {};
            var resolver = Resolver.get_default ();
            try {
                var addresses = resolver.lookup_by_name (name, null);
                foreach (InetAddress address in addresses) {
                    if (address.get_family () == SocketFamily.IPV4) {
                        address_list += address.to_string ();
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }

            return address_list;
        }

        private void process_adress (string address, string option) {
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
    }
}
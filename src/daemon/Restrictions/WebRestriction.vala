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
        private string[] old_urls = {};

        public new static bool get_supported () {
            return Environment.find_program_in_path (IPTABLES_EXEC) != null;
        }

        public WebRestriction (UserConfig config) {
            base (config);
        }

        public override void start () {
            update (Constants.DAEMON_KEY_BLOCK_URLS);  
        }

        public override void stop () {
            process_urls (config.get_block_urls (), false);
        }

        public override void update (string key) {
            if (key != Constants.DAEMON_KEY_BLOCK_URLS) {
                return;
            }
            
            process_urls (old_urls, false);
            old_urls = config.get_block_urls ();
            process_urls (old_urls, true);
        }

        private void process_urls (string[] urls, bool block) {
            foreach (string url in urls) {
                process_adress (url, block ? "-A" : "-D");
            }  
        }

        private static void process_adress (string address, string option) {
            try {
                GLib.Process.spawn_sync ("/",
                                    { IPTABLES_EXEC, option, "OUTPUT", "-p", "tcp", "-m", "string", "--string", address, "--algo", "kmp", "-j", "REJECT" },
                                    Environ.get (),
                                    SpawnFlags.SEARCH_PATH,
                                    null,
                                    null,
                                    null,
                                    null);
            } catch (SpawnError e) {
                warning (e.message);
            }
        }
    }
}

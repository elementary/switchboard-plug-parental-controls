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
    public class SessionHandler : Object {
        public ProcessWatcher core;
        public IptablesHelper iptables_helper;
        public Timer? timer;

        private ISession session;
        private Server server;

        private bool can_start = true;

        public SessionHandler (ISession session) {
            this.session = session;
            server = Server.get_default ();

            var config = UserConfig.get_for_username (session.name);
            if (config == null || !config.get_active ()) {
                can_start = false;
                return;
            }

            core = new ProcessWatcher (config);
            iptables_helper = new IptablesHelper (config);

            var token = PAM.Reader.get_token_for_user (Vars.PAM_TIME_CONF_PATH, session.name);
            if (token != null) {
                timer = new Timer (token);
                timer.terminate.connect (() => {
                    session.terminate ();
                });
            }
        }

        public void start () {
            if (!can_start) {
                return;
            }

            core.start.begin ();

            if (IptablesHelper.get_can_start ()) {
                iptables_helper.start ();
            }

            if (timer != null) {
                timer.start ();
            }
        }

        public void stop () {
            core.stop ();
            iptables_helper.stop ();
            if (timer != null) {
                timer.stop ();
            }
        }         
    }
}
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
    public class SessionHandler : Object {
        private RestrictionController controller;

        private AppRestriction app_restriction;
        private WebRestriction web_restriction;
        private TimeRestriction time_restriction;

        private UserConfig config;
        public ISession session;
        private Server server;

        public SessionHandler (ISession session) throws GLib.Error {
            this.session = session;
            server = Server.get_default ();

            config = UserConfig.get_for_username (session.name, false);
            if (config == null || !config.active) {
                throw new GLib.IOError.FAILED ("Unable to get userconfig");
            }

            controller = new RestrictionController ();

            app_restriction = new AppRestriction ();
            web_restriction = new WebRestriction ();

            time_restriction = new TimeRestriction ();
            time_restriction.terminate.connect (() => {
                try {
                    session.terminate ();
                } catch (GLib.Error e) {
                    critical (e.message);
                }
            });
        }

        public string get_id () {
            return session.id;
        }

        public UserConfig get_config () {
            return config;
        }

        public void start () {
            app_restriction.username = config.username;
            app_restriction.admin = config.admin;

            foreach (string target in config.targets) {
                app_restriction.add_target (target);
            }

            controller.add_restriction (app_restriction);

            if (WebRestriction.get_supported ()) {
                foreach (string url in config.block_urls) {
                    web_restriction.add_target (url);
                }

                controller.add_restriction (web_restriction);
            }

            var token = PAM.Reader.get_token_for_user (Constants.PAM_TIME_CONF_PATH, session.name);
            time_restriction.add_target (token);

            controller.add_restriction (time_restriction);
        }

        public void update () {
            if (!config.active) {
                stop ();
                return;
            }

            app_restriction.username = config.username;
            app_restriction.admin = config.admin;

            var new_targets = new GLib.List<string> ();
            foreach (string target in config.targets) {
                new_targets.append (target);
            }

            app_restriction.update_targets (new_targets);

            new_targets = new GLib.List<string> ();
            foreach (string url in config.block_urls) {
                new_targets.append (url);
            }

            web_restriction.update_targets (new_targets);
        }

        public void stop () {
            controller.remove_restriction (app_restriction);
            controller.remove_restriction (web_restriction);
            controller.remove_restriction (time_restriction);
        }
    }
}

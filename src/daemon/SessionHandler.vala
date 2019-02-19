// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2019 Adam Bieńkowski (https://github.com/elementary/switchboard-plug-parental-controls)
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

        public SessionHandler (ISession session) {
            this.session = session;
            server = Server.get_default ();

            config = UserConfig.get_for_username (session.name, true);
            config.changed.connect (on_config_changed);

            controller = new RestrictionController ();

            app_restriction = new AppRestriction (config);
            web_restriction = new WebRestriction (config);

            time_restriction = new TimeRestriction (config);
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

        private void start () {
            controller.add_restriction (app_restriction);
            controller.add_restriction (web_restriction);
            controller.add_restriction (time_restriction);
        }

        public void update () {
            var active = config.get_active ();
            if (!active && controller.has_restrictions ()) {
                stop ();
            } else if (active && !controller.has_restrictions ()) {
                start ();
            }
        }

        public void stop () {
            controller.remove_restriction (app_restriction);
            controller.remove_restriction (web_restriction);
            controller.remove_restriction (time_restriction);
        }

        private void on_config_changed (string key) {
            if (key != Constants.DAEMON_KEY_ACTIVE) {
                return;
            }

            update ();
        }
    }
}

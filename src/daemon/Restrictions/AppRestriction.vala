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
    public class AppRestriction : Restriction {
        private string[] old_targets = {};
        private bool old_admin = false;

        public new static bool get_supported () {
            return AccessControlLists.get_supported ();
        }

        public AppRestriction (UserConfig config) {
            base (config);
            config.notify["targets"].connect (update);
            config.notify["admin"].connect (update);
            config.notify["active"].connect (() => {
                if (config.active) {
                    update ();
                } else {
                    remove_restrictions ();
                }
            });
        }

        public override void start () {
        }

        public override void stop () {
        }

        private void remove_restrictions () {
            var admin = config.admin;
            AccessControlLists.apply_targets (config.username, config.targets, {}, admin, admin);
        }

        private void update () {
            var new_targets = config.targets;
            var new_admin = config.admin;
            AccessControlLists.apply_targets (config.username, old_targets, new_targets, old_admin, new_admin);
            old_targets = new_targets;
            old_admin = new_admin;
        }
    }
}

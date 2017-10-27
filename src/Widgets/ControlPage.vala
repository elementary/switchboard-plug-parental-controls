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

namespace PC.Widgets {
    public class ControlPage : Gtk.Box {
        public Act.User user;
        public Gtk.Stack stack;
        private GeneralBox general_box;
        private InternetBox internet_box;
        private AppsBox apps_box;
        private KeyFile key_file;

        public ControlPage (Act.User user) {
            this.user = user;

            key_file = new KeyFile ();
            key_file.set_list_separator (';');

            margin = 24;
            spacing = margin;
            hexpand = true;
            orientation = Gtk.Orientation.VERTICAL;

            general_box = new GeneralBox (user);
            general_box.expand = true;

            internet_box = new InternetBox (user);
            internet_box.expand = true;

            apps_box = new AppsBox (user);
            apps_box.expand = true;

            stack = new Gtk.Stack ();
            stack.add_titled (general_box, "general", _("General"));
            stack.add_titled (internet_box, "internet", _("Internet"));
            stack.add_titled (apps_box, "apps", _("Applications"));

            Utils.get_permission ().notify["allowed"].connect (update_view_state);

            var switcher = new Gtk.StackSwitcher ();
            switcher.halign = Gtk.Align.CENTER;
            switcher.homogeneous = true;
            switcher.stack = stack;

            add (switcher);
            add (stack);

            update_view_state ();
            show_all ();
        }

        public void set_active (bool active) {
            if (Utils.get_permission ().get_allowed ()) {
                Utils.get_api ().set_user_daemon_active.begin (user.get_user_name (), active);
                if (active) {
                    general_box.refresh ();
                    general_box.update_pam ();
                } else {
                    general_box.set_lock_dock_active (false);
                    general_box.set_printer_active (true);
                    Utils.get_api ().remove_restriction_for_user.begin (user.get_user_name ());
                }
            }  
        }

        public async bool get_active () {
            try {
                return yield Utils.get_api ().get_user_daemon_active (user.get_user_name ());    
            } catch (IOError e) {
                warning (e.message);
            }
            
            return false;
        } 

        private void update_view_state () {
            bool allowed = Utils.get_permission ().get_allowed ();
            general_box.sensitive = allowed;
            internet_box.sensitive = allowed;
            apps_box.sensitive = allowed;
        }
    }
}

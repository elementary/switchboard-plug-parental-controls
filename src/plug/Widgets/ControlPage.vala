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
        public weak Act.User user { get; construct; }
        public Gtk.Stack stack;
        private GeneralBox general_box;

        public ControlPage (Act.User user) {
            Object (user: user);
        }

        construct {
            unowned Polkit.Permission permission = Utils.get_permission ();

            margin = 24;
            spacing = margin;
            hexpand = true;
            orientation = Gtk.Orientation.VERTICAL;

            general_box = new GeneralBox (user);
            general_box.expand = true;

            var internet_box = new InternetBox (user);
            internet_box.expand = true;

            var apps_box = new AppsBox (user);
            apps_box.expand = true;

            stack = new Gtk.Stack ();
            stack.add_titled (general_box, "general", _("General"));
            stack.add_titled (internet_box, "internet", _("Internet"));
            stack.add_titled (apps_box, "apps", _("Applications"));

            permission.bind_property ("allowed", general_box, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            permission.bind_property ("allowed", internet_box, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            permission.bind_property ("allowed", apps_box, "sensitive", GLib.BindingFlags.SYNC_CREATE);

            var switcher = new Gtk.StackSwitcher ();
            switcher.halign = Gtk.Align.CENTER;
            switcher.homogeneous = true;
            switcher.stack = stack;

            add (switcher);
            add (stack);

            show_all ();
        }

        public void set_active (bool active) {
            unowned Polkit.Permission permission = Utils.get_permission ();
            if (permission.allowed) {
                Utils.get_api ().set_user_daemon_active.begin (user.get_user_name (), active);
                if (active) {
                    general_box.update_pam ();
                } else {
                    Utils.get_api ().remove_restriction_for_user.begin (user.get_user_name ());
                }
            }  
        }

        public async bool get_active () {
            try {
                return yield Utils.get_api ().get_user_daemon_active (user.get_user_name ());
            } catch (Error e) {
                warning (e.message);
            }
            
            return false;
        } 
    }
}

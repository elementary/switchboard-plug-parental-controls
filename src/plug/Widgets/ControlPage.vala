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
        private TimeLimitView time_limit_view;
        private AppsBox apps_box;

        public ControlPage (Act.User user) {
            Object (user: user);
        }

        construct {
            unowned Polkit.Permission permission = Utils.get_permission ();

            margin = 24;
            spacing = margin;
            hexpand = true;
            orientation = Gtk.Orientation.VERTICAL;

            time_limit_view = new TimeLimitView (user);
            time_limit_view.expand = true;

            var internet_box = new InternetBox (user);
            internet_box.expand = true;

            apps_box = new AppsBox (user);
            apps_box.expand = true;

            stack = new Gtk.Stack ();
            stack.add_titled (time_limit_view, "general", _("Screen Time"));
            stack.add_titled (internet_box, "internet", _("Internet"));
            stack.add_titled (apps_box, "apps", _("Applications"));

            permission.bind_property ("allowed", time_limit_view, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            permission.bind_property ("allowed", internet_box, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            permission.bind_property ("allowed", apps_box, "sensitive", GLib.BindingFlags.SYNC_CREATE);

            var switcher = new Gtk.StackSwitcher ();
            switcher.halign = Gtk.Align.CENTER;
            switcher.homogeneous = true;
            switcher.stack = stack;

            var header_grid = new Gtk.Grid ();
            header_grid.halign = Gtk.Align.START;
            header_grid.column_spacing = 10;
            header_grid.margin = 6;
            var avatar = new Granite.Widgets.Avatar.from_file (user.get_icon_file (), 64);

            var full_name = new Gtk.Label (user.get_real_name ());
            full_name.halign = Gtk.Align.START;
            full_name.get_style_context ().add_class ("h2");

            var description_message = new Gtk.Label ("");
            description_message.halign = Gtk.Align.FILL;
            description_message.xalign = 0;
            description_message.wrap = true;
            description_message.wrap_mode = Pango.WrapMode.WORD;
            if (Utils.get_current_user () == user) {
                description_message.set_text (_("Manage your usage of this device by setting limits on time usage, websites, and apps."));
            } else {
                description_message.set_text (_("Supervise and manage usage of this device with limits on time usage, websites, and apps. Some limits may be bypassed with an administrator's authorization."));
            }

            header_grid.attach (avatar, 0, 0, 1, 2);
            header_grid.attach (full_name, 1, 0, 1, 1);
            header_grid.attach (description_message, 1, 1, 1, 1);

            add (header_grid);
            add (switcher);
            add (stack);

            show_all ();
        }

        public void set_active (bool active) {
            unowned Polkit.Permission permission = Utils.get_permission ();
            if (permission.allowed) {
                Utils.get_api ().set_user_daemon_active.begin (user.get_user_name (), active);
                apps_box.set_restrictions_active (active);
                time_limit_view.update_pam (active);
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

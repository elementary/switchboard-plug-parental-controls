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

/* Borrowed from https://launchpad.net/switchboard-plug-useraccounts */

namespace PC.Widgets {
    public class UserItem : Gtk.ListBoxRow {
        public ControlPage page { get; construct; }

        private Gtk.Grid grid;
        private Hdy.Avatar avatar;
        private Gtk.Label full_name_label;
        private Gtk.Label username_label;
        private Gtk.Switch master_switch;

        public weak Act.User user { public get; private set; }

        public UserItem (ControlPage page) {
            Object (page: page);
        }

        construct {
            user = page.user;
            user.changed.connect (update_view);

            avatar = new Hdy.Avatar (32, null, true);

            full_name_label = new Gtk.Label ("");
            full_name_label.halign = Gtk.Align.START;
            full_name_label.hexpand = true;
            full_name_label.ellipsize = Pango.EllipsizeMode.END;
            full_name_label.get_style_context ().add_class ("h3");

            username_label = new Gtk.Label ("");
            username_label.halign = Gtk.Align.START;
            username_label.use_markup = true;
            username_label.ellipsize = Pango.EllipsizeMode.END;

            master_switch = new Gtk.Switch ();
            master_switch.valign = Gtk.Align.CENTER;

            grid = new Gtk.Grid () {
                column_spacing = 12,
                margin = 6,
                margin_end = 12,
                margin_start = 12
            };
            grid.attach (avatar, 0, 0, 1, 2);
            grid.attach (full_name_label, 1, 0, 1, 1);
            grid.attach (username_label, 1, 1, 1, 1);
            grid.attach (master_switch, 2, 0, 1, 2);

            master_switch.notify["active"].connect (() => {
                page.set_active (master_switch.get_active ());
            });

            master_switch.bind_property ("active", page.stack, "sensitive", BindingFlags.SYNC_CREATE);

            Utils.get_permission ().notify["allowed"].connect (update_view);
            update_view ();

            add (grid);
            show_all ();
        }

        public void update_view () {
            page.get_active.begin ((obj, res) => {
                master_switch.active = page.get_active.end (res);
            });

            master_switch.sensitive = Utils.get_permission ().get_allowed ();

            full_name_label.label = user.get_real_name ();
            username_label.label = GLib.Markup.printf_escaped (
                                        "<span font_size=\"small\">%s</span>", user.get_user_name ()
                                   );

            avatar.text = user.get_real_name ();
            avatar.set_image_load_func ((size) => {
                try {
                    return new Gdk.Pixbuf.from_file_at_size (user.get_icon_file (), size, size);
                } catch (Error e) {
                    debug (e.message);
                    return null;
                }
            });

            grid.show_all ();
        }
    }
}

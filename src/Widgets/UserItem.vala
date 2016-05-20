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

/* Borrowed from https://launchpad.net/switchboard-plug-useraccounts */

namespace PC.Widgets {
    public class UserItem : Gtk.ListBoxRow {
        public ControlPage page;

        private Gtk.Grid grid;
        private Granite.Widgets.Avatar avatar;
        private Gtk.Label full_name_label;
        private Gtk.Label username_label;
        private Gtk.Switch master_switch;

        public weak Act.User user { public get; private set; }

        public UserItem (ControlPage page) {
            this.page = page;
            this.user = page.user;
            user.changed.connect (update_ui);

            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.column_spacing = 6;

            avatar = new Granite.Widgets.Avatar ();

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

            grid.attach (avatar, 0, 0, 1, 2);
            grid.attach (full_name_label, 1, 0, 1, 1);
            grid.attach (username_label, 1, 1, 1, 1); 
            grid.attach (master_switch, 2, 0, 1, 2);  

            master_switch.bind_property ("active", page, "active", BindingFlags.SYNC_CREATE);
            master_switch.bind_property ("active", page, "sensitive", BindingFlags.SYNC_CREATE);     

            update_ui ();

            add (grid);
            show_all ();
        }

        public void update_ui () {
            try {
                var avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (user.get_icon_file (), 32, 32, true);
                avatar.pixbuf = avatar_pixbuf;
            } catch (Error e) {
                avatar.show_default (32);
            }

            full_name_label.label = user.get_real_name ();
            username_label.label = "<span font_size=\"small\">%s</span>".printf (GLib.Markup.escape_text (user.get_user_name ()));
            grid.show_all ();
        }
    }
}

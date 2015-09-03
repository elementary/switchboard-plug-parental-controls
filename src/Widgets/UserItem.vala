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
        private Gtk.Image avatar;
        private Gdk.Pixbuf avatar_pixbuf;
        private Gtk.Box label_box;
        private Gtk.Label full_name_label;
        private Gtk.Label description_label;

        public weak Act.User user { public get; private set; }

        public UserItem (ControlPage page) {
            this.page = page;
            this.user = page.user;
            user.changed.connect (update_ui);

            build_ui ();
        }

        private void build_ui () {
            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.margin_left = 12;
            grid.column_spacing = 6;

            label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            label_box.vexpand = true;
            label_box.valign = Gtk.Align.CENTER;
            grid.attach (label_box, 1, 0, 1, 1);

            full_name_label = new Gtk.Label ("");
            full_name_label.halign = Gtk.Align.START;
            full_name_label.get_style_context ().add_class ("h3");

            description_label = new Gtk.Label ("");
            description_label.halign = Gtk.Align.START;
            description_label.use_markup = true;

            label_box.pack_start (full_name_label, false, false);
            label_box.pack_start (description_label, false, false);

            update_ui ();

            grid.attach (avatar, 0, 0, 1, 1);

            add (grid);            
        }

        public void update_ui () {
            if (avatar == null) {
                avatar = new Gtk.Image ();
                avatar.margin_end = 3;
            }

            try {
                avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (user.get_icon_file (), 32, 32, true);
                avatar.set_from_pixbuf (avatar_pixbuf);
            } catch (Error e) {
                avatar.set_from_icon_name ("avatar-default", Gtk.IconSize.DND);
            }

            full_name_label.set_label (user.get_real_name ());
            string description = "<span font_size=\"small\">%s</span>".printf (user.get_user_name ());
            if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR)
                description = "<span font_size=\"small\">%s (%s)</span>".printf (user.get_user_name (), _("Administrator"));
            description_label.set_label (description);
            
            grid.show_all ();
        }
    }
}
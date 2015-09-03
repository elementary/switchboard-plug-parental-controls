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
    public class UserListBox : Gtk.ListBox {
        private Gtk.Label my_account_label;
        private Gtk.Label other_accounts_label;
        private Gtk.ListBoxRow  guest_session_row;
        private Gtk.Label guest_description_label;

        public UserListBox () { 
            selection_mode = Gtk.SelectionMode.SINGLE;
            Utils.get_usermanager ().user_added.connect (update_ui);
            Utils.get_usermanager ().user_removed.connect (update_ui);
            this.set_header_func (update_headers);

            build_ui ();
            this.show_all ();
        }

        private void build_ui () {
            my_account_label = new Gtk.Label (_("My Account"));
            my_account_label.halign = Gtk.Align.START;
            my_account_label.get_style_context ().add_class ("h4");

            other_accounts_label = new Gtk.Label (_("Other Accounts"));
            other_accounts_label.halign = Gtk.Align.START;
            other_accounts_label.get_style_context ().add_class ("h4");

            //only build the guest session list entry / row when lightDM is X11's display manager
            /*if (Utils.get_display_manager () == "lightdm") {
                build_guest_session_row ();
                debug ("LightDM found as display manager. Loading guest session settings");
            } else
                debug ("Unsupported display manager found. Guest session settings will be hidden");*/

            Utils.get_usermanager ().notify["is-loaded"].connect (update_ui);
        }

        public void update_ui () {
            List<weak Gtk.Widget> userlist_items = get_children ();

            foreach (unowned Gtk.Widget useritem in userlist_items) {
                this.remove (useritem);
            }

            int pos = 0;
            if (Utils.get_current_user ().get_account_type () != Act.UserAccountType.ADMINISTRATOR) {
                var current_page = new ControlPage (Utils.get_current_user ());
                insert (new UserItem (current_page), 0);
                pos++;
            }

            foreach (var temp_user in Utils.get_usermanager ().list_users ()) {
                if (temp_user.get_account_type () != Act.UserAccountType.ADMINISTRATOR && Utils.get_current_user () != temp_user) {
                    var page = new ControlPage (temp_user);
                    insert (new UserItem (page), pos);
                    pos++;
                }
            }

            //insert (guest_session_row, pos);
            if (get_selected_row () == null) {
                this.get_row_at_index (0).activate ();
            }

            show_all ();
        }

        public void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
            if (((UserItem) row).user == Utils.get_current_user ()) {
                row.set_header (my_account_label);
            } else {
                row.set_header (null);
            }
        }

        private void build_guest_session_row () {
            guest_session_row = new Gtk.ListBoxRow ();
            guest_session_row.name = "guest-session";

            Gtk.Grid row_grid = new Gtk.Grid ();
            row_grid.margin = 6;
            row_grid.margin_left = 12;
            row_grid.column_spacing = 6;
            guest_session_row.add (row_grid);

            Gtk.Image avatar = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DND);
            avatar.margin_end = 3;
            row_grid.attach (avatar, 0, 0, 1, 1);

            Gtk.Box label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            label_box.vexpand = true;
            label_box.valign = Gtk.Align.CENTER;
            row_grid.attach (label_box, 1, 0, 1, 1);

            Gtk.Label full_name_label = new Gtk.Label (_("Guest Session"));
            full_name_label.halign = Gtk.Align.START;
            full_name_label.get_style_context ().add_class ("h3");

            guest_description_label = new Gtk.Label (null);
            guest_description_label.halign = Gtk.Align.START;
            guest_description_label.use_markup = true;

            label_box.pack_start (full_name_label, false, false);
            label_box.pack_start (guest_description_label, false, false);
        }
    }
}

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
        private List<Act.User> users;

        public UserListBox () { 
            users = new List<Act.User> ();

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
        }

        public void update_ui () {
            List<weak Gtk.Widget> userlist_items = get_children ();

            foreach (unowned Gtk.Widget useritem in userlist_items) {
                users.remove (((UserItem) useritem).user);
                this.remove (useritem);
            }

            int pos = 0;
            if (Utils.get_current_user ().get_account_type () != Act.UserAccountType.ADMINISTRATOR) {
                var current_page = new ControlPage (Utils.get_current_user ());
                insert (new UserItem (current_page), 0);
                users.append (Utils.get_current_user ());
                pos++;
            }

            foreach (var user in Utils.get_usermanager ().list_users ()) {
                if (user.get_account_type () != Act.UserAccountType.ADMINISTRATOR && Utils.get_current_user () != user) {
                    var page = new ControlPage (user);
                    insert (new UserItem (page), pos);
                    users.append (user);
                    pos++;
                }
            }

            if (get_selected_row () == null) {
                this.get_row_at_index (0).activate ();
            }

            show_all ();
        }

        public bool get_has_users () {
            update_ui ();
            return (users.length () - 1 > 0);
        }

        public void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
            if (((UserItem) row).user == Utils.get_current_user ()) {
                row.set_header (my_account_label);
            } else {
                row.set_header (null);
            }
        }
    }
}

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
        private List<UserItem> items;

        public UserListBox () { 
            items = new List<UserItem> ();

            selection_mode = Gtk.SelectionMode.SINGLE;
            this.set_header_func (update_headers);

            build_view ();
            this.show_all ();
        }

        private void build_view () {
            my_account_label = new Gtk.Label (_("My Account"));
            my_account_label.halign = Gtk.Align.START;
            my_account_label.get_style_context ().add_class ("h4");

            other_accounts_label = new Gtk.Label (_("Other Accounts"));
            other_accounts_label.halign = Gtk.Align.START;
            other_accounts_label.get_style_context ().add_class ("h4");
        }

        public void fill () {
            foreach (var user in Utils.get_usermanager ().list_users ()) {
                add_user (user);
            }

            select_first ();            
        }

        public void add_user (Act.User user) {
            if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR || has_user (user)) {
                return;
            }

            bool had_users = get_has_users ();

            var page = new ControlPage (user);
            var useritem = new UserItem (page);

            items.append (useritem);
            add (useritem);

            if (!had_users) {
                select_first ();
            }

            show_all ();
        }

        public void update_user (Act.User user) {
            foreach (var item in items) {
                if (item.user == user) {
                    item.update_view ();
                    if (user.get_account_type () == Act.UserAccountType.ADMINISTRATOR) {
                        remove_user (user);
                    } else {
                        add_user (user);
                    }
                }
            }            
        }

        public void remove_user (Act.User user) {
            foreach (var item in items) {
                if (item.user == user) {
                    item.page.destroy ();
                    item.destroy ();
                    items.remove (item);
                }
            }
        }

        private void select_first () {
            if (get_selected_row () == null) {
                this.get_row_at_index (0).activate ();
            }
        }

        public bool get_has_users () {
            return (items.length () > 0);
        }

        private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
            if (row is UserItem && ((UserItem) row).user == Utils.get_current_user ()) {
                row.set_header (my_account_label);
            } else {
                row.set_header (null);
            }
        }

        private bool has_user (Act.User user) {
            foreach (var item in items) {
                if (item.user == user) {
                    return true;
                }
            }

            return false;
        }        
    }
}

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
    public class UserListBox : Gtk.ListBox {
        private List<UserItem> items;

        construct { 
            items = new List<UserItem> ();

            selection_mode = Gtk.SelectionMode.SINGLE;
            set_header_func (update_headers);

            unowned Act.UserManager user_manager = Act.UserManager.get_default ();

            if (user_manager.is_loaded) {
                user_manager.list_users ().foreach ((user) => add_user (user));
                select_first ();
            } else {
                user_manager.notify["is-loaded"].connect (() => {
                    user_manager.list_users ().foreach ((user) => add_user (user));
                    select_first ();
                });
            }

            show_all ();

            user_manager.user_added.connect (add_user);
            user_manager.user_changed.connect (update_user);
            user_manager.user_removed.connect (remove_user);
        }

        public void add_user (Act.User user) {
            if (has_user (user)) {
                return;
            }

            var page = new ControlPage (user);
            var useritem = new UserItem (page);

            items.append (useritem);
            add (useritem);

            select_first ();

            useritem.show_all ();
        }

        public void update_user (Act.User user) {
            foreach (var item in items) {
                if (item.user == user) {
                    item.update_view ();
                    add_user (user);

                    break;
                }
            }
        }

        public void remove_user (Act.User user) {
            foreach (var item in items) {
                if (item.user == user) {
                    item.page.destroy ();
                    item.destroy ();
                    items.remove (item);

                    break;
                }
            }
        }

        private void select_first () {
            if (get_selected_row () == null) {
                weak Gtk.ListBoxRow? first_row = get_row_at_index (0);
                if (first_row != null) {
                    first_row.activate ();
                }
            }
        }

        private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
            if (row is UserItem && ((UserItem) row).user == Utils.get_current_user ()) {
                var my_account_header = new Granite.HeaderLabel (_("My Account"));
                row.set_header (my_account_header);
            } else if (before is UserItem && ((UserItem) before).user == Utils.get_current_user ()) {
                var other_accounts_label = new Granite.HeaderLabel (_("Other Accounts"));
                row.set_header (other_accounts_label);
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

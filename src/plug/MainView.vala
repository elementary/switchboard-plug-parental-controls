/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 */

public class PC.MainBox : Gtk.Box {
    private List<Widgets.UserItem> items;
    private Gtk.ListBox list;

    construct {
        var stack = new Gtk.Stack () {
            hexpand = true
        };

        items = new List<Widgets.UserItem> ();

        list = new Gtk.ListBox () {
            selection_mode = SINGLE
        };
        list.set_header_func (update_headers);

        var scrolled_window = new Gtk.ScrolledWindow () {
            child = list,
            hscrollbar_policy = NEVER,
            vexpand = true
        };

        var paned = new Gtk.Paned (HORIZONTAL) {
            position = 240,
            start_child = scrolled_window,
            end_child = stack,
            shrink_start_child = false,
            shrink_end_child = false,
            resize_start_child = false
        };

        orientation = VERTICAL;
        append (paned);

        list.row_activated.connect ((row) => {
            var user_item_row = (Widgets.UserItem) row;
            if (stack.get_child_by_name (user_item_row.user.uid.to_string ()) == null) {
                stack.add_named (user_item_row.page, user_item_row.user.uid.to_string ());
            }

            stack.visible_child = user_item_row.page;
        });

        unowned var user_manager = Act.UserManager.get_default ();
        user_manager.user_added.connect (add_user);
        user_manager.user_changed.connect (update_user);
        user_manager.user_removed.connect (remove_user);

        if (user_manager.is_loaded) {
            user_manager.list_users ().foreach ((user) => add_user (user));
            select_first ();
        } else {
            user_manager.notify["is-loaded"].connect (() => {
                user_manager.list_users ().foreach ((user) => add_user (user));
                select_first ();
            });
        }
    }

    private void add_user (Act.User user) {
        if (has_user (user)) {
            return;
        }

        var page = new Widgets.ControlPage (user);
        var useritem = new Widgets.UserItem (page);

        items.append (useritem);
        list.append (useritem);

        select_first ();
    }

    private void update_user (Act.User user) {
        foreach (var item in items) {
            if (item.user == user) {
                item.update_view ();
                add_user (user);

                break;
            }
        }
    }

    private void remove_user (Act.User user) {
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
        if (list.get_selected_row () == null) {
            weak Gtk.ListBoxRow? first_row = list.get_row_at_index (0);
            if (first_row != null) {
                first_row.activate ();
            }
        }
    }

    private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        if (row is Widgets.UserItem && ((Widgets.UserItem) row).user == Utils.get_current_user ()) {
            var my_account_header = new Granite.HeaderLabel (_("My Account"));
            row.set_header (my_account_header);
        } else if (before is Widgets.UserItem && ((Widgets.UserItem) before).user == Utils.get_current_user ()) {
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

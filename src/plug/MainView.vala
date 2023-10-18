/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 */

public class PC.MainBox : Gtk.Box {
    construct {
        var stack = new Gtk.Stack () {
            hexpand = true
        };

        var list = new Widgets.UserListBox ();

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            child = list,
            hscrollbar_policy = NEVER,
            vexpand = true
        };

        var paned = new Gtk.Paned (HORIZONTAL) {
            position = 240
        };
        paned.pack1 (scrolled_window, true, true);
        paned.pack2 (stack, true, false);

        var lock_button = new Gtk.LockButton (Utils.get_permission ());

        var infobar = new Gtk.InfoBar ();

        var infobar_content = infobar.get_content_area ();
        var infobar_action_area = (Gtk.Container) infobar.get_action_area ();
        infobar_content.add (new Gtk.Label (_("Some settings require administrator rights to be changed")));
        infobar_action_area.add (lock_button);

        orientation = VERTICAL;
        add (infobar);
        add (paned);
        show_all ();

        list.row_activated.connect ((row) => {
            var user_item_row = (Widgets.UserItem) row;
            if (stack.get_child_by_name (user_item_row.user.uid.to_string ()) == null) {
                stack.add_named (user_item_row.page, user_item_row.user.uid.to_string ());
            }

            stack.visible_child = user_item_row.page;
        });

        unowned Polkit.Permission permission = Utils.get_permission ();
        permission.bind_property ("allowed", infobar, "revealed", SYNC_CREATE | INVERT_BOOLEAN);
    }
}

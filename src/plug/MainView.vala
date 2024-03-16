/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 */

public class PC.MainBox : Gtk.Box {
    private Gtk.Stack stack;

    construct {
        stack = new Gtk.Stack ();

        var sidebar = new Switchboard.SettingsSidebar (stack);

        var paned = new Gtk.Paned (HORIZONTAL) {
            start_child = sidebar,
            end_child = stack,
            shrink_start_child = false,
            shrink_end_child = false,
            resize_start_child = false,
            vexpand = true
        };

        orientation = VERTICAL;
        append (paned);

        unowned var user_manager = Act.UserManager.get_default ();
        user_manager.user_added.connect (add_user);
        user_manager.user_changed.connect (update_user);
        user_manager.user_removed.connect (remove_user);

        if (user_manager.is_loaded) {
            user_manager.list_users ().foreach ((user) => add_user (user));
        } else {
            user_manager.notify["is-loaded"].connect (() => {
                user_manager.list_users ().foreach ((user) => add_user (user));
            });
        }
    }

    private void add_user (Act.User user) {
        if (stack.get_child_by_name (user.uid.to_string ()) != null) {
            return;
        }

        var page = new Widgets.ControlPage (user);
        stack.add_titled (page, user.uid.to_string (), page.title);
    }

    private void update_user (Act.User user) {
        ((Widgets.ControlPage) stack.get_child_by_name (user.uid.to_string ())).update_user;
    }

    private void remove_user (Act.User user) {
        stack.remove (
            stack.get_child_by_name (user.uid.to_string ())
        );
    }
}

/*
 * Copyright (c) 2015 Adam Bieńkowski
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

public class PC.MainBox : Gtk.Box {
    private Gtk.Stack content;
    private Widgets.UserListBox list;
    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.InfoBar infobar;

    public MainBox () {
        content = new Gtk.Stack () {
            hexpand = true
        };

        list = new Widgets.UserListBox ();
        list.row_activated.connect ((row) => {
            if (content.get_children ().find (((Widgets.UserItem) row).page) == null) {
                content.add_child (((Widgets.UserItem) row).page);
            }

            content.visible_child = ((Widgets.UserItem) row).page;
        });

        scrolled_window = new Gtk.ScrolledWindow () {
            child = list,
            hscrollbar_policy = NEVER,
            vexpand = true
        };

        var paned = new Gtk.Paned (HORIZONTAL) {
            position = 240,
            start_child = scrolled_window,
            end_child = content
        };

        var lock_button = new Gtk.LockButton (Utils.get_permission ());

        infobar = new Gtk.InfoBar ();
        infobar.add_child (new Gtk.Label (_("Some settings require administrator rights to be changed")));
        infobar.add_action_widget (lock_button);

        unowned Polkit.Permission permission = Utils.get_permission ();
        permission.bind_property ("allowed", infobar, "no-show-all", GLib.BindingFlags.SYNC_CREATE);
        permission.bind_property ("allowed", infobar, "visible",
                                  GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);

        orientation = VERTICAL;
        append (infobar);
        append (paned);
    }
}

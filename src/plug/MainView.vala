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
    private Gtk.Stack stack;
    private Gtk.Stack content;
    private Widgets.UserListBox list;
    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Grid main_grid;
    private Gtk.InfoBar infobar;
    private Gtk.Grid alert_view_grid;

    public MainBox () {
        stack = new Gtk.Stack ();

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

        content = new Gtk.Stack ();
        content.hexpand = true;

        list = new Widgets.UserListBox ();
        list.row_activated.connect ((row) => {
            if (content.get_children ().find (((Widgets.UserItem) row).page) == null) {
                content.add (((Widgets.UserItem) row).page);
            }

            content.visible_child = ((Widgets.UserItem) row).page;
        });

        scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled_window.add (list);
        scrolled_window.vexpand = true;

        paned.pack1 (scrolled_window, true, true);
        paned.pack2 (content, true, false);
        paned.set_position (240);

        var lock_button = new Gtk.LockButton (Utils.get_permission ());

        infobar = new Gtk.InfoBar ();

        var infobar_content = infobar.get_content_area ();
        var infobar_action_area = (Gtk.Container) infobar.get_action_area ();
        infobar_content.add (new Gtk.Label (_("Some settings require administrator rights to be changed")));
        infobar_action_area.add (lock_button);

        main_grid = new Gtk.Grid ();
        main_grid.attach (infobar, 0, 1, 1, 1);
        main_grid.attach (paned, 0, 2, 1, 1);

        var alert_view = new Granite.Widgets.AlertView (_("No users to edit"), _("Parental Controls can only be applied to user accounts that don't have administrative permissions.\nYou can change a user's account type from \"Administrator\" to \"Standard\" in the User Accounts pane."), "preferences-system-parental-controls");
        alert_view.get_style_context ().remove_class (Gtk.STYLE_CLASS_VIEW);

        var link_button = new Gtk.LinkButton.with_label ("settings://accounts", _("Configure User Accounts"));
        link_button.halign = Gtk.Align.END;
        link_button.valign = Gtk.Align.END;
        link_button.tooltip_text = _("Open Users settings");

        alert_view_grid = new Gtk.Grid ();
        alert_view_grid.margin = 24;
        alert_view_grid.attach (alert_view, 0, 0, 1, 1);
        alert_view_grid.attach (link_button, 0, 1, 1, 1);

        stack.add (main_grid);
        stack.add (alert_view_grid);

        list.notify["has-users"].connect (() => update_stack ());
        update_stack ();

        unowned Polkit.Permission permission = Utils.get_permission ();
        permission.bind_property ("allowed", infobar, "no-show-all", GLib.BindingFlags.SYNC_CREATE);
        permission.bind_property ("allowed", infobar, "visible", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.INVERT_BOOLEAN);

        this.add (stack);
        this.show_all ();
    }

    private void update_stack () {
        if (list.has_users) {
            stack.visible_child = main_grid;
        } else {
            stack.visible_child = alert_view_grid;
        }
    }
}

/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 */

public class PC.Widgets.ControlPage : Gtk.Box {
    public weak Act.User user { get; construct; }
    public Gtk.Stack stack;
    private TimeLimitView time_limit_view;
    private AppsBox apps_box;

    public ControlPage (Act.User user) {
        Object (user: user);
    }

    construct {
        unowned var permission = Utils.get_permission ();

        hexpand = true;
        margin_top = 12;
        margin_end = 12;
        margin_bottom = 12;
        margin_start = 12;
        orientation = VERTICAL;
        spacing = 24;

        time_limit_view = new TimeLimitView (user);
        var internet_box = new InternetBox (user);
        apps_box = new AppsBox (user);

        stack = new Gtk.Stack ();
        stack.add_titled (time_limit_view, "general", _("Screen Time"));
        stack.add_titled (internet_box, "internet", _("Internet"));
        stack.add_titled (apps_box, "apps", _("Applications"));

        permission.bind_property ("allowed", time_limit_view, "sensitive", SYNC_CREATE);
        permission.bind_property ("allowed", internet_box, "sensitive", SYNC_CREATE);
        permission.bind_property ("allowed", apps_box, "sensitive", SYNC_CREATE);

        var switcher = new Gtk.StackSwitcher () {
            halign = CENTER,
            homogeneous = true,
            stack = stack
        };

        var header_grid = new Gtk.Grid () {
            column_spacing = 12,
            halign = START
        };

        var avatar = new Hdy.Avatar (48, user.get_real_name (), true) {
            loadable_icon = new FileIcon (File.new_for_path (user.get_icon_file ())),
            valign = START
        };

        var full_name = new Gtk.Label (user.get_real_name ()) {
            hexpand = true,
            selectable = true,
            wrap = true,
            xalign = 0
        };
        full_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var description_message = new Gtk.Label ("") {
            selectable = true,
            use_markup = true,
            wrap = true,
            xalign = 0
        };

        if (Utils.get_current_user () == user) {
            description_message.label = _("Manage your own device usage by setting limits on Screen Time, websites, and apps.");
        } else {
            description_message.label = _("Supervise and manage device usage with limits on Screen Time, websites, and apps. Some limits may be bypassed with an administrator's permission.");
        }

        header_grid.attach (avatar, 0, 0, 1, 2);
        header_grid.attach (full_name, 1, 0);
        header_grid.attach (description_message, 1, 1);

        add (header_grid);
        add (switcher);
        add (stack);

        show_all ();
    }

    public void set_active (bool active) {
        unowned Polkit.Permission permission = Utils.get_permission ();
        if (permission.allowed) {
            Utils.get_api ().set_user_daemon_active.begin (user.get_user_name (), active);
            apps_box.set_restrictions_active (active);
            time_limit_view.update_pam (active);
        }
    }

    public async bool get_active () {
        try {
            return yield Utils.get_api ().get_user_daemon_active (user.get_user_name ());
        } catch (Error e) {
            warning (e.message);
        }

        return false;
    }
}

/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 */

public class PC.Widgets.ControlPage : Switchboard.SettingsPage {
    public weak Act.User user { get; construct; }
    public Gtk.Stack stack;
    private TimeLimitView time_limit_view;
    private AppsBox apps_box;

    public ControlPage (Act.User user) {
        Object (
            activatable: true,
            title: user.get_real_name (),
            with_avatar: true,
            user: user
        );
    }
    construct {
        try {
            avatar_paintable = Gdk.Texture.from_filename (user.get_icon_file ());
        } catch (Error e) {
            critical (e.message);
        }

        if (Utils.get_current_user () == user) {
            description = _("Manage your own device usage by setting limits on Screen Time, websites, and apps.");
        } else {
            description = _("Supervise and manage device usage with limits on Screen Time, websites, and apps. Some limits may be bypassed with an administrator's permission.");
        }

        time_limit_view = new TimeLimitView (user);
        var internet_box = new InternetBox (user);
        apps_box = new AppsBox (user);

        stack = new Gtk.Stack ();
        stack.add_titled (time_limit_view, "general", _("Screen Time"));
        stack.add_titled (internet_box, "internet", _("Internet"));
        stack.add_titled (apps_box, "apps", _("Applications"));

        var switcher = new Gtk.StackSwitcher () {
            halign = CENTER,
            margin_bottom = 12,
            stack = stack
        };

        var size_group = new Gtk.SizeGroup (HORIZONTAL);

        unowned var switcher_child = switcher.get_first_child ();
        while (switcher_child != null) {
            size_group.add_widget (switcher_child);
            switcher_child = switcher_child.get_next_sibling ();
        }

        var lock_button = new Gtk.LockButton (Utils.get_permission ());

        var infobar = new Gtk.InfoBar () {
            margin_bottom = 9
        };
        infobar.add_css_class (Granite.STYLE_CLASS_FRAME);
        infobar.add_child (new Gtk.Label (_("Some settings require administrator rights to be changed")));
        infobar.add_action_widget (lock_button, 1);

        var box = new Gtk.Box (VERTICAL, 0);
        box.append (infobar);
        box.append (switcher);
        box.append (stack);

        child = box;

        status_switch.bind_property ("active", stack, "sensitive", SYNC_CREATE);
        status_switch.notify["active"].connect (() => {
            set_active (status_switch.active);
        });

        get_active.begin ((obj, res) => {
            status_switch.active = get_active.end (res);
        });

        user.changed.connect (() => {
            get_active.begin ((obj, res) => {
                status_switch.active = get_active.end (res);
            });
        });

        unowned var permission = Utils.get_permission ();
        permission.bind_property ("allowed", apps_box, "sensitive", SYNC_CREATE);
        permission.bind_property ("allowed", infobar, "revealed", SYNC_CREATE | INVERT_BOOLEAN);
        permission.bind_property ("allowed", internet_box, "sensitive", SYNC_CREATE);
        permission.bind_property ("allowed", status_switch, "sensitive", SYNC_CREATE);
        permission.bind_property ("allowed", time_limit_view, "sensitive", SYNC_CREATE);
    }

    private void set_active (bool active) {
        unowned Polkit.Permission permission = Utils.get_permission ();
        if (permission.allowed) {
            Utils.get_api ().set_user_daemon_active.begin (user.get_user_name (), active);
            apps_box.set_restrictions_active (active);
            time_limit_view.update_pam (active);
        }
    }

    private async bool get_active () {
        try {
            return yield Utils.get_api ().get_user_daemon_active (user.get_user_name ());
        } catch (Error e) {
            warning (e.message);
        }

        return false;
    }
}

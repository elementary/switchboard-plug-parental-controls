/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 */

public class PC.Widgets.UserItem : Gtk.ListBoxRow {
    public ControlPage page { get; construct; }

    private Adw.Avatar avatar;
    private Gtk.Label full_name_label;
    private Gtk.Label username_label;
    private Gtk.Switch master_switch;

    public weak Act.User user { public get; private set; }

    public UserItem (ControlPage page) {
        Object (page: page);
    }

    construct {
        user = page.user;
        user.changed.connect (update_view);

        avatar = new Adw.Avatar (32, null, true);

        full_name_label = new Gtk.Label ("") {
            halign = START,
            hexpand = true,
            ellipsize = END
        };
        full_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        username_label = new Gtk.Label ("") {
            halign = START,
            use_markup = true,
            ellipsize = END
        };
        username_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        master_switch = new Gtk.Switch () {
            valign = CENTER
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12
        };
        grid.attach (avatar, 0, 0, 1, 2);
        grid.attach (full_name_label, 1, 0);
        grid.attach (username_label, 1, 1);
        grid.attach (master_switch, 2, 0, 1, 2);

        child = grid;

        master_switch.bind_property ("active", page.stack, "sensitive", SYNC_CREATE);
        master_switch.sensitive = Utils.get_permission ().get_allowed ();
        master_switch.notify["active"].connect (() => {
            page.set_active (master_switch.active);
        });

        Utils.get_permission ().notify["allowed"].connect (() => {
            master_switch.sensitive = Utils.get_permission ().get_allowed ();
        });

        update_view ();
    }

    public void update_view () {
        page.get_active.begin ((obj, res) => {
            master_switch.active = page.get_active.end (res);
        });

        full_name_label.label = user.get_real_name ();
        username_label.label = user.get_user_name ();

        avatar.text = user.get_real_name ();
        try {
            avatar.custom_image = Gdk.Texture.from_filename (user.get_icon_file ());
        } catch (Error e) {
            avatar.custom_image = null;
        }
    }
}

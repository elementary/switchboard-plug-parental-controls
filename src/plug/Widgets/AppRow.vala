/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2023 elementary, Inc. (https://elementary.io)
 */

public class PC.Widgets.AppRow : Gtk.ListBoxRow {
    public signal void deleted ();

    public AppInfo app_info { get; construct; }
    public bool has_delete { get; construct; default = false; }

    private static Flatpak.Installation system_installation;
    private static Flatpak.Installation user_installation;

    public AppRow (AppInfo app_info) {
        Object (app_info: app_info);
    }

    public AppRow.with_delete_button (AppInfo app_info) {
        Object (
            app_info: app_info,
            has_delete: true
        );
    }

    public bool is_flatpak {
        get {
            return ((DesktopAppInfo)app_info).has_key ("X-Flatpak");
        }
    }

    public string? flatpak_ref {
        owned get {
            if (!is_flatpak) {
                return null;
            }

            string id = ((DesktopAppInfo)app_info).get_string ("X-Flatpak");
            return get_flatpak_ref_for_id (id);
        }
    }

    construct {
        var image = new Gtk.Image.from_gicon (app_info.get_icon (), DND) {
            pixel_size = 32
        };

        var app_name = new Gtk.Label (app_info.get_display_name ()) {
            xalign = 0
        };

        var app_comment = new Gtk.Label (app_info.get_description ()) {
            ellipsize = END,
            hexpand = true,
            xalign = 0
        };
        app_comment.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic") {
            halign = END,
            hexpand = true,
            tooltip_text = ("Unblock %s").printf (app_info.get_display_name ())
        };

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };
        main_grid.attach (image, 0, 0, 1, 2);
        main_grid.attach (app_name, 1, 0);
        main_grid.attach (app_comment, 1, 1);

        if (has_delete) {
            main_grid.attach (delete_button, 2, 0, 1, 2);
        }

        child = main_grid;

        delete_button.clicked.connect (() => deleted ());
    }

    public static string? get_flatpak_ref_for_id (string id) {
        string? ref = null;

        try {
            if (system_installation == null) {
                system_installation = new Flatpak.Installation.system ();
            }

            var refs = system_installation.list_installed_refs_by_kind (Flatpak.RefKind.APP);
            for (int i = 0; i < refs.length; i++) {
                unowned Flatpak.InstalledRef installed_ref = refs.@get (i);
                if (installed_ref.get_name () == id) {
                    ref = installed_ref.format_ref ();
                }
            }
        } catch (Error e) {
            // pass
        }

        try {
            if (user_installation == null) {
                user_installation = new Flatpak.Installation.user ();
            }

            var refs = user_installation.list_installed_refs_by_kind (Flatpak.RefKind.APP);
            for (int i = 0; i < refs.length; i++) {
                unowned Flatpak.InstalledRef installed_ref = refs.@get (i);
                if (installed_ref.get_name () == id) {
                    ref = installed_ref.format_ref ();
                }
            }
        } catch (Error e) {
            // pass
        }

        if (ref != null) {
            return ref;
        }

        return null;
    }
}

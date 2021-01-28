/*
 * Copyright (c) 2018 elementary, Inc (https://elementary.io)
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
 */

public class PC.Widgets.AppRow : Gtk.ListBoxRow {
    public signal void deleted ();

    public AppInfo app_info { get; construct; }

    public AppRow (AppInfo app_info) {
        Object (app_info: app_info);
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
            string? ref = null;

            try {
                var installation = new Flatpak.Installation.system ();
                var refs = installation.list_installed_refs_by_kind (Flatpak.RefKind.APP);
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
                var installation = new Flatpak.Installation.user ();
                var refs = installation.list_installed_refs_by_kind (Flatpak.RefKind.APP);
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

    construct {
        var image = new Gtk.Image.from_gicon (app_info.get_icon (), Gtk.IconSize.LARGE_TOOLBAR);
        image.pixel_size = 32;

        var app_name = new Gtk.Label (app_info.get_display_name ());
        app_name.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        app_name.xalign = 0;

        var app_comment = new Gtk.Label (app_info.get_description ());
        app_comment.ellipsize = Pango.EllipsizeMode.END;
        app_comment.hexpand = true;
        app_comment.xalign = 0;

        var main_grid = new Gtk.Grid ();
        main_grid.margin = 6;
        main_grid.margin_start = 12;
        main_grid.column_spacing = 12;
        main_grid.attach (image, 0, 0, 1, 2);
        main_grid.attach (app_name, 1, 0);
        main_grid.attach (app_comment, 1, 1);

        add (main_grid);
    }
}

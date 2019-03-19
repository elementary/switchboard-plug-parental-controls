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

        var time_limit_button = new Gtk.Button.from_icon_name ("tools-timer-symbolic");
        time_limit_button.tooltip_text = _("Limit after amount of daily usage");
        time_limit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var time_limit_label = new Gtk.Label (_("Allow:"));

        var time_limit_entry = new Gtk.Entry ();
        time_limit_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var time_limit_mins_label = new Gtk.Label (_("minutes per day"));

        var time_limit_grid = new Gtk.Grid ();
        time_limit_grid.column_spacing = 6;
        time_limit_grid.margin_top = 12;

        time_limit_grid.add (time_limit_label);
        time_limit_grid.add (time_limit_entry);
        time_limit_grid.add (time_limit_mins_label);

        var time_limit_revealer = new Gtk.Revealer ();
        time_limit_revealer.add (time_limit_grid);

        var allow_times_button = new Gtk.Button.from_icon_name ("preferences-system-time-symbolic");
        allow_times_button.tooltip_text = _("Allow certain times");
        allow_times_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var allow_times_label = new Gtk.Label (_("Allow:"));

        var allow_start_entry = new Granite.Widgets.TimePicker ();
        allow_start_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var allow_to_label = new Gtk.Label (_("to"));

        var allow_end_entry = new Granite.Widgets.TimePicker ();
        allow_end_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var allow_times_grid = new Gtk.Grid ();
        allow_times_grid.column_spacing = 6;
        allow_times_grid.margin_top = 12;

        allow_times_grid.add (allow_times_label);
        allow_times_grid.add (allow_start_entry);
        allow_times_grid.add (allow_to_label);
        allow_times_grid.add (allow_end_entry);

        var allow_times_revealer = new Gtk.Revealer ();
        allow_times_revealer.add (allow_times_grid);

        var main_grid = new Gtk.Grid ();
        main_grid.margin = 6;
        main_grid.margin_start = 12;
        main_grid.column_spacing = 12;

        main_grid.attach (image, 0, 0, 1, 2);
        main_grid.attach (app_name, 1, 0);
        main_grid.attach (time_limit_button, 3, 0, 1, 2);
        main_grid.attach (allow_times_button, 2, 0, 1, 2);
        main_grid.attach (app_comment, 1, 1);
        main_grid.attach (time_limit_revealer, 1, 2, 3);
        main_grid.attach (allow_times_revealer, 1, 3, 3);

        add (main_grid);

        time_limit_button.clicked.connect (() => {
            time_limit_revealer.reveal_child = !time_limit_revealer.reveal_child;
            var time_limit_context = time_limit_button.get_style_context ();

            if (time_limit_revealer.reveal_child) {
                time_limit_context.add_class (Granite.STYLE_CLASS_ACCENT);
                time_limit_entry.grab_focus ();
            } else {
                time_limit_context.remove_class (Granite.STYLE_CLASS_ACCENT);
            }
        });

        allow_times_button.clicked.connect (() => {
            allow_times_revealer.reveal_child = !allow_times_revealer.reveal_child;
            var allow_times_context = allow_times_button.get_style_context ();

            if (allow_times_revealer.reveal_child) {
                allow_times_context.add_class (Granite.STYLE_CLASS_ACCENT);
                allow_start_entry.grab_focus ();
            } else {
                allow_times_context.remove_class (Granite.STYLE_CLASS_ACCENT);
            }
        });
    }
}

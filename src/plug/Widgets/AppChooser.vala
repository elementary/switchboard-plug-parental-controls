/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 *              Julien Spautz <spautz.julien@gmail.com>
 */

public class PC.Widgets.AppChooser : Granite.Dialog {
    private Gtk.ListBox listbox;
    private Gtk.SearchEntry search_entry;

    public signal void app_chosen (AppInfo info);

    construct {
        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search Applications")
        };

        listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        listbox.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        listbox.set_filter_func (filter_function);
        listbox.set_sort_func (sort_function);

        var scrolled = new Gtk.ScrolledWindow () {
            child = listbox
        };

        var frame = new Gtk.Frame (null) {
            child = scrolled
        };

        var box = new Gtk.Box (VERTICAL, 6);
        box.append (search_entry);
        box.append (frame);

        default_height = 500;
        default_width = 400;
        focus_widget = search_entry;
        modal = true;
        get_content_area ().append (box);
        add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        foreach (var _info in AppInfo.get_all ()) {
            if (_info.should_show ()) {
                var row = new PC.Widgets.AppRow (_info);
                listbox.prepend (row);
            }
        }

        response.connect (hide);

        listbox.row_activated.connect (on_app_selected);

        search_entry.search_changed.connect (() => {
            listbox.invalidate_filter ();
        });
    }

    private int sort_function (Gtk.ListBoxRow first_row, Gtk.ListBoxRow second_row) {
        var row_1 = (PC.Widgets.AppRow)first_row;
        var row_2 = (PC.Widgets.AppRow)second_row;

        string name_1 = row_1.app_info.get_display_name ();
        string name_2 = row_2.app_info.get_display_name ();

        return name_1.collate (name_2);
    }

    private bool filter_function (Gtk.ListBoxRow row) {
        var app_row = (PC.Widgets.AppRow) row;
        return search_entry.text.down () in app_row.app_info.get_display_name ().down ()
            || search_entry.text.down () in app_row.app_info.get_description ().down ();
    }

    private void on_app_selected (Gtk.ListBoxRow row) {
        var app_row = (PC.Widgets.AppRow) row;
        app_chosen (app_row.app_info);
        hide ();
    }
}

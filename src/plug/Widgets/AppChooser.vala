/*
 * Copyright 2018 elementary, Inc. (https://elementary.io)
 *           2015 Adam Bieńkowski
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
 * Julien Spautz <spautz.julien@gmail.com>
 */

namespace PC.Widgets {
    public class AppChooser : Gtk.Popover {

        private Gtk.ListBox listbox;
        private Gtk.SearchEntry search_entry;

        public signal void app_chosen (AppInfo info);

        construct {
            search_entry = new Gtk.SearchEntry ();
            search_entry.margin_end = 12;
            search_entry.margin_start = 12;
            search_entry.placeholder_text = _("Search Applications");

            listbox = new Gtk.ListBox ();
            listbox.vexpand = true;
            listbox.set_filter_func (filter_function);
            listbox.set_sort_func (sort_function);

            var scrolled = new Gtk.ScrolledWindow ();
            scrolled.height_request = 200;
            scrolled.width_request = 500;
            scrolled.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scrolled.child = listbox;

            var grid = new Gtk.Grid ();
            grid.margin_top = 12;
            grid.row_spacing = 6;
            grid.attach (search_entry, 0, 0);
            grid.attach (scrolled, 0, 1);

            child = grid;

            foreach (var _info in AppInfo.get_all ()) {
                if (_info.should_show ()) {
                    var row = new PC.Widgets.AppRow (_info);
                    listbox.prepend (row);
                }
            }

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
}

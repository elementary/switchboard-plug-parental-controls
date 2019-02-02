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
        protected class AppRow : Gtk.Box {
            public AppInfo info;

            public AppRow (AppInfo info) {
                this.info = info;

                orientation = Gtk.Orientation.HORIZONTAL;
                margin = 6;
                spacing = 12;

                var image = new Gtk.Image.from_gicon (info.get_icon (), Gtk.IconSize.LARGE_TOOLBAR);
                image.pixel_size = 32;
                add (image);

                string? description = info.get_description ();
                if (description == null) {
                    description = "";
                }

                string markup = Utils.create_markup (info.get_display_name (), description);
                var label = new Gtk.Label (markup);
                label.use_markup = true;
                label.halign = Gtk.Align.START;
                label.ellipsize = Pango.EllipsizeMode.END;
                add (label);

                show_all ();
            }
        }

        private Gtk.ListBox listbox;
        private Gtk.SearchEntry search_entry;

        public signal void app_chosen (AppInfo info);

        public AppChooser (Gtk.Widget widget) {
            Object (relative_to: widget);
        }

        construct {
            modal = true;

            var grid = new Gtk.Grid ();
            grid.margin = 12;
            grid.row_spacing = 6;

            search_entry = new Gtk.SearchEntry ();
            search_entry.margin_end = 12;
            search_entry.margin_start = 12;
            search_entry.placeholder_text = _("Search Applications");

            listbox = new Gtk.ListBox ();
            listbox.expand = true;
            listbox.set_filter_func (filter_function);
            listbox.set_sort_func (sort_function);

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.height_request = 200;
            scrolled.width_request = 500;
            scrolled.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scrolled.add (listbox);

            var grid = new Gtk.Grid ();
            grid.margin_top = 12;
            grid.row_spacing = 6;
            grid.attach (search_entry, 0, 0);
            grid.attach (scrolled, 0, 1);

            add (grid);

            foreach (var _info in AppInfo.get_all ()) {
                if (_info.should_show ()) {
                    var row = new AppRow (_info);
                    listbox.prepend (row);
                }
            }

            listbox.row_activated.connect (on_app_selected);

            search_entry.search_changed.connect (() => {
                listbox.invalidate_filter ();
            });
        }

        private int sort_function (Gtk.ListBoxRow first_row, Gtk.ListBoxRow second_row) {
            var row_1 = (AppRow)first_row.get_child ();
            var row_2 = (AppRow)second_row.get_child ();

            string name_1 = row_1.info.get_display_name ();
            string name_2 = row_2.info.get_display_name ();

            return name_1.collate (name_2);
        }

        private bool filter_function (Gtk.ListBoxRow row) {
            var app_row = (AppRow)row.get_child ();
            return search_entry.text.down () in app_row.info.get_display_name ().down ()
                || search_entry.text.down () in app_row.info.get_description ().down ();
        }

        private void on_app_selected (Gtk.ListBoxRow row) {
            var app_row = (AppRow)row.get_child ();
            app_chosen (app_row.info);
            hide ();
        }
    }
}

// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Adam Bieńkowski (https://launchpad.net/switchboard-plug-parental-controls)
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
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

namespace PC.Widgets {
    public class WeekSpinBox : Gtk.Box {
        public signal void changed ();

        private Granite.Widgets.TimePicker picker_from;
        private Granite.Widgets.TimePicker picker_to;

        public WeekSpinBox (string title, Gtk.SizeGroup size_group) {
            orientation = Gtk.Orientation.HORIZONTAL;
            spacing = 12;

            picker_from = new Granite.Widgets.TimePicker ();
            picker_from.time_changed.connect (() => changed ());

            picker_to = new Granite.Widgets.TimePicker ();
            picker_to.time_changed.connect (() => changed ());

            var label = new Gtk.Label (title);
            label.get_style_context ().add_class ("h4");
            size_group.add_widget (label);

            add (label);
            add (new Gtk.Label (_("From:")));
            add (picker_from);
            add (new Gtk.Label (_("To:")));
            add (picker_to);
            show_all ();
        }

        public string get_from () {
            return format_time_string (picker_from.time.get_hour ())
                + format_time_string (picker_from.time.get_minute ());
        }

        public string get_to () {
            return format_time_string (picker_to.time.get_hour ())
                + format_time_string (picker_to.time.get_minute ());
        }

        public void set_from (string from) {
            string hours = from.slice (0, 2);
            string minutes = from.substring (2);

            var time = new DateTime.local (new DateTime.now_local ().get_year (), 1, 1, int.parse (hours), int.parse (minutes), 0);
            picker_from.time = time;
        }

        public void set_to (string to) {
            string hours = to.slice (0, 2);
            string minutes = to.substring (2);

            var time = new DateTime.local (new DateTime.now_local ().get_year (), 1, 1, int.parse (hours), int.parse (minutes), 0);
            picker_to.time = time;
        }

        private string format_time_string (int val) {
            if (val < 10) {
                return "0" + val.to_string ();
            }

            return val.to_string ();
        }
    }
}

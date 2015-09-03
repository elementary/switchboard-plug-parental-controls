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

public class WeekSpinBox : Gtk.Box {
    public signal void changed ();

    private Gtk.SpinButton hbtn_from;
    private Gtk.SpinButton mbtn_from;

    private Gtk.SpinButton hbtn_to;
    private Gtk.SpinButton mbtn_to;


    public WeekSpinBox (string title) {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 12;

        hbtn_from = new Gtk.SpinButton.with_range (0, 24, 1);
        hbtn_from.orientation = Gtk.Orientation.VERTICAL;

        mbtn_from = new Gtk.SpinButton.with_range (0, 60, 1);
        mbtn_from.orientation = Gtk.Orientation.VERTICAL;
        mbtn_from.margin_end = 12;

        hbtn_to = new Gtk.SpinButton.with_range (0, 24, 1);
        hbtn_to.orientation = Gtk.Orientation.VERTICAL;
        hbtn_to.margin_start = 12;

        mbtn_to = new Gtk.SpinButton.with_range (0, 60, 1);
        mbtn_to.orientation = Gtk.Orientation.VERTICAL;

        var label = new Gtk.Label (title);
        label.get_style_context ().add_class ("h4");

        hbtn_from.value_changed.connect (_changed);
        mbtn_from.value_changed.connect (_changed);
        hbtn_to.value_changed.connect (_changed);
        mbtn_to.value_changed.connect (_changed);

        use_leading (hbtn_from);
        use_leading (mbtn_from);
        use_leading (hbtn_to);
        use_leading (mbtn_to);

        add (label);
        add (new Gtk.Label (_("From:")));
        add (hbtn_from);
        add (new Gtk.Label (":"));
        add (mbtn_from);
        add (new Gtk.Label (_("To:")));
        add (hbtn_to);
        add (new Gtk.Label (_(":")));
        add (mbtn_to);
        show_all ();
    }

    public string get_from () {
        return hbtn_from.get_text () + mbtn_from.get_text ();
    }

    public string get_to () {
        return hbtn_to.get_text () + mbtn_to.get_text ();
    }

    private void _changed () {
        changed ();
    }

    private void use_leading (Gtk.SpinButton spin) {
        spin.output.connect ((s) => {
            int val = spin.get_value_as_int ();
            if (val < 10) {
                spin.text  = "0" + val.to_string ();
                return true;
            }

            return false;
        });
    }
}
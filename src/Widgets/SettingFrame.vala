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

public class SettingFrame : Gtk.Frame {
    private const string CSS_DATA = "GtkFrame {\nbackground: #ffffff;\n}";

    protected class SettingBox : Gtk.Box {

        public SettingBox (string title, string? path) {
            this.orientation = Gtk.Orientation.HORIZONTAL;


            this.pack_start (new Gtk.Label (title));

        }
    }

    public SettingFrame (string title, string? path) {
        var css_provider = new Gtk.CssProvider ();
        try {
            css_provider.load_from_data (CSS_DATA, -1);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }        

        this.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);


    }
}
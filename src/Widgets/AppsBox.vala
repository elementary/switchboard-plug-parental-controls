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
    public class AppsBox : Gtk.Box {
    	protected class AppEntry : Gtk.Box {
    		public signal void changed ();

    		private Gtk.CheckButton check_btn;

    		public AppEntry (AppInfo info) {
    			orientation = Gtk.Orientation.VERTICAL;

    			check_btn = new Gtk.CheckButton ();
    			check_btn.halign = Gtk.Align.END;
    			check_btn.valign = Gtk.Align.START;
    			check_btn.margin_end = 12;

    			var overlay = new Gtk.Overlay ();

    			Gtk.Image image;
    			if (info.get_icon () == null
    				|| info.get_icon ().to_string () == null
    				|| info.get_icon ().to_string ().strip () == "") {
					image = new Gtk.Image.from_icon_name ("application-x-desktop", Gtk.IconSize.INVALID);
    			} else {
    				image = new Gtk.Image.from_gicon (info.get_icon (), Gtk.IconSize.INVALID);
    			}

    			image.pixel_size = 64;

    			overlay.add (image);
    			overlay.add_overlay (check_btn);

    			var label = new Gtk.Label (info.get_name ());
    			label.wrap = true;
    			label.get_style_context ().add_class ("h3");
    			label.set_justify (Gtk.Justification.CENTER);
    			label.set_max_width_chars (10);

    			add (overlay);
    			add (label);
    		}

    		public void set_active (bool active) {
    			check_btn.set_active (active);
    		}
    	}

        public AppsBox () {
            orientation = Gtk.Orientation.VERTICAL;
            spacing = 12;

            var admin_check_btn = new Gtk.CheckButton.with_label (_("Allow access to these apps with admin permission"));

            var frame = new Gtk.Frame (null);
            frame.hexpand = frame.vexpand = true;

            Gdk.RGBA bg = { 1, 1, 1, 1 };
            frame.override_background_color (0, bg);

            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            var placeholder = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            placeholder.margin = 6;

            var combo = new Gtk.ComboBoxText ();
            combo.margin_end = 3;
            combo.append_text (_("Prevent"));
            combo.append_text (_("Allow"));
            combo.active = 0;

            placeholder.add (combo);
            placeholder.add (new Gtk.Label (_("the user from using these apps:")));

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.hexpand = scrolled.vexpand = true;
            frame.add (main_box);

            main_box.add (placeholder);
            main_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            main_box.add (scrolled);

            var flow_box = new Gtk.FlowBox ();
            flow_box.homogeneous = false;
            flow_box.column_spacing = flow_box.row_spacing = 6;
            flow_box.margin = 12;

            scrolled.add (flow_box);

            var app_list = AppInfo.get_all ();
            foreach (var app_info in app_list) {
            	if (app_info.should_show ()) {
	            	var entry = new AppEntry (app_info);
	            	flow_box.add (entry);
            	}
            }

            add (frame);
            add (admin_check_btn);
        }
    }
}
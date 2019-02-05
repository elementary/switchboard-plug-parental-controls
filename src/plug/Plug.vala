/*
 * Copyright 2019 elementary, Inc. (https://elementary.io)
 *           2015 Adam Bieńkowski (https://launchpad.net/switchboard-plug-parental-controls)
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
 */

public class PC.Plug : Switchboard.Plug {
    private MainBox? main_box = null;

    public Plug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("parental-controls", null);

        Object (
            category: Category.SYSTEM,
            code_name: "pantheon-parental-controls",
            display_name: _("Parental Control"),
            description: _("Configure time limits and restrict application usage"),
            icon: "preferences-system-parental-controls",
            supported_settings: settings
        );
    }

    public override Gtk.Widget get_widget () {
        if (main_box == null) {
            main_box = new MainBox ();
        }

        return main_box;
    }

    public override void shown () {
    }

    public override void hidden () {
    }

    public override void search_callback (string location) {
    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
        search_results.set ("%s → %s".printf (display_name, _("Limit computer use")), "");
        search_results.set ("%s → %s".printf (display_name, _("Prevent website access")), "");
        search_results.set ("%s → %s".printf (display_name, _("Prevent application access")), "");
        return search_results;
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Parental Controls plug");

    var plug = new PC.Plug ();
    return plug;
}

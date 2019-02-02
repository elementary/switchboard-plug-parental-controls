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
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Adam Bieńkowski <donadigos159@gmail.com>
 */

namespace PC {
    public static Plug plug;

    public class MainBox : Gtk.Box {
        private Gtk.Stack content;
        private Widgets.UserListBox list;
        private Gtk.ScrolledWindow scrolled_window;
        private Gtk.Grid main_grid;
        private Gtk.InfoBar infobar;

        public MainBox () {
            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

            content = new Gtk.Stack ();
            content.hexpand = true;

            list = new Widgets.UserListBox ();
            list.row_activated.connect ((row) => {
                if (content.get_children ().find (((Widgets.UserItem) row).page) == null) {
                    content.add (((Widgets.UserItem) row).page);
                }

                content.visible_child = ((Widgets.UserItem) row).page;
            });

            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;
            scrolled_window.add (list);
            scrolled_window.vexpand = true;

            paned.pack1 (scrolled_window, true, true);
            paned.pack2 (content, true, false);
            paned.set_position (240);

            var lock_button = new Gtk.LockButton (Utils.get_permission ());

            infobar = new Gtk.InfoBar ();

            var infobar_content = infobar.get_content_area ();
            var infobar_action_area = (Gtk.Container) infobar.get_action_area ();
            infobar_content.add (new Gtk.Label (_("Some settings require administrator rights to be changed")));
            infobar_action_area.add (lock_button);

            main_grid = new Gtk.Grid ();
            main_grid.attach (infobar, 0, 1, 1, 1);
            main_grid.attach (paned, 0, 2, 1, 1);

            var link_button = new Gtk.LinkButton.with_label ("settings://accounts", _("Configure User Accounts"));
            link_button.halign = Gtk.Align.END;
            link_button.valign = Gtk.Align.END;
            link_button.tooltip_text = _("Open Users settings");

            unowned Polkit.Permission permission = Utils.get_permission ();
            permission.bind_property ("allowed", infobar, "no-show-all", GLib.BindingFlags.SYNC_CREATE);
            permission.bind_property ("allowed", infobar, "visible", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.INVERT_BOOLEAN);

            this.add (main_grid);
            this.show_all ();
        }
    }

    public class Plug : Switchboard.Plug {
        private MainBox? main_box = null;

        public Plug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("parental-controls", null);
            Object (category: Category.SYSTEM,
                    code_name: "pantheon-parental-controls",
                    display_name: _("Parental Control"),
                    description: _("Configure time limits and restrict application usage"),
                    icon: "preferences-system-parental-controls",
                    supported_settings: settings);
            plug = this;
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
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Parental Controls plug");

    var plug = new PC.Plug ();
    return plug;
}

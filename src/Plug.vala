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

namespace PC {
    public static Plug plug;

    public class MainBox : Gtk.Box {
        private Gtk.Stack stack;
        private Gtk.Stack content;
        private Widgets.UserListBox list;
        private Gtk.ScrolledWindow scrolled_window;
        private Gtk.Grid main_grid;
        private Granite.Widgets.AlertView alert;

        private Act.UserManager usermanager;

        public MainBox () {
            usermanager = Utils.get_usermanager ();

            stack = new Gtk.Stack ();

            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            paned.width_request = 250;

            content = new Gtk.Stack ();
            content.hexpand = true;

            var sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            list = new Widgets.UserListBox ();
            list.row_activated.connect ((row) => {
                if (!Utils.list_contains (content.get_children (), ((Widgets.UserItem) row).page)) {
                    content.add (((Widgets.UserItem) row).page);
                }

                content.visible_child = ((Widgets.UserItem) row).page;
            });

            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.add (list);
            scrolled_window.vexpand = true;

            sidebar.pack_start (scrolled_window, true, true);

            paned.pack1 (sidebar, true, false);
            paned.pack2 (content, true, true);
            paned.set_position (240);

            var lock_button = new Gtk.LockButton (Utils.get_permission ());

            var infobar = new Gtk.InfoBar ();
            var infobar_content = infobar.get_content_area ();
            var infobar_action = (Gtk.Container) infobar.get_action_area ();
            infobar_content.add (new Gtk.Label ("Some settings require administrator rights to be changed"));
            infobar_action.add (lock_button);

            Utils.get_permission ().notify["allowed"].connect (() => {
                paned.sensitive = Utils.get_permission ().get_allowed ();
                if (Utils.get_permission ().get_allowed ()) {
                    infobar.no_show_all = true;
                    infobar.hide ();
                } else {
                    infobar.no_show_all = false;
                    infobar.show_all ();
                }
            });

            main_grid = new Gtk.Grid ();
            main_grid.attach (infobar, 0, 1, 1, 1);
            main_grid.attach (paned, 0, 2, 1, 1);

            alert = new Granite.Widgets.AlertView (_("No users to edit"), _("Parental Controls can only be applied to user accounts that don't have administrative permissions.\nYou can change a user's account type from \"Administrator\" to \"Standard\" in the User Accounts pane."), "preferences-system-parental-controls");

            var link_button = new Gtk.LinkButton.with_label ("", _("Configure User Accounts"));
            link_button.halign = Gtk.Align.START;
            link_button.tooltip_text = _("Open Users settings");
            link_button.activate_link.connect (() => {
                new Granite.Services.SimpleCommand ("/usr/bin", "switchboard user-accounts").run ();
                return true;
            });

            alert.attach (link_button, 2, 3, 1, 1);

            stack.add (main_grid);
            stack.add (alert);

            usermanager.notify["is-loaded"].connect (on_usermanager_loaded);

            this.add (stack);
            this.show_all ();
        }

        private void on_usermanager_loaded () {
            if (!usermanager.is_loaded) {
                return;
            }

            list.fill ();

            usermanager.user_added.connect (on_user_added);
            usermanager.user_changed.connect (on_user_changed);
            usermanager.user_removed.connect (on_user_removed);            
            update_ui_state ();
        }

        private void update_ui_state () {
            if (list.get_has_users ()) {
                stack.visible_child = main_grid;
            } else {
                stack.visible_child = alert;
            }    
        }

        private void on_user_added (Act.User user) {
            list.add_user (user);
            update_ui_state ();
        }

        private void on_user_changed (Act.User user) {
            list.update_user (user);
            update_ui_state ();
        }

        private void on_user_removed (Act.User user) {
            list.remove_user (user);
            update_ui_state ();
        }
    }

    public class Plug : Switchboard.Plug {
        private MainBox? main_box = null;

        public Plug () {
            Object (category: Category.SYSTEM,
                    code_name: Build.PLUGCODENAME,
                    display_name: _("Parental Control"),
                    description: _("Configure time limits and restrict application usage"),
                    icon: "preferences-system-parental-controls");
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
            return new Gee.TreeMap<string, string> (null, null);
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Parental Control plug");

    var plug = new PC.Plug ();
    return plug;
}

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
    public class ControlPage : Gtk.Box {
        public Act.User user;
        private GeneralBox general_box;
        private AppsBox apps_box;
        private InternetBox internet_box;
        private KeyFile key_file;

        public ControlPage (Act.User user) {
            this.user = user;

            key_file = new KeyFile ();
            key_file.set_list_separator (';');

            margin = 24;
            spacing = margin;
            hexpand = true;
            orientation = Gtk.Orientation.VERTICAL;

            general_box = new GeneralBox (user);
            general_box.expand = true;

            apps_box = new AppsBox (user);
            apps_box.expand = true;
            apps_box.update_key_file.connect (on_update_key_file);

            internet_box = new InternetBox (user);
            internet_box.expand = true;
            internet_box.update_key_file.connect (on_update_key_file);

            var stack = new Gtk.Stack ();
            stack.add_titled (general_box, "general", _("General"));
            stack.add_titled (internet_box, "internet", _("Internet"));
            stack.add_titled (apps_box, "apps", _("Applications"));

            var switcher = new Gtk.StackSwitcher ();
            switcher.halign = Gtk.Align.CENTER;
            switcher.stack = stack;
            add (switcher);
            add (stack);

            show_all ();
        }

        public bool active {
            get {
                return apps_box.get_active ();
            }

            set {
                apps_box.set_active (active);

                if (Utils.get_permission ().get_allowed ()) {
                    if (value) {
                        general_box.refresh ();
                        Utils.call_cli ({"--user", user.get_user_name (), "--enable-restrict"});
                    } else {
                        general_box.set_lock_dock_active (false);
                        general_box.set_printer_active (true);                    
                        Utils.call_cli ({"--user", user.get_user_name (), "--disable-restrict"});
                    }
                }            
            }
        }

        private void on_update_key_file () {
            if (!Utils.get_permission ().get_allowed ()) {
                return;
            }

            key_file.set_boolean (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_ACTIVE, apps_box.daemon_active);
            key_file.set_string_list (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_TARGETS, apps_box.targets);
            key_file.set_boolean (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_ADMIN, apps_box.admin);
            key_file.set_string_list (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_BLOCK_URLS, internet_box.urls);

            Utils.call_cli ({ "--set-contents", key_file.to_data (), "--file", Utils.build_daemon_conf_path (user) });
        }
    }
}

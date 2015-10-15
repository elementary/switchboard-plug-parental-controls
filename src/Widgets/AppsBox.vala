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
        private List<AppEntry> entries;
        private Act.User user;

        private Gtk.ListBox list_box;
        private AppChooser apps_popover;
        private Gtk.CheckButton admin_check_btn;
        private Gtk.ToolButton remove_button;

        protected class AppEntry : Gtk.ListBoxRow {
            public signal void deleted ();

            private AppInfo info;
            private string executable;

            public AppEntry (AppInfo info) {
                this.info = info;
                executable = info.get_executable ();

                var main_grid = new Gtk.Grid ();
                main_grid.orientation = Gtk.Orientation.HORIZONTAL;

                main_grid.margin = 6;
                main_grid.column_spacing = 12;

                var image = new Gtk.Image.from_gicon (info.get_icon (), Gtk.IconSize.LARGE_TOOLBAR);
                image.pixel_size = 32;
                main_grid.add (image);

                string markup = Utils.create_markup (info.get_display_name (), info.get_description ());
                var label = new Gtk.Label (markup);
                label.expand = true;
                label.use_markup = true;
                label.halign = Gtk.Align.START;
                label.ellipsize = Pango.EllipsizeMode.END;
                main_grid.add (label);

                add (main_grid);
            }

            public AppInfo get_info () {
                return info;
            }

            public string get_executable () {
                return executable;
            }
        }

        public AppsBox (Act.User user) {
            this.user = user;
            entries = new List<AppEntry> ();

            orientation = Gtk.Orientation.VERTICAL;
            spacing = 12;

            admin_check_btn = new Gtk.CheckButton.with_label (_("Allow access to these apps with admin permission"));
            admin_check_btn.notify["active"].connect (on_changed);

            var frame = new Gtk.Frame (null);
            frame.hexpand = frame.vexpand = true;

            Gdk.RGBA bg = { 1, 1, 1, 1 };
            frame.override_background_color (0, bg);

            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            frame.add (main_box);

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.hexpand = scrolled.vexpand = true;

            var plabel = new Gtk.Label ("Add apps to prevent %s from using them:".printf (user.get_real_name ()));
            plabel.margin_start = 6;
            plabel.halign = Gtk.Align.START;
            plabel.get_style_context ().add_class ("h4");

            main_box.add (plabel);

            list_box = new Gtk.ListBox ();
            list_box.row_selected.connect (on_changed);
            scrolled.add (list_box);

            var toolbar = new Gtk.Toolbar ();
            toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
            toolbar.icon_size = Gtk.IconSize.SMALL_TOOLBAR;

            var add_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON), null);
            add_button.tooltip_text = _("Add Prevented Apps…");
            add_button.clicked.connect (() => {
                apps_popover.show_all ();
            });

            remove_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.BUTTON), null);
            remove_button.tooltip_text = _("Remove Selected App");
            remove_button.sensitive = false;
            remove_button.clicked.connect (() => {
                var row = (AppEntry) list_box.get_selected_row ();
                row.deleted ();
            });

            apps_popover = new AppChooser (add_button);
            apps_popover.app_chosen.connect ((info) => {
                if (!get_info_loaded (info)) {
                    var row = new AppEntry (info);
                    row.deleted.connect (on_deleted);

                    entries.append (row);
                    list_box.add (row);
                    list_box.show_all ();
                }

                on_changed ();
            });

            toolbar.add (add_button);
            toolbar.add (remove_button);

            main_box.add (scrolled);
            main_box.add (toolbar);

            add (frame);
            add (admin_check_btn);
        }

        private bool get_info_loaded (AppInfo info) {
            foreach (var entry in entries) {
                if (entry.get_info () == info) {
                    return true;
                }
            }

            return false;
        }

        private void on_deleted (AppEntry row) {
            row.destroy ();
            entries.remove (row);
            on_changed ();
        }

        private void on_changed () {
            remove_button.sensitive = (list_box.get_selected_row () != null);

            if (Utils.get_permission ().get_allowed ()) {
                var key_file = new KeyFile ();
                key_file.set_list_separator (';');

                string[] targets = {};
                foreach (var entry in entries) {
                    targets += Environment.find_program_in_path (entry.get_executable ());
                }

                key_file.set_string_list (Vars.APP_LOCK_GROUP, Vars.APP_LOCK_TARGETS, targets);
                key_file.set_boolean (Vars.APP_LOCK_GROUP, Vars.APP_LOCK_ADMIN, admin_check_btn.get_active ());

                Utils.call_cli ({ "--set-contents", key_file.to_data (), "--file", build_app_lock_path () });
            }   
        }

        private string? build_app_lock_path () {
            return user.get_home_dir () + Vars.APP_LOCK_CONF_DIR;
        }
    }
}
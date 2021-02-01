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

namespace PC.Widgets {
    public class AppsBox : Gtk.Grid {
        private List<PC.Widgets.AppRow> entries;
        public Act.User user { get; construct; }

        private Gtk.ListBox list_box;
        private AppChooser apps_popover;
        private Gtk.Switch admin_switch_btn;
        private Gtk.Button remove_button;
        private Gtk.Button clear_button;

        private Mct.Manager malcontent;

        public AppsBox (Act.User user) {
            Object (user: user);
        }

        construct {
            try {
                malcontent = new Mct.Manager (GLib.Bus.get_sync (GLib.BusType.SYSTEM));
            } catch (Error e) {
                warning ("Unable to init malcontent support: %s", e.message);
            }

            entries = new List<PC.Widgets.AppRow> ();

            column_spacing = 12;
            row_spacing = 12;

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.hexpand = scrolled.vexpand = true;

            var header_label = new Granite.HeaderLabel (
                _("Prevent %s from using these apps:").printf (user.get_real_name ())
            );
            header_label.margin_start = 12;
            header_label.margin_top = 6;

            list_box = new Gtk.ListBox ();
            list_box.row_selected.connect (update_sensitivity);
            scrolled.add (list_box);

            var add_button = new Gtk.Button.from_icon_name ("application-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            add_button.tooltip_text = _("Add Prevented Apps…");
            add_button.clicked.connect (on_add_button_clicked);

            remove_button = new Gtk.Button.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            remove_button.tooltip_text = _("Remove Selected App");
            remove_button.sensitive = false;
            remove_button.clicked.connect (on_remove_button_clicked);

            clear_button = new Gtk.Button.from_icon_name ("edit-clear-all-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            clear_button.tooltip_text = _("Clear All");
            clear_button.sensitive = false;
            clear_button.clicked.connect (on_clear_button_clicked);

            apps_popover = new AppChooser (add_button);
            apps_popover.app_chosen.connect (load_info);

            var toolbar = new Gtk.ActionBar ();
            toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
            toolbar.add (add_button);
            toolbar.add (remove_button);
            toolbar.pack_end (clear_button);

            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            main_box.add (header_label);
            main_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            main_box.add (scrolled);
            main_box.add (toolbar);

            var frame = new Gtk.Frame (null);
            frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
            frame.add (main_box);

            var admin_label = new Gtk.Label (_("Allow access to these apps with admin permission:"));
            admin_label.halign = Gtk.Align.END;

            admin_switch_btn = new Gtk.Switch ();
            admin_switch_btn.halign = Gtk.Align.START;
            admin_switch_btn.notify["active"].connect (update_admin);

            attach (frame, 0, 0, 2, 1);
            attach (admin_label, 0, 1, 1, 1);
            attach (admin_switch_btn, 1, 1, 1, 1);

            load_existing.begin ();
            show_all ();
        }

        private void on_add_button_clicked () {
            apps_popover.show_all ();
        }

        private void on_remove_button_clicked () {
            var entry = (PC.Widgets.AppRow) list_box.get_selected_row ();
            entry.deleted ();
        }

        private void on_clear_button_clicked () {
            foreach (weak PC.Widgets.AppRow entry in entries) {
                Idle.add (() => {
                    entry.deleted ();
                    return false;
                });
            }
        }

        private void load_info (AppInfo info) {
            if (get_info_loaded (info)) {
                return;
            }

            var row = new PC.Widgets.AppRow (info);
            row.deleted.connect (on_deleted);

            entries.append (row);
            list_box.add (row);
            list_box.show_all ();
            update_targets ();
        }

        private bool get_info_loaded (AppInfo info) {
            foreach (var entry in entries) {
                if (entry.app_info.equal (info)) {
                    return true;
                }
            }

            return false;
        }

        private void on_deleted (PC.Widgets.AppRow row) {
            entries.remove (row);
            row.destroy ();
            update_targets ();
        }

        private void update_admin () {
            update_sensitivity ();

            if (Utils.get_permission ().get_allowed ()) {
                Utils.get_api ().set_user_daemon_admin.begin (user.get_user_name (), admin_switch_btn.get_active ());
            }
        }

        private void update_targets () {
            update_sensitivity ();

            if (!Utils.get_permission ().get_allowed ()) {
                return;
            }

            string[] targets = {};

            var app_filter_builder = new Mct.AppFilterBuilder ();

            foreach (var entry in entries) {
                if (entry.is_flatpak) {
                    var flatpak_ref = entry.flatpak_ref;
                    if (flatpak_ref != null) {
                        app_filter_builder.blocklist_flatpak_ref (flatpak_ref);
                    }
                } else {
                    targets += Utils.info_to_exec_path (entry.app_info, null);
                }
            }

            if (malcontent != null) {
                try {
                    malcontent.set_app_filter (user.uid, app_filter_builder.end (), Mct.ManagerSetValueFlags.NONE);
                } catch (Error e) {
                    warning ("Failed to set malcontent app filter: %s", e.message);
                }
            }

            Utils.get_api ().set_user_daemon_targets.begin (user.get_user_name (), targets);
        }

        private void update_sensitivity () {
            remove_button.sensitive = (list_box.get_selected_row () != null);
            clear_button.sensitive = (entries.length () > 0);
        }

        public void set_restrictions_active (bool active) {
            if (malcontent == null) {
                return;
            }

            // Clear the restrictions list if restrictions are disabled for this user
            if (!active) {
                var app_filter_builder = new Mct.AppFilterBuilder ();
                try {
                    malcontent.set_app_filter (user.uid, app_filter_builder.end (), Mct.ManagerSetValueFlags.NONE);
                } catch (Error e) {
                    warning ("Failed to set malcontent app filter: %s", e.message);
                }
            } else {
                update_targets ();
            }
        }

        private async void load_existing () {
            Mct.AppFilter? app_filter = null;

            if (malcontent != null) {
                try {
                    app_filter = yield malcontent.get_app_filter_async (user.uid, Mct.ManagerGetValueFlags.NONE, null);
                } catch (Error e) {
                    warning ("Unable to get malcontent app filter: %s", e.message);
                }
            }

            try {
                string[] targets = yield Utils.get_api ().get_user_daemon_targets (user.get_user_name ());
                bool admin = yield Utils.get_api ().get_user_daemon_admin (user.get_user_name ());
                admin_switch_btn.set_active (admin);

                List<AppInfo> infos = AppInfo.get_all ();
                foreach (unowned GLib.AppInfo info in infos) {
                    unowned DesktopAppInfo desktop_app = (DesktopAppInfo)info;
                    if (desktop_app.has_key ("X-Flatpak")) {
                        // Show the flatpak in the app list if it's been blocked for this user
                        if (app_filter != null && !app_filter.is_appinfo_allowed (desktop_app)) {
                            load_info (info);
                        }

                        continue;
                    }

                    if (info.should_show () && Utils.info_to_exec_path (info, null) in targets) {
                        load_info (info);
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }
        }
    }
}

/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 */

public class PC.Widgets.AppsBox : Gtk.Grid {
    private List<PC.Widgets.AppRow> entries;
    public Act.User user { get; construct; }

    private Gtk.ListBox list_box;
    private AppChooser apps_dialog;
    private Gtk.Switch admin_switch_btn;
    private Gtk.Button clear_button;

    private Mct.Manager malcontent;

    public AppsBox (Act.User user) {
        Object (user: user);
    }

    construct {
        entries = new List<PC.Widgets.AppRow> ();

        column_spacing = 12;

        var header_label = new Granite.HeaderLabel (_("Blocked Apps"));

        list_box = new Gtk.ListBox ();

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            child = list_box,
            hexpand = true,
            vexpand = true
        };

        var add_label = new Gtk.Label (_("Add Blocked App…"));
        var add_image = new Gtk.Image.from_icon_name ("application-add-symbolic", SMALL_TOOLBAR);

        var add_button_box = new Gtk.Box (HORIZONTAL, 3);
        add_button_box.add (add_image);
        add_button_box.add (add_label);

        var add_button = new Gtk.Button () {
            child = add_button_box
        };
        add_label.mnemonic_widget = add_button;
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        clear_button = new Gtk.Button.from_icon_name ("edit-clear-all-symbolic") {
            sensitive = false,
            tooltip_text = _("Clear All")
        };
        clear_button.clicked.connect (on_clear_button_clicked);

        apps_dialog = new AppChooser () {
            transient_for = ((Gtk.Application) Application.get_default ()).active_window
        };
        apps_dialog.app_chosen.connect (load_info);

        var toolbar = new Gtk.ActionBar ();
        toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        toolbar.pack_start (add_button);
        toolbar.pack_end (clear_button);

        var main_box = new Gtk.Box (VERTICAL, 0);
        main_box.add (scrolled);
        main_box.add (toolbar);

        var frame = new Gtk.Frame (null) {
            child = main_box,
            margin_bottom = 12
        };
        frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

        var admin_label = new Gtk.Label (_("Allow access to these apps with admin permission:")) {
            halign = END
        };

        admin_switch_btn = new Gtk.Switch () {
            halign = START
        };
        admin_switch_btn.notify["active"].connect (update_admin);

        attach (header_label, 0, 0, 2);
        attach (frame, 0, 1, 2);
        attach (admin_label, 0, 2);
        attach (admin_switch_btn, 1, 2);

        load_existing.begin ();
        show_all ();

        add_button.clicked.connect (apps_dialog.present);
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

        var row = new PC.Widgets.AppRow.with_delete_button (info);
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
        try {
            malcontent = new Mct.Manager (yield GLib.Bus.@get (GLib.BusType.SYSTEM));
        } catch (Error e) {
            warning ("Unable to init malcontent support: %s", e.message);
        }

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

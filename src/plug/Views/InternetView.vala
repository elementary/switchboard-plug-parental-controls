/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 */

public class PC.Widgets.InternetBox : Gtk.Box {
    private const string URL_REGEX = "[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,4}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)";

    public weak Act.User user { get; construct; }
    private Regex? url_regex = null;

    private Gtk.ListBox list_box;
    private Granite.ValidatedEntry entry;
    private Gtk.Button add_button;

    public InternetBox (Act.User user) {
        Object (user: user);
    }

    construct {
        try {
            url_regex = new Regex (URL_REGEX, RegexCompileFlags.OPTIMIZE);
        } catch (RegexError e) {
            warning ("%s\n", e.message);
        }

        var info_label = new Granite.HeaderLabel (_("Blocked Websites"));

        list_box = new Gtk.ListBox () {
            selection_mode = NONE
        };

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            child = list_box,
            vexpand = true
        };

        add_button = new Gtk.Button.with_label (_("Block URL")) {
            margin_end = 6,
            sensitive = false
        };
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        add_button.clicked.connect (on_entry_activate);

        entry = new Granite.ValidatedEntry.from_regex (url_regex) {
            hexpand = true,
            margin_start = 6,
            placeholder_text = _("example.com")
        };

        var main_box = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6,
            margin_bottom = 6
        };
        main_box.attach (scrolled, 0, 0, 2);
        main_box.attach (new Gtk.Separator (HORIZONTAL), 0, 1, 2);
        main_box.attach (entry, 0, 3);
        main_box.attach (add_button, 1, 3);

        var frame = new Gtk.Frame (null) {
            child = main_box
        };
        frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

        orientation = VERTICAL;
        add (info_label);
        add (frame);
        load_existing.begin ();
        show_all ();

        entry.bind_property ("is-valid", add_button, "sensitive");
        entry.notify["is-valid"].connect (() => {
            if (entry.is_valid) {
                entry.secondary_icon_tooltip_text = null;
            } else {
                entry.secondary_icon_tooltip_text = _("Invalid URL");
            }
        });

        entry.activate.connect (on_entry_activate);
    }

    private async void load_existing () {
        try {
            string[] block_urls = yield Utils.get_api ().get_user_daemon_block_urls (user.get_user_name ());
            foreach (unowned string url in block_urls) {
                add_entry (url);
            }
        } catch (Error e) {
            critical (e.message);
        }
    }

    private void update_block_urls () {
        if (!Utils.get_permission ().get_allowed ()) {
            return;
        }

        string[] block_urls = {};
        foreach (weak Gtk.Widget url_entry in list_box.get_children ()) {
            block_urls += ((UrlEntry) url_entry).url;
        }

        Utils.get_api ().set_user_daemon_block_urls.begin (user.get_user_name (), block_urls);
    }

    private void on_entry_activate () {
        if (url_regex == null) {
            return;
        }

        string url = entry.get_text ().strip ();
        if (!url_regex.match (url)) {
            return;
        }

        add_entry (url);

        entry.text = "";
        update_block_urls ();
    }

    private void add_entry (string url) {
        var url_entry = new UrlEntry (url);
        url_entry.destroy.connect (() => update_block_urls ());
        list_box.add (url_entry);
    }

    private class UrlEntry : Gtk.ListBoxRow {
        public string url { get; construct; }

        public UrlEntry (string url) {
            Object (url: url);
        }

        construct {
            var delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic") {
                halign = END,
                hexpand = true,
                tooltip_text = _("Unblock %s").printf (url)
            };

            delete_button.clicked.connect (() => {
                destroy ();
            });

            var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 6
            };
            main_box.add (new Gtk.Label (url));
            main_box.add (delete_button);

            child = main_box;
            show_all ();
        }
    }
}

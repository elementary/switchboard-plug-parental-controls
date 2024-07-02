/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 */

public class PC.Widgets.InternetBox : Gtk.Box {
    private const string URL_REGEX = "([^/w.])[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{1,3}([^/])\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*\\b)";
    private string? entry_secondary_tooltip_text = null;
    public weak Act.User user { get; construct; }
    private GLib.MatchInfo? pattern = null;
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

        var scrolled = new Gtk.ScrolledWindow () {
            child = list_box,
            vexpand = true
        };

        add_button = new Gtk.Button.with_label (_("Block URL")) {
            margin_end = 6,
            sensitive = false
        };
        add_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
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
        frame.add_css_class (Granite.STYLE_CLASS_VIEW);

        orientation = VERTICAL;
        spacing = 6;
        append (info_label);
        append (frame);
        load_existing.begin ();

        entry.bind_property ("is-valid", add_button, "sensitive");
        entry.notify["is-valid"].connect (() => {
            if (entry.is_valid) {
                entry.secondary_icon_tooltip_text = null;
            } else {
                entry.secondary_icon_tooltip_text = _("Invalid URL");
            }
        });

        entry.changed.connect (() => {
            on_entry_changed ();
            entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY , this.entry_secondary_tooltip_text);
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

        // SECTION: Remove duplicate strings
        string formatted_url = entry.get_text ().strip ();
        string input_url = pattern.get_string ();
        string block_url;
        int i = 0;
        string[] block_urls = {};

        unowned var child = list_box.get_first_child ();
        while (child != null) {
            if (child is UrlEntry) {
                block_url = ((UrlEntry) child).url;
                if (formatted_url in block_url) {
                    if (formatted_url.length == block_url.length) {
                        i++;
                        if (i > 1) {
                            list_box.remove (child);
                            entry.set_text (input_url);
                            return;
                        }
                    }
                }

                block_urls += block_url;
            }

            child = child.get_next_sibling ();
        }

        // SECTION end
        entry.text = "";

        // We necessary to clean a table rules before saving the configuration file
        Utils.get_api ().set_user_daemon_active.begin (user.get_user_name (), false);
        Utils.get_api ().set_user_daemon_block_urls.begin (user.get_user_name (), block_urls);
        Utils.get_api ().set_user_daemon_active.begin (user.get_user_name (), true);
    }

    private void on_entry_activate () {
        if (url_regex == null) {
            return;
        }

        string url = entry.get_text ().strip ();
        if (!url_regex.match (url)) {
            return;
        }

        // Add automatic url formatting, for example:
        // google.com instead of www.google.com
        // youtube.com instead of https://www.youtube.com
        string? formatted_url = null;
        try {
            for (url_regex.match (url, 0, out pattern); pattern.matches (); pattern.next ()) {
                formatted_url = pattern.fetch (0);
                entry.set_text (formatted_url);
            }
        } catch (GLib.Error e) {
            GLib.error ("Failed URL extraction using regex: %s", e.message);
        }

        if (formatted_url == null) {
            return;
        }

        add_entry (formatted_url);

        update_block_urls ();
    }

    private void on_entry_changed () {
        if (url_regex == null) {
            return;
        }

        var entry_stripped_text = entry.get_text ().strip ();
        bool valid = url_regex.match (entry_stripped_text);
        add_button.sensitive = valid;
        if (valid || entry_stripped_text == "") {
            entry.secondary_icon_name = null;
            if (pattern != null) {
                if (entry_stripped_text == pattern.get_string ()) {
                    entry_secondary_tooltip_text = _("The specified URL already exists in list");
                    entry.secondary_icon_name = "dialog-warning-symbolic";
                    add_button.sensitive = false;
                }
            }
        } else {
            entry_secondary_tooltip_text = _("Invalid URL");
            entry.secondary_icon_name = "process-error-symbolic";
        }
    }

    private void add_entry (string url) {
        var url_entry = new UrlEntry (url);
        url_entry.destroy.connect (() => update_block_urls ());
        list_box.append (url_entry);
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
                unparent ();
                destroy ();
            });

            var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 6
            };
            main_box.append (new Gtk.Label (url));
            main_box.append (delete_button);

            child = main_box;
        }
    }
}

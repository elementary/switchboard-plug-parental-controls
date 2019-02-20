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
    public class InternetBox : Gtk.Grid {
        private const string URL_REGEX_RULE = "[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,4}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)";

        public weak Act.User user { get; construct; }
        private Regex? url_regex = null;

        private Gtk.ListBox list_box;
        private Gtk.Entry entry;
        private Gtk.Button add_button;

        private class UrlEntry : Gtk.ListBoxRow {
            public signal void deleted ();
            public string url { get; construct; }

            public UrlEntry (string url) {
                Object (url: url);
            }

            construct {
                var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic");
                delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
                delete_button.clicked.connect (() => {
                    destroy ();
                });

                var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                main_box.margin_start = 12;
                main_box.margin_end = 6;

                main_box.add (new Gtk.Label (url));
                main_box.pack_end (delete_button, false, false, 0);

                add (main_box);
                show_all ();
            }
        }

        public InternetBox (Act.User user) {
            Object (user: user);
        }

        construct {
            try {
                url_regex = new Regex (URL_REGEX_RULE, RegexCompileFlags.OPTIMIZE);
            } catch (RegexError e) {
                warning ("%s\n", e.message);
            }

            var info_label = new Gtk.Label (_("Prevent %s from visiting these websites:").printf (user.get_real_name ()));
            info_label.halign = Gtk.Align.START;
            info_label.margin_start = 12;
            info_label.get_style_context ().add_class ("h4");

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.vexpand = true;

            list_box = new Gtk.ListBox ();
            list_box.selection_mode = Gtk.SelectionMode.NONE;

            scrolled.add (list_box);

            add_button = new Gtk.Button.with_label (_("Add URL"));
            add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            add_button.margin_end = 6;
            add_button.sensitive = false;
            add_button.clicked.connect (on_entry_activate);

            entry = new Gtk.Entry ();
            entry.hexpand = true;
            entry.margin_start = 6;
            entry.placeholder_text = _("Add a new URL, for example: google.com");
            entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Invalid URL"));
            entry.changed.connect (on_entry_changed);
            entry.activate.connect (on_entry_activate);

            var main_box = new Gtk.Grid ();
            main_box.column_spacing = 6;
            main_box.row_spacing = 6;
            main_box.margin_top = main_box.margin_bottom = 6;
            main_box.attach (info_label, 0, 0, 2, 1);
            main_box.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 1, 2, 1);
            main_box.attach (scrolled, 0, 2, 2, 1);
            main_box.attach (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 3, 2, 1);
            main_box.attach (entry, 0, 4, 1, 1);
            main_box.attach (add_button, 1, 4, 1, 1);

            var frame = new Gtk.Frame (null);
            frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
            frame.add (main_box);

            add (frame);
            load_existing.begin ();
            show_all ();
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
            print ("URLS\n");
            foreach (weak Gtk.Widget url_entry in list_box.get_children ()) {
                block_urls += ((UrlEntry) url_entry).url;
                print (((UrlEntry) url_entry).url + "\n");
            }

            Utils.get_api ().set_user_daemon_block_urls.begin (user.get_user_name (), block_urls);
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
            } else {
                entry.secondary_icon_name = "process-error-symbolic";
            }
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
    }
}

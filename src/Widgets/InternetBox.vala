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
    public class InternetBox : Gtk.Box {
        public signal void update_key_file ();
        public string[] urls;

        private const string URL_REGEX_RULE = "[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,4}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)";

        private Act.User user;
        private Regex? url_regex = null;
        private List<UrlEntry> url_list;

        private Gtk.ListBox list_box;
        private Gtk.Entry entry;
        private Gtk.Button add_button;

        private class UrlEntry : Gtk.ListBoxRow {
            public signal void deleted ();
            private string url;

            public UrlEntry (string url) {
                this.url = url;

                var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic");
                delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
                delete_button.clicked.connect (() => {
                    deleted ();
                });

                var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                main_box.margin_start = 12;
                main_box.margin_end = 6;

                main_box.add (new Gtk.Label (url));
                main_box.pack_end (delete_button, false, false, 0);

                add (main_box);
                show_all ();
            }

            public string get_url () {
                return url;
            }
        }

        public InternetBox (Act.User user) {
            this.user = user;

            try {
                url_regex = new Regex (URL_REGEX_RULE, RegexCompileFlags.OPTIMIZE);
            } catch (RegexError e) {
                warning ("%s\n", e.message);
            }

            url_list = new List<UrlEntry> ();

            orientation = Gtk.Orientation.VERTICAL;
            margin_start = margin_end = 128;
            margin_bottom = 32;

            Gdk.RGBA bg = { 1, 1, 1, 1 };

            var frame = new Gtk.Frame (null);
            frame.hexpand = frame.vexpand = true;
            frame.override_background_color (0, bg);

            var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            main_box.hexpand = main_box.vexpand = true;
            main_box.margin_top = main_box.margin_bottom = 6;

            var info_label = new Gtk.Label (_("Blacklist the following sites:"));
            info_label.halign = Gtk.Align.START;
            info_label.margin_start = 12;
            info_label.get_style_context ().add_class ("h4");

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.vexpand = true;

            list_box = new Gtk.ListBox ();
            list_box.selection_mode = Gtk.SelectionMode.NONE;

            scrolled.add (list_box);

            var bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            bottom_box.margin_start = bottom_box.margin_end = 6;

            add_button = new Gtk.Button.with_label (_("Add URL"));
            add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            add_button.sensitive = false;
            add_button.clicked.connect (on_entry_activate);

            entry = new Gtk.Entry ();
            entry.hexpand = true;
            entry.set_placeholder_text (_("Add a new URL, for example: google.com"));
            entry.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, _("Invalid URL"));
            entry.changed.connect (on_entry_changed);
            entry.activate.connect (on_entry_activate);

            bottom_box.add (entry);
            bottom_box.pack_end (add_button, false, false, 0);

            main_box.add (info_label);
            main_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            main_box.add (scrolled);
            main_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            main_box.add (bottom_box);

            frame.add (main_box);

            add (frame);
            load_existing ();
            show_all ();
        }

        private void load_existing () {
            var key_file = new KeyFile ();
            try {
                key_file.load_from_file (Utils.build_app_lock_path (user), 0);
                urls = key_file.get_string_list (Vars.DAEMON_GROUP, Vars.BLOCK_URLS);
                foreach (string url in urls) {
                    add_entry (new UrlEntry (url));
                }
            } catch (Error e) {
                warning ("%s\n", e.message);
            }         
        }

        private void update () {
            string[] _urls = {};
            foreach (var url_entry in url_list) {
                _urls += url_entry.get_url ();
            }

            urls = _urls;
            update_key_file ();
        }

        private void on_entry_changed () {
            if (url_regex == null) {
                return;
            }

            bool valid = url_regex.match (entry.get_text ());
            add_button.sensitive = valid;
            if (valid || entry.get_text ().strip () == "") {
                entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, null);
            } else {
                entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "process-error-symbolic");
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

            var url_entry = new UrlEntry (url);
            add_entry (url_entry);

            entry.text = "";
            update ();
        }

        private void add_entry (UrlEntry url_entry) {
            url_list.append (url_entry);
            url_entry.deleted.connect (on_url_entry_deleted);

            list_box.add (url_entry);            
        }

        private void on_url_entry_deleted (UrlEntry url_entry) {
            url_list.remove (url_entry);
            list_box.remove (url_entry);
            update ();
        }
    }
}
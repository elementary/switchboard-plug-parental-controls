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
    public class TimeLimitView : Gtk.Grid {
        public weak Act.User user { get; construct; }

        private Gtk.SizeGroup title_group;

        private WeekSpinBox weekday_box;
        private WeekSpinBox weekend_box;

        public TimeLimitView (Act.User user) {
            Object (user: user);
        }

        construct {
            title_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

            weekday_box = new WeekSpinBox (
                ///TRANSLATORS: Refers to non-weekend days, as used in a title
                _("Weekdays"),
                ///TRANSLATORS: Refers to non-weekend days, as used in a sentence
                _("weekdays"),
                title_group,
                user
            );

            weekend_box = new WeekSpinBox (
                ///TRANSLATORS: Refers to weekend days, as used in a title
                _("Weekends"),
                ///TRANSLATORS: Refers to weekend days, as used in a sentence
                _("weekends"),
                title_group,
                user
            );

            row_spacing = 24;
            attach (weekday_box, 0, 0);
            attach (weekend_box, 0, 1);
            show_all ();

            weekday_box.changed.connect (() => update_pam ());
            weekend_box.changed.connect (() => update_pam ());

            load_restrictions ();

            weekday_box.notify["active"].connect (() => {
                update_pam ();
            });

            weekend_box.notify["active"].connect (() => {
                update_pam ();
            });
        }

        private void load_restrictions () {
            var token = PAM.Reader.get_token_for_user (Constants.PAM_TIME_CONF_PATH, user.get_user_name ());
            if (token == null) {
                return;
            }

            foreach (PAM.TimeInfo info in token.get_times_info ()) {
                switch (info.day_type) {
                    case PAM.DayType.WEEKDAY:
                        weekday_box.active = true;
                        weekday_box.set_from (info.from);
                        weekday_box.set_to (info.to);
                        break;
                    case PAM.DayType.WEEKEND:
                        weekend_box.active = true;
                        weekend_box.set_from (info.from);
                        weekend_box.set_to (info.to);
                        break;
                    default:
                        break;
                }
            }
        }

        public void update_pam (bool daemon_active = true) {
            if (!Utils.get_permission ().get_allowed ()) {
                return;
            }

            if ((weekday_box.active || weekend_box.active) && daemon_active) {
                string[] times = {};
                string[] users = { user.get_user_name () };

                if (weekday_box.active) {
                    times += PAM.DayType.WEEKDAY.to_string () + weekday_box.get_from () + "-" + weekday_box.get_to ();
                }

                if (weekend_box.active) {
                    times += PAM.DayType.WEEKEND.to_string () + weekend_box.get_from () + "-" + weekend_box.get_to ();
                }

                string input = PAM.Token.construct_pam_restriction_simple (users, times);
                Utils.get_api ().add_restriction_for_user.begin (input, true);
            } else {
                Utils.get_api ().remove_restriction_for_user.begin (user.get_user_name ());
            }
        }
    }

    private class WeekSpinBox : Gtk.Grid {
        public signal void changed ();

        public bool active { get; set; }
        public string title { get; construct; }
        public string sentence_case { get; construct; }
        public Gtk.SizeGroup size_group { get; construct; }
        public weak Act.User user { get; construct; }

        private Granite.Widgets.TimePicker picker_from;
        private Granite.Widgets.TimePicker picker_to;

        public WeekSpinBox (
            string title,
            string sentence_case,
            Gtk.SizeGroup size_group,
            Act.User user
        ) {
            Object (
                title: title,
                sentence_case: sentence_case,
                size_group: size_group,
                user: user
            );
        }

        construct {
            var enable_switch = new Gtk.Switch ();
            enable_switch.halign = Gtk.Align.START;
            enable_switch.valign = Gtk.Align.CENTER;

            var from_label = new Gtk.Label (_("From:"));
            from_label.halign = Gtk.Align.END;

            picker_from = new Granite.Widgets.TimePicker ();
            picker_from.hexpand = true;

            var to_label = new Gtk.Label (_("To:"));

            picker_to = new Granite.Widgets.TimePicker ();
            picker_to.hexpand = true;

            var label = new Gtk.Label (title);
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            size_group.add_widget (label);

            column_spacing = 12;
            row_spacing = 6;

            var message_not_limited = _("Screen Time for %s will not be limited during this period on %s.").printf (
                user.get_real_name (),
                sentence_case
            );
            var message_limited = _("%s will only be able to log in during this time on %s, and will be automatically logged out once this period ends:").printf (
                user.get_real_name (),
                sentence_case
            );

            var limit_description = new Gtk.Label (message_not_limited);
            limit_description.wrap = true;
            limit_description.xalign = 0;


            attach (label, 0, 0);
            attach (enable_switch, 1, 0);
            attach (limit_description, 0, 1, 4, 1);
            attach (from_label, 0, 2);
            attach (picker_from, 1, 2);
            attach (to_label, 2, 2);
            attach (picker_to, 3, 2);

            bind_property ("active", enable_switch, "active", GLib.BindingFlags.BIDIRECTIONAL);
            bind_property ("active", from_label, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            bind_property ("active", picker_from, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            bind_property ("active", to_label, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            bind_property ("active", picker_to, "sensitive", GLib.BindingFlags.SYNC_CREATE);

            notify["active"].connect (() => {
                if (active) {
                    limit_description.set_text (message_limited);
                } else {
                    limit_description.set_text (message_not_limited);
                }
            });

            picker_from.time_changed.connect (() => changed ());
            picker_to.time_changed.connect (() => changed ());
        }

        public string get_from () {
            return format_time_string (picker_from.time.get_hour ())
                + format_time_string (picker_from.time.get_minute ());
        }

        public string get_to () {
            return format_time_string (picker_to.time.get_hour ())
                + format_time_string (picker_to.time.get_minute ());
        }

        public void set_from (string from) {
            string hours = from.slice (0, 2);
            string minutes = from.substring (2);

            var time = new DateTime.local (
               new DateTime.now_local ().get_year (), 1, 1, int.parse (hours), int.parse (minutes), 0
            );

            picker_from.time = time;
        }

        public void set_to (string to) {
            string hours = to.slice (0, 2);
            string minutes = to.substring (2);

            var time = new DateTime.local (
               new DateTime.now_local ().get_year (), 1, 1, int.parse (hours), int.parse (minutes), 0
            );

            picker_to.time = time;
        }

        private string format_time_string (int val) {
            if (val < 10) {
                return "0" + val.to_string ();
            }

            return val.to_string ();
        }
    }
}

/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 *                         2015 Adam Bieńkowski
 */

public class PC.Widgets.TimeLimitView : Gtk.Box {
    public weak Act.User user { get; construct; }

    private WeekSpinBox weekday_box;
    private WeekSpinBox weekend_box;

    public TimeLimitView (Act.User user) {
        Object (user: user);
    }

    construct {
        weekday_box = new WeekSpinBox (
            ///TRANSLATORS: Refers to non-weekend days, as used in a title
            _("Weekdays"),
            false,
            user
        );

        weekend_box = new WeekSpinBox (
            ///TRANSLATORS: Refers to weekend days, as used in a title
            _("Weekends"),
            true,
            user
        );

        orientation = VERTICAL;
        spacing = 24;
        add (weekday_box);
        add (weekend_box);
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

    private class WeekSpinBox : Gtk.Grid {
        public signal void changed ();

        public bool active { get; set; }
        public string title { get; construct; }
        public bool is_weekend {get; construct; }
        public weak Act.User user { get; construct; }

        private Granite.TimePicker picker_from;
        private Granite.TimePicker picker_to;

        public WeekSpinBox (
            string title,
            bool is_weekend,
            Act.User user
        ) {
            Object (
                title: title,
                is_weekend: is_weekend,
                user: user
            );
        }

        construct {
            var enable_switch = new Gtk.Switch () {
                valign = START
            };

            var today_local = new GLib.DateTime.now_local ();
            var today_start = new GLib.DateTime.local (
                today_local.get_year (),
                today_local.get_month (),
                today_local.get_day_of_month (),
                0, 0, 0
            );

            var today_end = new GLib.DateTime.local (
                today_local.get_year (),
                today_local.get_month (),
                today_local.get_day_of_month (),
                23, 59, 59
            );

            picker_from = new Granite.Widgets.TimePicker () {
                hexpand = true,
                margin_end = 6,
                time = today_start
            };

            var from_label = new Gtk.Label (_("From:")) {
                mnemonic_widget = picker_from
            };

            picker_to = new Granite.Widgets.TimePicker () {
                hexpand = true,
                time = today_end
            };

            var to_label = new Gtk.Label (_("To:")) {
                mnemonic_widget = picker_to
            };

            var label = new Granite.HeaderLabel (title) {
                mnemonic_widget = enable_switch
            };

            string message_not_limited, message_limited;
            if (is_weekend) {
                message_not_limited = _("Screen Time is not limited on weekends.");
                ///TRANSLATORS: %s is the user's name
                message_limited = _("%s will only be able to log in during this time on weekends, and will be automatically logged out once this period ends:").printf (
                    user.get_real_name ()
                );
            } else {
                message_not_limited = _("Screen Time is not limited on weekdays.");
                ///TRANSLATORS: %s is the user's name
                message_limited = _("%s will only be able to log in during this time on weekdays, and will be automatically logged out once this period ends:").printf (
                    user.get_real_name ()
                );
            }

            var limit_description = new Gtk.Label (message_not_limited) {
                hexpand = true,
                wrap = true,
                xalign = 0
            };

            var duration_box = new Gtk.Box (HORIZONTAL, 6) {
                margin_top = 12
            };
            duration_box.add (from_label);
            duration_box.add (picker_from);
            duration_box.add (to_label);
            duration_box.add (picker_to);

            column_spacing = 12;
            attach (label, 0, 0);
            attach (limit_description, 0, 1);
            attach (enable_switch, 1, 0, 1, 2);
            attach (duration_box, 0, 2, 2);

            bind_property ("active", enable_switch, "active", BIDIRECTIONAL);
            bind_property ("active", from_label, "sensitive", SYNC_CREATE);
            bind_property ("active", picker_from, "sensitive", SYNC_CREATE);
            bind_property ("active", to_label, "sensitive", SYNC_CREATE);
            bind_property ("active", picker_to, "sensitive", SYNC_CREATE);

            notify["active"].connect (() => {
                if (active) {
                    limit_description.label = message_limited;
                } else {
                    limit_description.label = message_not_limited;
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

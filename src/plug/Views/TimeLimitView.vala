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
        private string plank_conf_file_path = "";
        public weak Act.User user { get; construct; }
        private Gtk.Switch limit_switch;
        private Gtk.ComboBoxText limit_combobox;

        private Gtk.Frame frame;

        private Gtk.SizeGroup title_group;

        private WeekSpinBox weekday_box;
        private WeekSpinBox weekend_box;

        public TimeLimitView (Act.User user) {
            Object (user: user);
            plank_conf_file_path = Path.build_filename (user.get_home_dir (), Constants.PLANK_CONF_DIR);

            limit_switch.notify["active"].connect (() => update_pam ());
            limit_switch.bind_property ("active", limit_combobox, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            limit_switch.bind_property ("active", frame, "sensitive", GLib.BindingFlags.SYNC_CREATE);

            limit_combobox.changed.connect (on_limit_combobox_changed);

            weekday_box.changed.connect (() => update_pam ());
            weekend_box.changed.connect (() => update_pam ());

            load_restrictions ();
        }

        construct {
            column_spacing = 12;
            row_spacing = 6;

            var limit_method_label = new Gtk.Label (_("Limit computer use:"));
            limit_method_label.halign = Gtk.Align.END;

            limit_switch = new Gtk.Switch ();
            limit_switch.valign = Gtk.Align.CENTER;

            limit_combobox = new Gtk.ComboBoxText ();
            limit_combobox.hexpand = true;
            limit_combobox.append (PAM.DayType.WEEKDAY.to_string () + PAM.DayType.WEEKEND.to_string (), _("On weekdays and weekends"));
            limit_combobox.append (PAM.DayType.WEEKDAY.to_string (), _("Only on weekdays"));
            limit_combobox.append (PAM.DayType.WEEKEND.to_string (), _("Only on weekends"));
            limit_combobox.active = 0;

            frame = new Gtk.Frame (null);
            frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

            var frame_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

            title_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

            weekday_box = new WeekSpinBox (_("Weekdays"), title_group);
            weekday_box.margin = 12;
            weekday_box.halign = Gtk.Align.CENTER;

            weekend_box = new WeekSpinBox (_("Weekends"), title_group);
            weekend_box.margin = 12;
            weekend_box.halign = Gtk.Align.CENTER;

            frame_box.add (weekday_box);
            frame_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            frame_box.add (weekend_box);
            frame.add (frame_box);

            attach (limit_method_label, 0, 0);
            attach (limit_switch, 1, 0);
            attach (limit_combobox, 2, 0);
            attach (frame, 0, 1, 3, 1);
            show_all ();
        }

        public void reset () {
            limit_switch.active = false;
        }

        private void load_restrictions () {
            var token = PAM.Reader.get_token_for_user (Constants.PAM_TIME_CONF_PATH, user.get_user_name ());
            if (token == null) {
                return;
            }

            limit_switch.active = true;

            string[] ids = {};
            foreach (PAM.TimeInfo info in token.get_times_info ()) {
                ids += info.day_type.to_string ();
                switch (info.day_type) {
                    case PAM.DayType.WEEKDAY:
                        weekday_box.set_from (info.from);
                        weekday_box.set_to (info.to);
                        break;
                    case PAM.DayType.WEEKEND:
                        weekend_box.set_from (info.from);
                        weekend_box.set_to (info.to);
                        break;
                    default:
                        break;
                }
            }

            if (ids.length > 0) {
                limit_combobox.active_id = string.joinv ("|", ids);    
            }
        }

        public void update_pam (bool daemon_active = true) {
            if (!Utils.get_permission ().get_allowed ()) {
                return;
            }

            if (limit_switch.get_active () && daemon_active) {
                string[] times = {};
                string[] users = { user.get_user_name () };
                unowned string id = limit_combobox.get_active_id ();

                if (PAM.DayType.WEEKDAY.to_string () in id) {
                    times += PAM.DayType.WEEKDAY.to_string () + weekday_box.get_from () + "-" + weekday_box.get_to ();
                }

                if (PAM.DayType.WEEKEND.to_string () in id) {
                    times += PAM.DayType.WEEKEND.to_string () + weekend_box.get_from () + "-" + weekend_box.get_to ();
                }

                string input = PAM.Token.construct_pam_restriction_simple (users, times);
                Utils.get_api ().add_restriction_for_user.begin (input, true);
            } else {
                Utils.get_api ().remove_restriction_for_user.begin (user.get_user_name ());
            }
        }

        private void on_limit_combobox_changed () {
            string id = limit_combobox.get_active_id ();

            if (PAM.DayType.WEEKDAY.to_string () in id && PAM.DayType.WEEKEND.to_string () in id) {
                weekday_box.sensitive = true;
                weekend_box.sensitive = true;
            } else if (PAM.DayType.WEEKDAY.to_string () in id) {
                weekday_box.sensitive = true;
                weekend_box.sensitive = false;
            } else if (PAM.DayType.WEEKEND.to_string () in id) {
                weekday_box.sensitive = false;
                weekend_box.sensitive = true;
            }

            update_pam ();
        }
    }
}

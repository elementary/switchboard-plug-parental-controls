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
    public class GeneralBox : Gtk.Grid {
        private string plank_conf_file_path = "";
        private Act.User user;
        private Gtk.CheckButton dock_btn;
        private Gtk.CheckButton print_btn;
        private Gtk.Switch limit_switch;
        private Gtk.ComboBoxText limit_combobox;

        private Gtk.Frame frame;

        private Gtk.SizeGroup title_group;

        private WeekSpinBox weekday_box;
        private WeekSpinBox weekend_box;

        public GeneralBox (Act.User user) {
            this.user = user;
            plank_conf_file_path = Path.build_filename (user.get_home_dir (), Constants.PLANK_CONF_DIR);

            dock_btn.notify["active"].connect (on_dock_btn_activate);
            print_btn.notify["active"].connect (on_print_conf_activate);

            limit_switch.notify["active"].connect (on_limit_switch_changed);
            limit_switch.bind_property ("active", limit_combobox, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            limit_switch.bind_property ("active", frame, "sensitive", GLib.BindingFlags.SYNC_CREATE);

            limit_combobox.changed.connect (on_limit_combobox_changed);

            weekday_box.changed.connect (update_pam);
            weekend_box.changed.connect (update_pam);

            load_restrictions ();
        }

        construct {
            column_spacing = 12;
            row_spacing = 6;

            var main_label = new Gtk.Label (_("Allow this user to:"));
            main_label.halign = Gtk.Align.END;

            dock_btn = new Gtk.CheckButton.with_label (_("Modify the dock"));
            dock_btn.halign = Gtk.Align.START;

            print_btn = new Gtk.CheckButton.with_label (_("Configure printing"));
            print_btn.halign = Gtk.Align.START;
            print_btn.margin_bottom = 18;

            // Temporarily disabled for beta release
            // Remove after both options are finished
            main_label.no_show_all = true;
            main_label.visible = false;

            dock_btn.no_show_all = true;
            dock_btn.visible = false;

            print_btn.no_show_all = true;
            print_btn.visible = false;
            // Temporarily disabled for beta release

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

            attach (main_label, 0, 0, 1, 1);
            attach (dock_btn, 1, 0, 2, 1);
            attach (print_btn, 1, 1, 2, 1);
            attach (limit_method_label, 0, 2, 1, 1);
            attach (limit_switch, 1, 2, 1, 1);
            attach (limit_combobox, 2, 2, 1, 1);
            attach (frame, 0, 3, 3, 1);
            show_all ();
        }

        public void refresh () {
            on_dock_btn_activate ();
            on_print_conf_activate ();
        }

        public void reset () {
            dock_btn.active = true;
            print_btn.active = true;
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

        public void update_pam () {
            if (!Utils.get_permission ().get_allowed ()) {
                return;
            }

            string[] times = {};
            string[] users = { user.get_user_name () };
            string id = limit_combobox.get_active_id ();

            if (PAM.DayType.WEEKDAY.to_string () in id) {
                times += PAM.DayType.WEEKDAY.to_string () + weekday_box.get_from () + "-" + weekday_box.get_to ();
            }

            if (PAM.DayType.WEEKEND.to_string () in id) {
                times += PAM.DayType.WEEKEND.to_string () + weekend_box.get_from () + "-" + weekend_box.get_to ();
            }

            string input = PAM.Token.construct_pam_restriction_simple (users, times);
            Utils.get_api ().add_restriction_for_user.begin (input, true);
        }

        private void on_dock_btn_activate () {
            set_lock_dock_active (!dock_btn.get_active ());
        }

        public void set_lock_dock_active (bool active) {
            if (Utils.get_permission ().get_allowed ()) {
                Utils.get_api ().lock_dock_icons_for_user.begin (user.get_user_name (), active);
            }
        }

        private void on_print_conf_activate () {
            set_printer_active (print_btn.get_active ());
        }

        public void set_printer_active (bool active) {
            string[] users = { user.get_user_name () };

            try {
                CupsPkHelper? helper = Bus.get_proxy_sync (BusType.SYSTEM, Constants.CUPS_PK_HELPER_IFACE, "/");
                if (helper == null) {
                    return;
                }

                foreach (string printer in get_printers ()) {
                    if (active) {
                        helper.printer_set_users_allowed (printer, users);
                    } else {
                        helper.printer_set_users_denied (printer, users);
                    }
                }
            } catch (Error e) {
                warning ("%s\n", e.message);
            } 
        }  

        private void on_limit_switch_changed () {
            if (limit_switch.get_active ()) {
                update_pam ();
            } else if (Utils.get_permission ().get_allowed ()) {
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

        private string[] get_printers () {
            string[] retval = {};
            string path = "/etc/cups/ppd";
            var file = File.new_for_path (path);

            FileInfo info = null;
            try {
                var enumerator = file.enumerate_children ("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                while ((info = enumerator.next_file ()) != null) {
                    string printer = info.get_name ().split (".")[0];
                    if (!(printer in retval)) {
                        retval += printer;
                    }
                }
            } catch (IOError e) {
                warning ("%s\n", e.message);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }

            return retval;
        }      
    }
}

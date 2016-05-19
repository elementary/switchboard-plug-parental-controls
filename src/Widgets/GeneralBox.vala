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
    public class GeneralBox : Gtk.Grid {
        private string plank_conf_file_path = "";
        private Act.User user;
        private Gtk.CheckButton dock_btn;
        private Gtk.CheckButton print_btn;
        private Gtk.Switch limit_switch;
        private Gtk.ComboBoxText limit_combobox;

        private Gtk.Frame frame;

        private WeekSpinBox weekday_box;
        private WeekSpinBox weekend_box;

        public GeneralBox (Act.User user) {
            this.user = user;
            plank_conf_file_path = Path.build_filename (user.get_home_dir (), Vars.PLANK_CONF_DIR);

            dock_btn.notify["active"].connect (on_dock_btn_activate);

            print_btn.notify["active"].connect (on_print_conf_activate);

            limit_switch.notify["active"].connect (on_limit_switch_changed);
            limit_switch.bind_property ("active", limit_combobox, "sensitive", GLib.BindingFlags.SYNC_CREATE);
            limit_switch.bind_property ("active", frame, "sensitive", GLib.BindingFlags.SYNC_CREATE);

            limit_combobox.changed.connect (on_limit_combobox_changed);

            weekday_box.changed.connect (update_pam);
            weekend_box.changed.connect (update_pam);

            monitor_updates ();
            update ();
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

            var limit_method_label = new Gtk.Label (_("Limit computer use:"));
            limit_method_label.halign = Gtk.Align.END;

            limit_switch = new Gtk.Switch ();
            limit_switch.valign = Gtk.Align.CENTER;

            limit_combobox = new Gtk.ComboBoxText ();
            limit_combobox.hexpand = true;
            limit_combobox.append (Vars.ALL_ID, _("On weekdays and weekends"));
            limit_combobox.append (Vars.WEEKDAYS_ID, _("Only on weekdays"));
            limit_combobox.append (Vars.WEEKENDS_ID, _("Only on weekends"));
            limit_combobox.active_id = "all";

            frame = new Gtk.Frame (null);
            frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

            var frame_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

            weekday_box = new WeekSpinBox (_("Weekdays"));
            weekday_box.margin = 12;
            weekday_box.halign = Gtk.Align.CENTER;

            weekend_box = new WeekSpinBox (_("Weekends"));
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
            var restricts = PAMControl.get_all_restrictions ();
            foreach (var restrict in restricts) {
                if (restrict.user == user.get_user_name ()) {
                    limit_switch.active = true;

                    limit_combobox.active_id = restrict.day_id;
                    switch (restrict.day_id) {
                        case Vars.ALL_ID:
                            string from_weekday = restrict.weekday_hours.split ("-")[0];
                            string to_weekday = restrict.weekday_hours.split ("-")[1];
                            string from_weekend = restrict.weekend_hours.split ("-")[0];
                            string to_weekend = restrict.weekend_hours.split ("-")[1];

                            weekday_box.set_from (from_weekday);
                            weekday_box.set_to (to_weekday);

                            weekend_box.set_from (from_weekend);
                            weekend_box.set_to (to_weekend);
                            break;
                        case Vars.WEEKDAYS_ID:
                            weekday_box.set_from (restrict.from);
                            weekday_box.set_to (restrict.to);
                            break;
                        case Vars.WEEKENDS_ID:
                            weekend_box.set_from (restrict.from);
                            weekend_box.set_to (restrict.to);
                            break;
                        default:
                            break;
                    }
                }
            }
        }

        private void update_pam () {
            string restrict = "";
            string id = limit_combobox.get_active_id ();
            switch (id) {
                case Vars.ALL_ID:
                    restrict = generate_pam_conf_restriction (id, weekday_box.get_from (), weekday_box.get_to ());
                    restrict += "|" + weekend_box.get_from () + "-" + weekend_box.get_to ();
                    break;
                case Vars.WEEKDAYS_ID:
                    restrict = generate_pam_conf_restriction (id, weekday_box.get_from (), weekday_box.get_to ());
                    break;
                case Vars.WEEKENDS_ID:
                    restrict = generate_pam_conf_restriction (id, weekend_box.get_from (), weekend_box.get_to ());
                    break;
            }

            PAMControl.try_add_restrict_line (user.get_user_name (), restrict);
        }

        private string generate_pam_conf_restriction (string id, string from, string to) {
            string retval = "*;*;";
            string days = "";
            switch (id) {
                case Vars.ALL_ID:
                    days = "Al";
                    break;
                case Vars.WEEKDAYS_ID:
                    days = "Wk";
                    break;
                case Vars.WEEKENDS_ID:
                    days = "Wd";
                    break;
            }

            retval += user.get_user_name () + ";" + days + from + "-" + to;
            return retval;
        }

        private void monitor_updates () {
            try {
                var monitor = File.new_for_path (plank_conf_file_path).monitor_file (FileMonitorFlags.NONE);
                monitor.changed.connect (update);
            } catch (IOError e) {
                warning ("%s\n", e.message);
            }
        }

        private void update () {
            var key_file = new KeyFile ();
            try {
                key_file.load_from_file (plank_conf_file_path, KeyFileFlags.NONE);
                dock_btn.active = !key_file.get_boolean (Vars.PLANK_CONF_GROUP, Vars.PLANK_CONF_LOCK_ITEMS_KEY);
            } catch (FileError e) {
                dock_btn.active = true;
                warning ("%s\n", e.message);
            } catch (Error e) {
                dock_btn.active = true;
                warning ("%s\n", e.message);
            }

            /* TODO: Get denied users for printing configuration */

            /* For now, we assume that printing is enabled */
            print_btn.active = true;
        }

        private void on_dock_btn_activate () {
            set_lock_dock_active (!dock_btn.get_active ());
        }

        public void set_lock_dock_active (bool active) {
            if (Utils.get_permission ().get_allowed ()) {
                Utils.call_cli ({"--user", user.get_user_name (), "--lock-dock", active.to_string ()});
            }
        }

        private void on_print_conf_activate () {
            set_printer_active (print_btn.get_active ());
        }

        public void set_printer_active (bool active) {
            var builder = new VariantBuilder (new VariantType ("as"));
            builder.add ("s", user.get_user_name ());

            string method = "PrinterSetUsersDenied";
            if (active) {
                method = "PrinterSetUsersAllowed";
            }

            try {
                var conn = Bus.get_sync (BusType.SYSTEM);
                foreach (string printer in get_printers ()) {
                    conn.call_sync ("org.opensuse.CupsPkHelper.Mechanism",
                                    "/",
                                    "org.opensuse.CupsPkHelper.Mechanism",
                                    method,
                                    new Variant ("(sas)", printer, builder),
                                    null,
                                    0, -1);
                }
            } catch (Error e) {
                warning ("%s\n", e.message);
            } 
        }  

        private void on_limit_switch_changed () {
            if (limit_switch.get_active ()) {
                update_pam ();
            } else {
                PAMControl.try_remove_user_restrict (user.get_user_name ());
            }
        }

        private void on_limit_combobox_changed () {
            switch (limit_combobox.get_active_id ()) {
                case Vars.ALL_ID:
                    weekday_box.sensitive = true;
                    weekend_box.sensitive = true;
                    break;
                case Vars.WEEKDAYS_ID:
                    weekday_box.sensitive = true;
                    weekend_box.sensitive = false;      
                    break;
                case Vars.WEEKENDS_ID:
                    weekday_box.sensitive = false;
                    weekend_box.sensitive = true;
                    break;                                
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

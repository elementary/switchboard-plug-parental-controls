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

[DBus (name = "org.freedesktop.DisplayManager.Seat")]
public interface Seat : Object {
    [DBus (name = "SwitchToGreeter")]
    public abstract void switch_to_greeter () throws Error;         
}

namespace PC.Daemon {
    public class Daemon : Gtk.Application {
        private const int MINUTE_INTERVAL = 60;
        private const int HOUR_INTERVAL = 3600;
        private string user_name = "";

        public static int main (string[] args) {
            Gtk.init (ref args);

            var app = new Daemon ();
            app.flags = ApplicationFlags.HANDLES_COMMAND_LINE;
            return app.run (args);
        }

        public override int command_line (ApplicationCommandLine command_line) {
            string[] args = command_line.get_arguments ();
            string*[] _args = new string[args.length];
            for (int i = 0; i < args.length; i++) {
                _args[i] = args[i];
            }

            if (_args.length != 2) {
                command_line.print ("Usage: %s user\n", _args[0]);
            } else {
                if (Posix.getuid () != 0) {
                    command_line.print ("Error: To run this program you need root privigiles.\n\n");
                    terminate (1);
                }

                user_name = _args[1];
                command_line.print ("Initializing Parental Controls Daemon for %s.\n", user_name);
                activate ();
            }

            return 0;
        }

        public override void activate () {
            if (user_name != null && user_name != "") {
                Utils.get_usermanager ().notify["is-loaded"].connect (on_usermanager_loaded);
            }

            Gtk.main ();
        }

        private void on_usermanager_loaded () {
            if (!Utils.get_usermanager ().is_loaded) {
                return;
            }

            Utils.set_user_name (user_name);
            print ("Loading user configuration...\n");

            bool pam_lock = false;

            var current_user = Utils.get_current_user ();
            if (current_user == null) {
                print ("Error: Could not load user. Aborting...\n");
                terminate (1);
            }

            var app_lock_core = new AppLock.AppLockCore (current_user);
            try {
                if (!app_lock_core.key_file.get_boolean (Vars.DAEMON_GROUP, Vars.DAEMON_ACTIVE)) {
                    terminate (0);
                }
            } catch (Error e) {
                warning ("%s\n", e.message);
            }

            bool app_lock = app_lock_core.valid;

            if (app_lock_core.valid) {
                app_lock_core.start.begin ();
            }

            var restricts = PAMControl.get_all_restrictions ();
            foreach (var restrict in restricts) {
                if (restrict.user == current_user.get_user_name ()) {
                    pam_lock = true;

                    var current_date = new DateTime.now_local ();
                    string minute = current_date.get_minute ().to_string ();
                    if (int.parse (minute) < 10) {
                        minute = "0" + minute;
                    }

                    switch (restrict.day_id) {
                        case Vars.WEEKDAYS_ID:
                            if (current_date.get_day_of_week () < 6) {
                                int estimated_time = int.parse (restrict.to);
                                var span = get_difference_span (estimated_time, current_date);
                                start_loop ((int)((span / GLib.TimeSpan.MINUTE * -1) + 1) - 24 * MINUTE_INTERVAL);
                            }

                            break;
                        case Vars.WEEKENDS_ID:
                            if (current_date.get_day_of_week () >= 6) {
                                int estimated_time = int.parse (restrict.to);
                                var span = get_difference_span (estimated_time, current_date);
                                start_loop ((int)((span / GLib.TimeSpan.MINUTE * -1) + 1) - 24 * MINUTE_INTERVAL);
                            }

                            break;
                        case Vars.ALL_ID:
                            int estimated_time = 2400;
                            if (current_date.get_day_of_week () < 6) {
                                estimated_time = int.parse (restrict.weekday_hours.split ("-")[1]);
                            } else if (current_date.get_day_of_week () >= 6) {
                                estimated_time = int.parse (restrict.weekend_hours.split ("-")[1]);
                            }
                            
                            var span = get_difference_span (estimated_time, current_date);
                            int minutes = (int)((span / GLib.TimeSpan.MINUTE * -1) + 1) - 24 * MINUTE_INTERVAL;
                            if (minutes > 0) {
                                start_loop (minutes);
                            } else {
                                this.lock ();
                            }

                            break;
                        default:
                            break;
                    }
                }
            }  

            if (!app_lock && !pam_lock) {
                app_lock_core.stop ();

                print ("User %s does not have any restrictions. Aborting...\n", user_name);
                terminate ();
            }        

            print ("AppLock events: %s\n", app_lock.to_string ());
            print ("PAM restrict events: %s\n", pam_lock.to_string ());
        }

        private void terminate (int exit_code = 0) {
            Gtk.main_quit ();
            Process.exit (exit_code);            
        }

        private TimeSpan get_difference_span (int estimated_time, DateTime current_date) {
            bool end_day = (estimated_time == 2400 || estimated_time == 0);
            if (end_day) {
                estimated_time = 2359;
            }

            char[] tmp = estimated_time.to_string ().to_utf8 ();
            int _h, _m;
            _h = int.parse (tmp[0].to_string () + tmp[1].to_string ());
            _m = int.parse (tmp[2].to_string () + tmp[3].to_string ());

            var estimated_date = new DateTime.local (current_date.get_year (),
                                                    current_date.get_month (),
                                                    current_date.get_day_of_week (),
                                                    _h, _m, 0);

            var span = current_date.difference (estimated_date);            
            if (end_day) {
                span -= GLib.TimeSpan.MINUTE;
            }

            return span;
        }

        private int get_estimated_hours (int minutes) {
            if (minutes >= MINUTE_INTERVAL) {
                return minutes / MINUTE_INTERVAL;
            }

            return 0;
        }

        private void start_loop (int minutes) {
            int _hours = get_estimated_hours (minutes);
            int remaining_minutes = minutes - (MINUTE_INTERVAL * _hours);
            send_notification (_hours, remaining_minutes);

            schedule_notification (remaining_minutes, 5);
            schedule_notification (remaining_minutes, 1);

            Timeout.add_seconds (MINUTE_INTERVAL, () => {
                remaining_minutes--;
                if (remaining_minutes == 0) {
                    this.lock ();
                }

                return (remaining_minutes != 0);
            });

            Timeout.add_seconds (HOUR_INTERVAL, () => {
                int hours = get_estimated_hours (minutes);
                if (hours > 0) {
                    int tmp = minutes - (MINUTE_INTERVAL * hours);
                    send_notification (hours, tmp);
                }   

                return (hours != 0 || minutes != 0);
            });
        }

        private void schedule_notification (int remaining_minutes, int minutes) {
            Timeout.add_seconds ((remaining_minutes - minutes) * MINUTE_INTERVAL, () => {
                send_notification (0, minutes);

                return false;
            });
        }

        private void lock () {
            string? seat_path = Environment.get_variable ("XDG_SEAT_PATH");
            if (seat_path == "" || seat_path == null) {
                seat_path = "/org/freedesktop/DisplayManager/Seat0";
            }

            try {
                Seat? seat = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.DisplayManager", seat_path); 
                seat.switch_to_greeter ();
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }   

        private new void send_notification (ulong hours = 0, ulong minutes = 0) {
            string time = "";
            if (hours > 0) {
                time = ngettext (_("%ld hour"), _("%ld hours"), (ulong)hours).printf (minutes);

                if (minutes > 0) {
                    time += " " + _("and") + " " + ngettext (_("minute"), _("minutes"), (ulong)minutes);
                }  

            } else if (minutes > 0) {
                time = ngettext (_("%ld minute"), _("%ld minutes"), (ulong)minutes).printf (minutes);
            }

            string body = _("The computer will lock after %s.").printf (time);
            if (minutes <= 10) {
                body += " " + _("Make sure to close all applications before your computer will be locked.");
            }

            var notification = new Notification (_("Time left"));
            try {
                var pix = Icon.new_for_string ("dialog-warning");
                notification.set_icon (pix);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }

            notification.set_body (body);
            base.send_notification (null, notification);
        } 
    }
}

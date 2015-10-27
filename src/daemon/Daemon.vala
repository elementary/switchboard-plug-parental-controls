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
    public class App : Gtk.Application {
        public static int main (string[] args) {
            Gtk.init (ref args);
            var app = new App ();
            return app.run (args);
        }

        public override void activate () {
            var loop = new MainLoop ();

            PC.Utils.get_usermanager ().notify["is-loaded"].connect (() => {
            	var current_user = Utils.get_current_user ();
                var watcher = new AppLock.ProcessWatcher (current_user);
                if (watcher == null || !watcher.update ()) {
                	watcher.unref ();
                }

                var restricts = PAMControl.get_all_restrictions ();
                bool quit = true;
                foreach (var restrict in restricts) {
                    if (restrict.user == current_user.get_user_name ()) {
                        quit = false;

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
                                    start_loop ((int)((span / GLib.TimeSpan.MINUTE * -1) + 1) - 24 * 60);
                                }

                                break;
                            case Vars.WEEKENDS_ID:
                                if (current_date.get_day_of_week () >= 6) {
                                    int estimated_time = int.parse (restrict.to);
                                    var span = get_difference_span (estimated_time, current_date);
                                    start_loop ((int)((span / GLib.TimeSpan.MINUTE * -1) + 1) - 24 * 60);
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
                                int minutes = (int)((span / GLib.TimeSpan.MINUTE * -1) + 1) - 24 * 60;
                                if (minutes > 0) {
                                    start_loop (minutes);
                                } else {
                                    this.lock ();
                                    loop.quit ();
                                }

                                break;
                            default:
                                loop.quit ();
                                break;
                        }
                    }
                }
            });

            loop.run ();
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
            if (minutes >= 60) {
                return minutes / 60;
            }

            return 0;
        }

        private void start_loop (int minutes) {
            int _hours = get_estimated_hours (minutes);
            int remaining_minutes = minutes - (60 * _hours);
            send_notification (_hours, remaining_minutes);

            Timeout.add_seconds ((remaining_minutes - 5) * 60, () => {
                send_notification (0, 5);

                return false;
            });

            Timeout.add_seconds ((remaining_minutes - 1) * 60, () => {
                send_notification (0, 1);

                return false;
            });

            Timeout.add_seconds (60, () => {
                remaining_minutes--;
                if (remaining_minutes == 0) {
                    this.lock ();
                }

                return (remaining_minutes != 0);
            });

            Timeout.add_seconds (3600, () => {
                int hours = get_estimated_hours (minutes);
                if (hours > 0) {
                    int tmp = minutes - (60 * hours);
                    send_notification (hours, tmp);
                }   

                return (hours != 0 || minutes != 0);
            });
        }

        private void lock () {
        	string? seat_path = Environment.get_variable ("XDG_SEAT_PATH");
        	if (seat_path == "" || seat_path == null) {
        		seat_path = "/org/freedesktop/DisplayManager/Seat0";
        	}

        	Seat? seat = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.DisplayManager", seat_path); 
        	try {
        		seat.switch_to_greeter ();
        	} catch (Error e) {
        		warning ("%s\n", e.message);
        	}
        }	

        private new void send_notification (int hours = 0, int minutes = 0) {
            string time = "";
            if (hours > 0) {
            	time = ngettext (_("hour"), _("hours"), (ulong)hours);

                if (minutes > 0) {
                    time += " " + _("and") + " " + ngettext (_("minute"), _("minutes"), (ulong)minutes);
                }  

            } else if (minutes > 0) {
            	time = ngettext (_("minute"), _("minutes"), (ulong)minutes);
            }

            string body = _("The computer will lock after %s.").printf (time);
            if (minutes <= 10) {
                body += " " + _("Make sure to close all applications before your computer will be locked.");
            }

            var notification = new Notification ("Time left");
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

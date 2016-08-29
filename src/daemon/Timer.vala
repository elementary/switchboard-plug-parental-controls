// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016 Adam Bieńkowski (https://launchpad.net/switchboard-plug-parental-controls)
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

namespace PC.Daemon {
    public class Timer : Object {
        private const int MINUTE_INTERVAL = 60;
        private const int HOUR_INTERVAL = 3600;

        public signal void terminate ();

        private PAM.Token token;
        private uint[] timeout_ids;

        public Timer (PAM.Token token) {
            this.token = token;
        }

        public void start () {
            var times_info = token.get_times_info ();
            if (times_info.length () == 0) {
                return;
            }

            PAM.TimeInfo? current = null;

            int day_of_week = new DateTime.now_local ().get_day_of_week ();
            foreach (PAM.TimeInfo info in times_info) {
                if ((day_of_week < 6 && info.day_type == PAM.DayType.WEEKDAY)
                    || (day_of_week >= 6 && info.day_type == PAM.DayType.WEEKEND)
                    || info.day_type == PAM.DayType.ALL) {
                    current = info;
                    break;
                }
            }

            if (current == null) {
                return;
            }

            var span = get_difference_span (current.to);
            int minutes = ((int)(span / GLib.TimeSpan.MINUTE)).abs ();
            
            if (minutes > 0) {
                start_loop (minutes);
            } else {
                terminate ();
            }  

            timeout_ids += Timeout.add_seconds (HOUR_INTERVAL * 24, () => {
                start ();
                return true;
            });
        }

        public void stop () {
            foreach (uint timeout_id in timeout_ids) {
                GLib.Source.remove (timeout_id);
            }
        }

        private TimeSpan get_difference_span (string estimated_time_str) {
            int estimated_time = int.parse (estimated_time_str);

            bool end_day = estimated_time == 2400 || estimated_time == 0;
            if (end_day) {
                estimated_time = 2359;
            }

            int hour = int.parse (estimated_time_str.slice (0, 2));
            int minute = int.parse (estimated_time_str.substring (2));

            var current_date = new DateTime.now_local ();
            var estimated_date = current_date.add_full (0, 0, 0,
                                                        hour - current_date.get_hour (),
                                                        minute - current_date.get_minute (),
                                                        0);
            var span = estimated_date.difference (current_date);
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
            Server.get_default ().show_timeout (minutes / MINUTE_INTERVAL, minutes % MINUTE_INTERVAL);
            timeout_ids += Timeout.add_seconds (MINUTE_INTERVAL, () => {
                minutes--;
                if (minutes == MINUTE_INTERVAL ||
                    minutes == 10 ||
                    minutes == 5 ||
                    minutes == 1) {
                    Server.get_default ().show_timeout (minutes / MINUTE_INTERVAL, minutes % MINUTE_INTERVAL);
                }

                if (minutes == 0) {
                    terminate ();
                }

                return (minutes > 0);
            });
        }   
    }
}
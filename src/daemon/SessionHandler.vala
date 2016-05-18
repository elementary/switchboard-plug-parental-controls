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

 namespace PC.Daemon {
    public class SessionHandler : Object {
        private const int MINUTE_INTERVAL = 60;
        private const int HOUR_INTERVAL = 3600;

        public Core core;
        public IptablesHelper iptables_helper;

        private ISession session;
        private Server server;

        private bool can_start = true;

        public SessionHandler (ISession _session) {
            session = _session;
            server = Server.get_default ();
            Utils.set_user_name (session.name);

            core = new Core (Utils.get_current_user (), server);

            try {
                if (!core.key_file.has_group (Vars.DAEMON_GROUP) || !core.key_file.get_boolean (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_ACTIVE)) {
                    can_start = false;
                }
            } catch (Error e) {
                warning ("%s\n", e.message);
            }

            string[] block_urls = {};
            try {
                block_urls = core.key_file.get_string_list (Vars.DAEMON_GROUP, Vars.DAEMON_KEY_BLOCK_URLS);
            } catch (KeyFileError e) {
                warning ("%s\n", e.message);
            }

            iptables_helper = new IptablesHelper (block_urls);
        }

        public void start () {
            if (!can_start) {
                return;
            }

            if (core.valid) {
                core.start.begin ();
            }

            if (iptables_helper.valid) {
                iptables_helper.add_rules ();
            }

            var restricts = PAMControl.get_all_restrictions ();
            foreach (var restrict in restricts) {
                if (restrict.user == Utils.get_current_user ().get_user_name ()) {
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
                                lock_session ();
                            }

                            break;
                        default:
                            break;
                    }
                }
            } 
        }

        public void stop () {
            core.stop ();
            iptables_helper.reset ();
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
            server.send_time_notification (_hours, remaining_minutes);

            schedule_notification (remaining_minutes, 5);
            schedule_notification (remaining_minutes, 1);

            Timeout.add_seconds (MINUTE_INTERVAL, () => {
                remaining_minutes--;
                if (remaining_minutes == 0) {
                    lock_session ();
                }

                return (remaining_minutes != 0);
            });

            Timeout.add_seconds (HOUR_INTERVAL, () => {
                int hours = get_estimated_hours (minutes);
                if (hours > 0) {
                    server.send_time_notification (hours, minutes - (MINUTE_INTERVAL * hours));
                }   

                return (hours != 0 || minutes != 0);
            });
        }

        private void schedule_notification (int remaining_minutes, int minutes) {
            Timeout.add_seconds ((remaining_minutes - minutes) * MINUTE_INTERVAL, () => {
                server.send_time_notification (0, minutes);

                return false;
            });
        }

        private void lock_session () {
            try {
                session.lock ();
            } catch (IOError e) {
                warning ("%s\n", e.message);
            }
        }          
    }
}
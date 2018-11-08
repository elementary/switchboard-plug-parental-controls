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

namespace PC.PAM {
    public enum DayType {
        UNKNOWN,
        ALL,
        WEEKDAY,
        WEEKEND;

        public static DayType to_enum (string str) {
            switch (str) {
                case "Al":
                    return ALL;
                case "Wk":
                    return WEEKDAY;
                case "Wd":
                    return WEEKEND;
                default:
                    return UNKNOWN;
            }
        }

        public string to_string () {
            switch (this) {
                case ALL:
                    return "Al";
                case WEEKDAY:
                    return "Wk";
                case WEEKEND:
                    return "Wd";
                default:
                case UNKNOWN:
                    return "unknown";                
            }
        }
    }

    public class TimeInfo {
        public DayType day_type = DayType.UNKNOWN;
        public string from = "";
        public string to = "";
    }

    public class Token : Object {
        private const int SERVICES_INDEX = 0;
        private const int TTYS_INDEX = 1;
        private const int USERS_INDEX = 2;
        private const int TIMES_INDEX = 3;

        private const string TYPE_SEPARATOR = ";";
        private const string LIST_SEPARATOR = "|";

        public string[] services;
        public string[] ttys;
        public string[] users;
        public string[] times;

        public static Token? parse_line (string line) {
            string[] strv = line.split (TYPE_SEPARATOR);
            if (strv.length != 4) {
                return null;
            }

            var token = new Token ();
            token.services = strv[SERVICES_INDEX].split (LIST_SEPARATOR);
            token.ttys = strv[TTYS_INDEX].split (LIST_SEPARATOR);
            token.users = strv[USERS_INDEX].split (LIST_SEPARATOR);
            token.times = strv[TIMES_INDEX].split (LIST_SEPARATOR);
            return token;
        }

        public static List<Token> parse (string str) {
            var list = new List<Token> ();

            foreach (string line in str.split ("\n")) {
                var token = parse_line (line);
                if (token != null) {
                    list.append (token);
                }
            }

            return list;
        }

        public static string construct_pam_restriction (string[] services, string[] ttys, string[] users, string[] times) {
            string services_str = string.joinv (LIST_SEPARATOR, services);
            string ttys_str = string.joinv (LIST_SEPARATOR, ttys);
            string users_str = string.joinv (LIST_SEPARATOR, users);
            string times_str = string.joinv (LIST_SEPARATOR, times);

            return "%s;%s;%s;%s".printf (services_str, ttys_str, users_str, times_str);
        }

        public static string construct_pam_restriction_simple (string[] users, string[] times) {
            return construct_pam_restriction ({ "*" }, { "*" }, users, times);
        }

        public List<TimeInfo> get_times_info () {
            var list = new List<TimeInfo> ();

            if (times.length == 0) {
                return list;
            }

            foreach (string time in times) {
                string[] bounds = time.substring (2).split ("-");
                if (bounds.length < 2) {
                    continue;
                }

                var info = new TimeInfo ();
                info.day_type = DayType.to_enum (time.slice (0, 2));
                info.from = bounds[0];
                info.to = bounds[1];
                
                list.append (info);
            }

            return list;
        }

        public string get_user_arg0 () {
            if (users.length == 0) {
                return "";
            }

            return users[0];
        }

        public string to_string () {
            return construct_pam_restriction (services, ttys, users, times);
        }

        public void get_weekday_hours (out int from, out int to) {
            if (times.length < 1) {
                from = 0;
                to = 0;
                return;
            }

            string[] bounds = times[0].substring (2).split ("-");
            if (bounds.length < 2) {
                from = 0;
                to = 0;                
                return;
            }

            from = int.parse (bounds[0]);
            to = int.parse (bounds[1]);
        }

        public void get_weekend_hours (out int from, out int to) {
            if (times.length < 2) {
                from = 0;
                to = 0;
                return;
            }

            string[] bounds = times[1].split ("-");
            if (bounds.length < 2) {
                from = 0;
                to = 0;
                return;                
            }

            from = int.parse (bounds[0]);
            to = int.parse (bounds[1]);
        }
    }
}

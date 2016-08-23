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
                case "Wd":
                    return WEEKDAY;
                case "Wk":
                    return WEEKEND;
                default:
                    return UNKNOWN;
            }
        }
    }

    public class Token : Object {
        private const int SERVICES_INDEX = 0;
        private const int TTYS_INDEX = 1;
        private const int USERS_INDEX = 2;
        private const int TIMES_INDEX = 3;

        private const string TYPE_SEPARATOR = ";";
        private const string LIST_SEPARATOR = "|";

        public string[] services { get; set; }
        public string[] ttys { get; set; }
        public string[] users { get; set; }
        public string[] times { get; set; }

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

        private static string construct_pam_restriction (string[] services, string[] ttys, string users[], string[] times) {
            string services_list = string.join (LIST_SEPARATOR, services);
            string ttys_list = string.join (LIST_SEPARATOR, ttys);
            string users_list = string.join (LIST_SEPARATOR, users);
            string times_list = string.join (LIST_SEPARATOR, times);

            return "%s;%s;%s;%s".printf (services_list, ttys_list, users_list, times_list);
        }

        public static string construct_pam_restriction_simple (string user, string[] times) {
            return construct_pam_restriction ({ "*" }, { "*" }, { user }, times);
        }

        public DayType get_day_type () {
            if (times.length == 0) {
                return DayType.UNKNOWN;
            }

            return DayType.to_enum (times[0].slice (0, 2));
        }

        public string get_user_arg0 () {
            if (users.length == 0) {
                return "";
            }

            return users[0];
        }

        public void get_weekday_hours (out int from, out int to) {
            string[] bounds = times[0].slice (2, -1).split ("-");
            from = int.parse (bounds[0]);
            to = int.parse (bounds[1]);
        }

        public void get_weekend_hours (out int from, out int to) {
            string[] bounds = times[1].split ("-");
            from = int.parse (bounds[0]);
            to = int.parse (bounds[1]);
        }
    }
}
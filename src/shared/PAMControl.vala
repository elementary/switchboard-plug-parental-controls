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

namespace PC {
    public struct PAMRestrictInfo {
        public string user;
        public string day_id;
        public string weekday_hours;
        public string weekend_hours;  
        public string from;
        public string to;
    }

    public class PAMControl : Object {
        private static string get_conf_section () {
            string contents = "";
            try {
                FileUtils.get_contents ("/etc/security/time.conf", out contents);
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }
            
            try {
                var regex = new Regex (Vars.PAM_CONF_REGEX);

                if (regex.match (contents)) {
                    int i = 0;
                    foreach (string str in regex.split (contents)) {
                        // Do not replace the contents of the PC plug section
                        if (i != 1) {
                            contents = contents.replace (str, "");
                        }

                        i++;
                    }
                } else {
                    return "";
                }
            } catch (RegexError e) {
                warning ("%s\n", e.message);
            }


            return contents;
        }

        public static List<PAMRestrictInfo?> get_all_restrictions () {
            var restrictions = new List<PAMRestrictInfo?> ();
            string conf = get_conf_section ();

            foreach (string line in conf.split ("\n")) {
                if (!line.has_prefix ("#")) {
                    var restrict_info = PAMRestrictInfo ();
                    string[] units = line.split (";");
                    if (units.length >= 4) {
                        restrict_info.user = units[2];
                        string time = units[3];
                        time = time.replace ("!", "");

                        char[] time_chars = time.to_utf8 ();
                        string day = time_chars[0].to_string () + time_chars[1].to_string ();
                        switch (day.down ()) {
                            case "al":
                                restrict_info.day_id = "all";
                                break;
                            case "wk":
                                restrict_info.day_id = "weekdays";
                                break;
                            case "wd":
                                restrict_info.day_id = "weekends";
                                break;
                            default:
                                restrict_info.day_id = "";
                                break;
                        }

                        string hours = time.replace (day, "");
                        string[] tmp = {}; 
                        if ("|" in hours) {
                            tmp = hours.split ("|");
                            restrict_info.weekday_hours = tmp[0];
                            restrict_info.weekend_hours = tmp[1];
                        } else {
                            tmp = hours.split ("-");
                            restrict_info.from = tmp[0];
                            restrict_info.to = tmp[1];
                        }

                        restrictions.append (restrict_info);
                    }
                }
            }

            return restrictions;
        }

        public static void try_add_restrict_line (string user_name, string restrict) {
            if (Utils.get_permission ().allowed) {            
                Utils.call_cli ({"--user", user_name, "--restrict-pam-line", restrict});
            }
        }

        public static void try_remove_user_restrict (string user_name) {
            if (Utils.get_permission ().allowed) {            
                Utils.call_cli ({"--user", user_name, "--remove-restrict"});
            }            
        }
    }
}
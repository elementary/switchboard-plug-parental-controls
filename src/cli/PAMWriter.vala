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

namespace PC.Cli {
    public class PAMWriter : Object {
        private const string TIME_CONF_PATH = "/etc/security/time.conf";
        private const int REGEX_MATCH_INDEX = 1;

        private string filename;

        public static PAMWriter new_for_time () {
            return new PAMWriter (TIME_CONF_PATH);
        }

        public PAMWriter (string filename) {
            this.filename = filename;
        }    

        public string get_conf_section (bool ignore_comments = true) {
            string config_section = "";

            string contents;
            FileUtils.get_contents (filename, out contents);

            int start_idx = contents.index_of (Vars.PAM_CONF_START);
            int end_idx = contents.index_of (Vars.PAM_CONF_END);
            if (start_idx == -1 || end_idx == -1) {
                return config_section;
            }

            config_section = contents.slice (start_idx, end_idx);

            if (ignore_comments) {
                string tmp_buffer = "";
                foreach (string line in config_section.split ("\n")) {
                    if (!line.strip ().has_prefix ("#")) {
                        tmp_buffer += line;
                    }
                }

                return tmp_buffer;
            }

            return config_section;
        }

        public void remove_conf_section () {
            string contents = read_contents ();
            string final_contents = contents.replace (filename, "");

            try {
                FileUtils.set_contents (filename, final_contents);
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }
        }

        public void remove_user_restrictions (string user) {
            string contents = read_contents ();
            string conf_section = get_conf_section ();

            string new_conf = "";
            if (conf_section != "" && user != "") {
                int i = 0;
                string[] split = conf_section.split ("\n");
                foreach (string section_line in split) {
                    bool contains = (user in section_line);
                    if (!contains) {
                        if (i > 0) {
                            new_conf += "\n";
                        }

                        new_conf += section_line;
                    }

                    i++;
                }

                try {
                    FileUtils.set_contents (filename, contents.replace (conf_section, new_conf));
                } catch (FileError e) {
                    warning ("%s\n", e.message);
                }
            }            
        } 

        public void modify_user_restrictions (string user, bool enable) {
            string contents = read_contents ();
            string conf_section = get_conf_section ();

            string new_conf = "";
            if (conf_section != "" && user != "") {
                int i = 0;
                string[] split = conf_section.split ("\n");
                foreach (string section_line in split) {
                    if (i > 0) {
                        new_conf += "\n";
                    }

                    bool contains = (user in section_line);
                    if (!contains) {
                        new_conf += section_line;
                    } else {
                        string prefix = "#";
                        if (enable) {
                            prefix = "";
                            section_line = section_line.replace ("#", "");
                        }

                        new_conf += prefix + section_line;
                    }

                    i++;
                }

                try {
                    FileUtils.set_contents (filename, contents.replace (conf_section, new_conf));
                } catch (FileError e) {
                    warning ("%s\n", e.message);
                }
            }            
        } 

        public void add_conf_line (string line, string? user = null) {
            string contents = read_contents ();
            string conf_section = get_conf_section ();

            string new_conf = "";
            if (conf_section != "" && user != null) {
                int i = 0;
                string[] split = conf_section.split ("\n");
                foreach (string section_line in split) {
                    bool contains = (user in section_line);
                    if (!contains) {
                        if (i > 0) {
                            new_conf += "\n";
                        }

                        new_conf += section_line;
                    }

                    i++;
                }

                try {
                    FileUtils.set_contents (filename, contents.replace (conf_section, new_conf));
                } catch (FileError e) {
                    warning ("%s\n", e.message);
                }

                contents = read_contents ();
                conf_section = get_conf_section ();
            }

            
            string final_contents = "";

            if (conf_section == "") {
                final_contents = contents +
                                    "\n" +
                                    Vars.PAM_CONF_START +
                                    "\n" +
                                    line +
                                    "\n" +
                                    Vars.PAM_CONF_END;
            } else {
                final_contents = conf_section.replace (Vars.PAM_CONF_END, "");
                final_contents += line + "\n" + Vars.PAM_CONF_END;
                final_contents = contents.replace (conf_section, final_contents);
            }

            try {
                FileUtils.set_contents (filename, final_contents);
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }
        }  

        private string read_contents () {
            string data = "";
            if (!FileUtils.test (filename, FileTest.EXISTS)) {
                return "";
            }

            try {
                FileUtils.get_contents (filename, out data);
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }

            return data;
        }
    }
}
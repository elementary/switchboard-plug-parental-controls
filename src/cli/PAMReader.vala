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

namespace Cli {
    public class PAMReader : FileReader {
        public File file;
        private const string CONF_START = "## PANTHEON_PARENTAL_CONTROL_START";
        private const string CONF_END = "## PANTHEON_PARENTAL_CONTROL_END";
        private const string CONF_REGEX = CONF_START + "|" + CONF_END;

        public PAMReader (File file) {
            this.file = file;
        }    

        public string get_conf_section () {
            string contents = this.read_contents (file);
            try {
                var regex = new Regex (CONF_REGEX);

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

        public void remove_conf_section () {
            string contents = this.read_contents (file);
            string final_contents = contents.replace (get_conf_section (), "");

            try {
                FileUtils.set_contents (file.get_path (), final_contents);
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }
        }

        public void add_conf_line (string line, string? user = null) {
            string contents = this.read_contents (file);
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
                    FileUtils.set_contents (file.get_path (), contents.replace (conf_section, new_conf));
                } catch (FileError e) {

                }

                contents = this.read_contents (file);
                conf_section = get_conf_section ();
            }

            
            string final_contents = "";

            if (conf_section == "") {
                final_contents = contents +
                                    "\n" +
                                    CONF_START +
                                    "\n" +
                                    line +
                                    "\n" +
                                    CONF_END;
            } else {
                final_contents = conf_section.replace (CONF_END, "");
                final_contents += line + "\n" + CONF_END;
                final_contents = contents.replace (conf_section, final_contents);
            }

            try {
                FileUtils.set_contents (file.get_path (), final_contents);
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }
        }  

        public override ReaderType get_reader_type () {
            return ReaderType.PAM;
        }
    }
}
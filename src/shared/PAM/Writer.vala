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
    public class Writer : Object {
        public const string TIME_CONF_PATH = "/etc/security/time.conf";
        private const int REGEX_MATCH_INDEX = 1;

        private string filename;

        public static Writer new_for_time () {
            return new Writer (TIME_CONF_PATH);
        }

        public Writer (string filename) {
            this.filename = filename;
        }

        public void add_restriction_for_user (string input) {
            string contents = Utils.read_contents (filename);
            string config = Reader.get_config (contents, false);

            var token = Token.parse_line (input);
            if (token != null) {
                string username = token.get_user_arg0 ();
                if (Reader.get_token_for_user (filename, username) != null) {
                    remove_restriction_for_user (username);
                }
            }

            var builder = new StringBuilder (Vars.PAM_CONF_START);
            if (config != "") {
                builder.append ("\n");
                builder.append (Utils.remove_comments (config)); 
            } else {
                builder.append ("\n");
            }

            builder.append (input);
            builder.append ("\n");
            builder.append (Vars.PAM_CONF_END);

            try {
                if (config != "") {
                    FileUtils.set_contents (filename, contents.replace (config, builder.str));
                } else {
                    FileUtils.set_contents (filename, "\n%s\n%s\n".printf (contents, builder.str));
                }
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }
        }

        public void remove_restriction_for_user (string username) {
            string contents = Utils.read_contents (filename);
            string config = Reader.get_config (contents);

            if (config == "") {
                return;
            }

            string buffer = "";

            foreach (string line in config.split ("\n")) {
                var token = Token.parse_line (line);
                if (token != null && token.get_user_arg0 () != username) {
                    buffer += line;
                }
            }

            buffer += "\n";

            try {
                FileUtils.set_contents (filename, contents.replace (config, buffer));
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }
        }        
    }
}
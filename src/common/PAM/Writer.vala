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
    public class Writer : Object {
        private string filename;

        public static Writer new_for_time () {
            return new Writer (Constants.PAM_TIME_CONF_PATH);
        }

        public Writer (string filename) {
            this.filename = filename;
        }

        public void add_restriction_for_user (string input, bool clean) {
            string? clean_username = null;
            if (clean) {
                var token = Token.parse_line (input);
                if (token != null) {
                    clean_username = token.get_user_arg0 ();
                }
            }

            string contents;
            try {
                FileUtils.get_contents (filename, out contents);
            } catch (FileError e) {
                warning (e.message);
                return;
            }

            int start_idx;
            int end_idx;
            string config = Reader.get_config (contents, out start_idx, out end_idx);

            if (start_idx != -1 && end_idx != -1) {
                contents = contents.splice (start_idx - 1, end_idx);
            }

            var builder = new StringBuilder (Constants.PAM_CONF_START);
            builder.append ("\n");

            foreach (var token in Token.parse (config)) {
                if (token.get_user_arg0 () == clean_username) {
                    continue;
                }

                builder.append (token.to_string ());
                builder.append ("\n");
            }

            builder.append (input);
            builder.append ("\n");
            builder.append (Constants.PAM_CONF_END);

            try {
                FileUtils.set_contents (filename, "%s\n%s".printf (contents, builder.str));
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }
        }

        public void remove_restriction_for_user (string username) {
            string contents;
            try {
                FileUtils.get_contents (filename, out contents);
            } catch (FileError e) {
                warning (e.message);
                return;
            }

            int start_idx;
            int end_idx;
            string config = Reader.get_config (contents, out start_idx, out end_idx);

            if (start_idx != -1 && end_idx != -1) {
                contents = contents.splice (start_idx - 1, end_idx);
            } else {
                return;
            }

            var builder = new StringBuilder (Constants.PAM_CONF_START);
            builder.append ("\n");

            foreach (var token in Token.parse (config)) {
                if (token.get_user_arg0 () == username) {
                    continue;
                }

                builder.append (token.to_string ());
                builder.append ("\n");
            }

            builder.append (Constants.PAM_CONF_END);

            try {
                FileUtils.set_contents (filename, "%s\n%s".printf (contents, builder.str));
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }
        }
    }
}

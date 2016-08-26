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
    public class Reader : Object {
        public static string get_config (string contents, bool ignore_comments = true) {
            string config = "";

            int start_idx = contents.index_of (Vars.PAM_CONF_START);
            int end_idx = contents.index_of (Vars.PAM_CONF_END) + Vars.PAM_CONF_END.char_count ();
            if (start_idx == -1 || end_idx == -1) {
                return config;
            }

            config = contents.slice (start_idx, end_idx);

            if (ignore_comments) {
                return Utils.remove_comments (config);
            }

            return config;
        }

        public static List<Token> get_tokens (string filename) {
            string contents = Utils.read_contents (filename);
            string config = get_config (contents);
            return Token.parse (config);
        }

        public static Token? get_token_for_user (string filename, string username) {
            foreach (Token token in get_tokens (filename)) {
                if (token.get_user_arg0 () == username) {
                    return token;
                }
            }

            return null;
        }
    }
}
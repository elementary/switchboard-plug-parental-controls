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
    public enum ReaderType {
        PAM = 0,
        HOSTS
    }

    public abstract class FileReader : Object {
        public virtual string read_contents (File file) {
            string data = "";
            if (!file.query_exists ()) {
                return "";
            }

            try {
                FileUtils.get_contents (file.get_path (), out data);
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }

            return data;
        }

        public abstract ReaderType get_reader_type ();
    }
}
/*-
 * Copyright (c) 2016 elementary LLC (https://elementary.io)
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
 * Authored by: Felipe Escoto <felescoto95@hotmail.com>
 */

public abstract class PC.Daemon.Restriction <R> : Object {
    public List<R> restrictions;

    construct {
        restrictions = new List<R>();
    }

    public abstract string serialize ();
    public abstract void parse_line (string line);
   
    public void add_restriction (R item) {
        if (restrictions.index (item) == -1) {
            restrictions.append (item);
        }
    }

    public void remove_restriction (R item) {
        if (restrictions.index (item) != -1) {
            restrictions.remove (item);
        }
    }
}

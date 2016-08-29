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
namespace PC.Daemon {
    public struct SessionStruct {
        string name;
        uint32 uid;
        string user;
        string seat;
        GLib.ObjectPath object_path;
    }

    public struct SeatStruct {
        string seat_id;
        GLib.ObjectPath object_path;
    }

    [DBus (name = "org.freedesktop.login1.Manager")]
    public interface IManager : Object {
        public abstract SessionStruct[] list_sessions () throws IOError;
        public abstract SeatStruct[] list_seats () throws IOError;
        public abstract GLib.ObjectPath get_seat (string seat) throws IOError;
        public signal void session_new (string session, GLib.ObjectPath object_path);
        public signal void session_removed (string session, GLib.ObjectPath object_path);
    }

    [DBus (name = "org.freedesktop.login1.Session")]
    public interface ISession : Object {
        public abstract bool active { owned get; }
        public abstract string name { owned get; }
        public abstract void terminate () throws IOError;
    }
}
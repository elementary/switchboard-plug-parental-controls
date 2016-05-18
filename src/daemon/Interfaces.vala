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

public struct SessionStruct {
    string name;
    uint32 uid;
    string user;
    string seat;
    GLib.ObjectPath object_path;
}

public struct UserStruct {
    uint32 uid;
    string name;
    GLib.ObjectPath object_path;
}

public struct ActiveSessionStruct {
    string session_id;
    GLib.ObjectPath object_path;
}

[DBus (name = "org.freedesktop.login1.Manager")]
public interface IManager : Object {
    public abstract UserStruct[] list_users () throws IOError;
    public abstract SessionStruct[] list_sessions () throws IOError;
    public abstract GLib.ObjectPath get_seat (string seat) throws IOError;
    public signal void session_new (string user, GLib.ObjectPath object_path);
    public signal void session_removed (string user, GLib.ObjectPath object_path);
}

[DBus (name = "org.freedesktop.login1.Session")]
public interface ISession : Object {
    public abstract bool active { owned get; }
    public abstract string display { owned get; }
    public abstract string name { owned get; }

    public abstract void lock () throws IOError;

    public signal void unlock ();
}

[DBus (name = "org.freedesktop.login1.Seat")]
public interface ISeat : Object {
    public abstract ActiveSessionStruct active_session { owned get; }
}
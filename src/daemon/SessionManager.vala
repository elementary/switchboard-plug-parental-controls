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
    public class SessionManager : Object {
        public SessionHandler? current_handler = null;
        
        private Manager? manager = null;

        public SessionManager () {
            try {
                manager = Bus.get_proxy_sync (BusType.SYSTEM, Vars.LOGIN_IFACE, Vars.LOGIN_OBJECT_PATH); 
            } catch (IOError e) {
                warning ("%s\n", e.message);
            }
        }

        public void start () {
            manager.session_new.connect (() => {
                update_session ();
            });

            update_session ();
        }

        private Session? get_current_session () {
            try {
                foreach (var struct_session in manager.list_sessions ()) {
                    Session session = Bus.get_proxy_sync (BusType.SYSTEM, Vars.LOGIN_IFACE, struct_session.object_path);
                    if (session.active) {
                        return session;
                    }
                } 
            } catch (IOError e) {
                warning ("%s\n", e.message);
            }
            
            return null;         
        }

        private void update_session () {
            if (current_handler != null) {
                current_handler.stop ();
                current_handler = null;
            }

            var current_session = get_current_session ();
            current_session.unlock.connect (update_session);
            current_handler = new SessionHandler (current_session);
            current_handler.start ();
        }
    }
 }
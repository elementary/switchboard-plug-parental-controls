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

namespace PC.Widgets {
    public class ControlPage : Gtk.Box {
        public Act.User user;

        public ControlPage (Act.User user) {
            this.user = user;

            margin = 24;
            spacing = margin;
            hexpand = true;
            orientation = Gtk.Orientation.VERTICAL;

            var general = new GeneralBox (user);
            general.expand = true;

            var stack = new Gtk.Stack ();
            stack.add_titled (general, "general", _("General"));
            stack.add_titled (new InternetBox (), "internet", _("Internet"));
            stack.add_titled (new AppsBox (user), "apps", _("Applications"));

            var switcher = new Gtk.StackSwitcher ();
            switcher.halign = Gtk.Align.CENTER;
            switcher.stack = stack;
            add (switcher);
            add (stack);

            Utils.get_permission ().notify["allowed"].connect (update);
            update ();
            show_all ();
        }

        private void update () {
            sensitive = Utils.get_permission ().allowed;
        }
    }
}
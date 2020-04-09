/*-
 * Copyright 2019-2020 elementary, Inc (htts://elementary.io)
 *           2015 Adam Bieńkowski
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

public class PC.Client.AppUnavailableDialog : Granite.MessageDialog {
    public AppUnavailableDialog () {
        Object (
            image_icon: new ThemedIcon ("preferences-system-parental-controls"),
            primary_text: _("You are not permitted to run this application"),
            secondary_text: _("An administrator has restricted your access to this application."),
            buttons: Gtk.ButtonsType.CLOSE
        );
    }

    construct {
        response.connect (() => {
            destroy ();
        });
    }
}

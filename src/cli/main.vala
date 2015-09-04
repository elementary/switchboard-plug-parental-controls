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
    public class App : Application {
        private const string PLANK_CONF_DIR = "/.config/plank/dock1/settings";
        private string conf_dir = "";

        public App () {
            Object (flags: ApplicationFlags.HANDLES_COMMAND_LINE);
        }
        public static int main (string[] args) {
            if (Environment.get_user_name () != "root") {
                stdout.printf ("Error: To run this program you need root privigiles\n\n");
                return 1;
            } 

            var app = new App ();
            return app.run (args);
        }

        private int _command_line (ApplicationCommandLine command_line) {
            string? user = null;
            string? home_dir = null;
            string? restrict_pam_line = null;
            string? lock_dock = null;

            var options = new OptionEntry[4];
            options[0] = { "user", 0, 0, OptionArg.STRING, ref user, "Use username", null };
            options[1] = { "home-dir", 0, 0, OptionArg.FILENAME, ref home_dir, "Use specific home directory", null };
            options[2] = { "lock-dock", 0, 0, OptionArg.STRING, ref lock_dock, "Lock the given user dock", null };
            options[3] = { "restrict-pam-line", 0, 0, OptionArg.STRING, ref restrict_pam_line, "Add specified line to pam configuration", null };

            string[] args = command_line.get_arguments ();
            string*[] _args = new string[args.length];
            for (int i = 0; i < args.length; i++) {
                _args[i] = args[i];
            }

            try {
                var opt_context = new OptionContext ("context");
                opt_context.set_help_enabled (false);
                opt_context.add_main_entries (options, null);
                unowned string[] tmp = _args;
                opt_context.parse (ref tmp);
            } catch (OptionError e) {
                command_line.print ("error: %s\n", e.message);
                command_line.print ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
                return 1;
            }   

            if (restrict_pam_line != null && user != null) {
                ensure_pam_lightdm_enabled ();

                var pam_reader = new PAMWriter (File.new_for_path ("/etc/security/time.conf"));
                pam_reader.add_conf_line (restrict_pam_line, user);
            }

            if (home_dir != null && lock_dock != null) {
               lock_dock_for_user (home_dir, bool.parse (lock_dock.to_string ()));
            }

            return 0;
        }

        private void ensure_pam_lightdm_enabled () {
            string path = "/etc/pam.d/lightdm";
            string contents = "";
            try {
                FileUtils.get_contents (path, out contents);
            } catch (FileError e) {
                warning ("%s\n", e.message);
            }                
            
            string conf_line = "\naccount required pam_time.so";
            if (!(conf_line in contents)) {
                contents += conf_line;

                try {
                    FileUtils.set_contents (path, contents);
                } catch (FileError e) {
                    warning ("%s\n", e.message);
                }
            }
        }

        private void lock_dock_for_user (string home_dir, bool lock) {
            conf_dir = home_dir + PLANK_CONF_DIR;
            if (conf_dir != "" && File.new_for_path (conf_dir).query_exists ()) {
                var key_file = new KeyFile ();
                var flags = KeyFileFlags.KEEP_COMMENTS|KeyFileFlags.KEEP_TRANSLATIONS;
                try {
                    key_file.load_from_file (conf_dir, flags);
                } catch (FileError e) {
                    warning ("%s\n", e.message);
                }  
                              
                key_file.set_boolean ("PlankDockPreferences", "LockItems", lock);

                try {
                    key_file.save_to_file (conf_dir);
                } catch (FileError e) {
                    warning ("%s\n", e.message);
                }       
            }
        }

        public override void activate () {

        }

        public override int command_line (ApplicationCommandLine command_line) {
            this.hold ();
            int res = _command_line (command_line);
            this.release ();
            return res;
        }
    }
}
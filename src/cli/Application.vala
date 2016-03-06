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

namespace PC.Cli {
    public class App : Application {
        private const string TIME_CONF_FILE = "/etc/security/time.conf";
        private string plank_conf_file_path = "";

        public App () {
            Object (flags: ApplicationFlags.HANDLES_COMMAND_LINE);
        }
        
        public static int main (string[] args) {
            var app = new App ();
            return app.run (args);
        }

        private int _command_line (ApplicationCommandLine command_line) {
            string? user = null;
            string? restrict_pam_line = null;
            string? lock_dock = null;
            string? set_contents = null;
            string? file = null;

            bool remove_restrict = false;
            bool enable_restrict = false;
            bool disable_restrict = false;

            var options = new OptionEntry[9];
            options[0] = { "user", 0, 0, OptionArg.STRING, ref user, "Use specific user", null };
            options[1] = { "lock-dock", 0, 0, OptionArg.STRING, ref lock_dock, "Lock the given user dock", null };
            options[2] = { "restrict-pam-line", 0, 0, OptionArg.STRING, ref restrict_pam_line, "Add specified line to pam configuration", null };
            options[3] = { "remove-restrict", 0, 0, OptionArg.NONE, ref remove_restrict, "Remove all time restrictions for specified user", null };
            options[4] = { "set-contents", 0, 0, OptionArg.STRING, ref set_contents, "Set contents of specified filename", null };
            options[5] = { "file", 0, 0, OptionArg.FILENAME, ref file, "A file to write contents to", null };
            options[6] = { "enable-restrict", 0, 0, OptionArg.NONE, ref enable_restrict, "Enable PAM restrictions for the user", null };
            options[7] = { "disable-restrict", 0, 0, OptionArg.NONE, ref disable_restrict, "Disable PAM restrictions for the user", null };

            string[] args = command_line.get_arguments ();
            string*[] _args = new string[args.length];
            for (int i = 0; i < args.length; i++) {
                _args[i] = args[i];
            }

            print ("called it\n");

            try {
                var opt_context = new OptionContext ("context");
                opt_context.set_help_enabled (true);
                opt_context.add_main_entries (options, null);
                unowned string[] tmp = _args;
                opt_context.parse (ref tmp);
            } catch (OptionError e) {
                command_line.print ("error: %s\n", e.message);
                command_line.print ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
                return 1;
            }   

            if (Posix.getuid () != 0) {
                command_line.print ("Error: To run this program you need root privigiles\n\n");
                Process.exit (1);
            } 

            if (remove_restrict && user != "") {
            	var pam_writer = new PAMWriter (File.new_for_path (TIME_CONF_FILE));
            	pam_writer.remove_user_restrictions (user);
            }

            if (enable_restrict && user != "") {
                var pam_writer = new PAMWriter (File.new_for_path (TIME_CONF_FILE));
                pam_writer.modify_user_restrictions (user, true);
            }

            if (disable_restrict && user != "") {
                var pam_writer = new PAMWriter (File.new_for_path (TIME_CONF_FILE));
                pam_writer.modify_user_restrictions (user, false);
            }

            if (restrict_pam_line != null && user != null) {
                ensure_pam_lightdm_enabled ();

                var pam_writer = new PAMWriter (File.new_for_path (TIME_CONF_FILE));
                pam_writer.add_conf_line (restrict_pam_line, user);
            }

            if (user != null && lock_dock != null) {
                var loop = new MainLoop ();

                Utils.get_usermanager ().notify["is-loaded"].connect (() => {
                    if (Utils.get_usermanager ().is_loaded) {
                        lock_dock_for_user (user, bool.parse (lock_dock));
                        loop.quit ();
                    }
                });

                loop.run ();
            }

            if (set_contents != null && file != null) {
                set_file_contents (file, set_contents);
            }

            return 0;
        }

        private void set_file_contents (string path, string contents) {
            var file = File.new_for_path (path);
            if (!file.query_exists ()) {
                try {
                    var os = file.create (FileCreateFlags.REPLACE_DESTINATION);
                    os.write (contents.data);
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            } else {
                try {
                    FileUtils.set_contents (path, contents);
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            }
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

        private void lock_dock_for_user (string user, bool lock) {
            plank_conf_file_path = Path.build_filename (Utils.get_usermanager ().get_user (user).get_home_dir (), Vars.PLANK_CONF_DIR);
            if (plank_conf_file_path != "" && File.new_for_path (plank_conf_file_path).query_exists ()) {
                var key_file = new KeyFile ();
                try {
                    key_file.load_from_file (plank_conf_file_path, KeyFileFlags.KEEP_COMMENTS | KeyFileFlags.KEEP_TRANSLATIONS);
                } catch (KeyFileError e) {
                    warning ("%s\n", e.message);
                } catch (FileError e) {
                    warning ("%s\n", e.message);
                }  
                
                print ("setting boolean: %s\n", lock.to_string ());                              
                key_file.set_boolean ("PlankDockPreferences", "LockItems", lock);

                try {
                    key_file.save_to_file (plank_conf_file_path);
                } catch (FileError e) {
                    warning ("%s\n", e.message);
                }       
            }
        }

        public override int command_line (ApplicationCommandLine command_line) {
            this.hold ();
            int res = _command_line (command_line);
            this.release ();
            return res;
        }
    }
}
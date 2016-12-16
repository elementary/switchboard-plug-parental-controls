[CCode (cheader_filename = "exec-monitor.h", type_id = "exec_monitor_get_type ()")]
public interface ExecMonitor : GLib.Object {
    public virtual async void start_monitor ();
    public virtual void stop_monitor ();
    public abstract void handle_pid (int pid);
}
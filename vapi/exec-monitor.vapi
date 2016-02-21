[CCode (cheader_filename = "exec-monitor.h", type_id = "exec_monitor_get_type ()")]
public interface ExecMonitor : GLib.Object {
    public virtual async void start ();
    public virtual void stop ();
    public abstract void handle_pid (int pid);
}
#ifndef EXEC_MONITOR_H
#define EXEC_MONITOR_H

#include <glib-object.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <gio/gio.h>

#include <linux/connector.h>
#include <linux/netlink.h>
#include <linux/cn_proc.h>

#define SEND_MESSAGE_LEN (NLMSG_LENGTH (sizeof (struct cn_msg) + \
                       sizeof (enum proc_cn_mcast_op)))
#define RECV_MESSAGE_LEN (NLMSG_LENGTH (sizeof (struct cn_msg) + \
                       sizeof (struct proc_event)))

#define SEND_MESSAGE_SIZE (NLMSG_SPACE(SEND_MESSAGE_LEN))
#define RECV_MESSAGE_SIZE (NLMSG_SPACE(RECV_MESSAGE_LEN))

#define max(x,y) ((y)<(x)?(x):(y))
#define min(x,y) ((y)>(x)?(x):(y))

#define BUFF_SIZE (max(max(SEND_MESSAGE_SIZE, RECV_MESSAGE_SIZE), 1024))
#define MIN_RECV_SIZE (min(SEND_MESSAGE_SIZE, RECV_MESSAGE_SIZE))

#define PROC_CN_MCAST_LISTEN (1)
#define PROC_CN_MCAST_IGNORE (2)

G_BEGIN_DECLS

#define EXEC_MONITOR_TYPE (exec_monitor_get_type ())
#define EXEC_MONITOR(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), EXEC_MONITOR_TYPE, ExecMonitor))
#define EXEC_MONITOR_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), EXEC_MONITOR_TYPE, ExecMonitorIface))
#define IS_EXEC_MONITOR(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), EXEC_MONITOR_TYPE))
#define EXEC_MONITOR_GET_IFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), EXEC_MONITOR_TYPE, ExecMonitorIface))

typedef struct _ExecMonitor       ExecMonitor;
typedef struct _ExecMonitorIface  ExecMonitorIface;

struct _ExecMonitorIface
{
  GTypeInterface parent_iface;
  gboolean monitor_events;
  int sk_nl;

  void (* handle_pid)   (ExecMonitor *exec_monitor,
                        gint pid);
};

GType           exec_monitor_get_type       (void);
void            exec_monitor_start          (ExecMonitor *exec_monitor, GAsyncReadyCallback callback, gpointer user_data);
void            exec_monitor_start_internal (ExecMonitor *exec_monitor);
static void     start_task_thread           (GTask *task, gpointer task_data, GCancellable *cancellable);
void            exec_monitor_stop           (ExecMonitor *exec_monitor);

G_END_DECLS

#endif /* EXEC_MONITOR_H */
/*
 * Copyright/Licensing information.
 */

#ifndef EXEC_MONITOR_H
#define EXEC_MONITOR_H

#include <glib-object.h>
#include <sys/socket.h>
#include <sys/types.h>

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
#define EXEC_MONITOR_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), EXEC_MONITOR_TYPE, ExecMonitorClass))
#define IS_EXEC_MONITOR(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), EXEC_MONITOR_TYPE))
#define IS_EXEC_MONITOR_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), EXEC_MONITOR_TYPE))
#define EXEC_MONITOR_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), EXEC_MONITOR_TYPE, ExecMonitorClass))

typedef struct ExecMonitor
{
  GObject parent_instance;
  gboolean monitor_started;
  gboolean monitor_events;
} ExecMonitor;

typedef struct
{
  GObjectClass parent_class;

  void (* pid_exec)(ExecMonitor *exec_monitor, gint pid);
} ExecMonitorClass;

GType                   exec_monitor_get_type     (void);
ExecMonitor            *exec_monitor_new          (void);
void 					exec_monitor_start        (ExecMonitor *exec_monitor);

G_END_DECLS

#endif /* EXEC_MONITOR_H */
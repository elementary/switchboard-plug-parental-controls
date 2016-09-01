/*
 * (C) 2007-2010 Sebastian Krahmer <krahmer@suse.de> original netlink handling
 * stolen from an proc-connector example, copyright folows:
 *
 * Copyright (C) Matt Helsley, IBM Corp. 2005
 * Derived from fcctl.c by Guillaume Thouvenin
 * Original copyright notice follows:
 *
 * Copyright (C) 2005 BULL SA.
 * Written by Guillaume Thouvenin <guillaume.thouvenin@bull.net> and Adam Bieńkowski <donadigos159@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <glib.h>
#include <gio/gio.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include "exec-monitor.h"

typedef ExecMonitorIface ExecMonitorInterface;
G_DEFINE_INTERFACE(ExecMonitor, exec_monitor, G_TYPE_OBJECT);

void
exec_monitor_handle_msg (ExecMonitor  *self,
                        struct cn_msg *cn_hdr)
{
    g_return_if_fail (IS_EXEC_MONITOR (self));

    struct proc_event *ev = (struct proc_event *)cn_hdr->data;

    gint _pid;
    switch (ev->what){
        case PROC_EVENT_EXEC:
            _pid = ev->event_data.exec.process_pid;
            EXEC_MONITOR_GET_IFACE (self)->handle_pid (self, _pid);
            break;
        case PROC_EVENT_FORK:            
        case PROC_EVENT_EXIT:
        case PROC_EVENT_UID:
            break;
        default:
            break;
    }
}

void
exec_monitor_handle_pid (ExecMonitor *self,
                        gint pid)
{
}

static void
exec_monitor_default_init (ExecMonitorInterface *exec_monitor)
{
    exec_monitor->monitor_events = FALSE;
}

void
exec_monitor_start (ExecMonitor         *self,
                    GAsyncReadyCallback callback,
                    gpointer            user_data)
{
    ExecMonitorInterface *iface;
    GTask *task;

    g_return_if_fail (IS_EXEC_MONITOR (self));

    iface = EXEC_MONITOR_GET_IFACE (self);

    g_return_if_fail (!iface->monitor_events);
    
    task = g_task_new (self, NULL, callback, user_data);
    g_task_run_in_thread (task, start_task_thread);
    g_object_unref (task);
}

static void
start_task_thread (GTask     *task,
                gpointer     task_data,
                GCancellable *cancellable)
{
    ExecMonitor* self = EXEC_MONITOR (task_data);
    exec_monitor_start_internal (self);
}

void
exec_monitor_stop (ExecMonitor *self)
{
    ExecMonitorInterface *iface;

    g_return_if_fail (IS_EXEC_MONITOR (self));    

    iface = EXEC_MONITOR_GET_IFACE (self);
    iface->monitor_events = FALSE;
    close (iface->sk_nl);
}

void
exec_monitor_start_internal (ExecMonitor *self)
{
    int err;
    struct sockaddr_nl my_nla, kern_nla, from_nla;
    socklen_t from_nla_len;
    char buff[BUFF_SIZE];
    int rc = -1;
    struct nlmsghdr *nl_hdr;
    struct cn_msg *cn_hdr;
    enum proc_cn_mcast_op *mcop_msg;
    size_t recv_len = 0;

    g_return_if_fail (IS_EXEC_MONITOR (self));
    g_return_if_fail (getuid () == 0);

    ExecMonitorInterface *iface;
    iface = EXEC_MONITOR_GET_IFACE (self);

    iface->sk_nl = socket (PF_NETLINK, SOCK_DGRAM, NETLINK_CONNECTOR);
    if (iface->sk_nl == -1) {
        return;
    }

    my_nla.nl_family = AF_NETLINK;
    my_nla.nl_groups = CN_IDX_PROC;
    my_nla.nl_pid = getpid ();

    kern_nla.nl_family = AF_NETLINK;
    kern_nla.nl_groups = CN_IDX_PROC;
    kern_nla.nl_pid = 1;

    err = bind (iface->sk_nl, (struct sockaddr *)&my_nla, sizeof (my_nla));
    if (err == -1) {
        return;
    }

    nl_hdr = (struct nlmsghdr *)buff;
    cn_hdr = (struct cn_msg *)NLMSG_DATA(nl_hdr);
    mcop_msg = (enum proc_cn_mcast_op*)&cn_hdr->data[0];

    memset (buff, 0, sizeof(buff));
    *mcop_msg = PROC_CN_MCAST_LISTEN;

    nl_hdr->nlmsg_len = SEND_MESSAGE_LEN;
    nl_hdr->nlmsg_type = NLMSG_DONE;
    nl_hdr->nlmsg_flags = 0;
    nl_hdr->nlmsg_seq = 0;
    nl_hdr->nlmsg_pid = getpid ();

    cn_hdr->id.idx = CN_IDX_PROC;
    cn_hdr->id.val = CN_VAL_PROC;
    cn_hdr->seq = 0;
    cn_hdr->ack = 0;
    cn_hdr->len = sizeof (enum proc_cn_mcast_op);

    if (send (iface->sk_nl, nl_hdr, nl_hdr->nlmsg_len, 0) != nl_hdr->nlmsg_len) {
        return;
    }

    if (*mcop_msg == PROC_CN_MCAST_IGNORE) {
        return;
    }

    iface->monitor_events = TRUE;
    while (iface->monitor_events) {
        struct nlmsghdr *nlh = (struct nlmsghdr*)buff;
        memcpy (&from_nla, &kern_nla, sizeof (from_nla));

        recv_len = recvfrom (iface->sk_nl, buff, BUFF_SIZE, 0,
                (struct sockaddr*)&from_nla, &from_nla_len);
        if (from_nla.nl_pid != 0) {
            continue;
        }

        if (recv_len < 1) {
            continue;
        }

        while (NLMSG_OK (nlh, recv_len)) {
            cn_hdr = NLMSG_DATA (nlh);
            if (nlh->nlmsg_type == NLMSG_NOOP) {
                continue;
            }

            if ((nlh->nlmsg_type == NLMSG_ERROR) ||
                (nlh->nlmsg_type == NLMSG_OVERRUN)) {
                break;
            }

            exec_monitor_handle_msg (self, cn_hdr);
            if (nlh->nlmsg_type == NLMSG_DONE) {
                break;
            }

            nlh = NLMSG_NEXT (nlh, recv_len);
        }
    }
}
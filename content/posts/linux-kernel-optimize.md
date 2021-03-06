---
title: "Linux 内核参数优化"
date: 2019-09-30T13:50:42+08:00
keywords: ["linux", "kernel", "linux内核参数优化"]
categories: ["linux", "nginx"]
tags: ["linux", "kernel", "linux内核参数优化"]
draft: false
related:
  threshold: 80
  includeNewer: false
  toLower: false
  indices:
  - name: keywords
    weight: 100
  - name: tags
    weight: 90
  - name: categories
    weight: 50
  - name: date
    weight: 10
---

由于默认的linux内核参数考虑的是最通用的场景，这种场景下并不适合高并发访问的web服务器的定义，所以需要修改如下参数，
使得nginx可以拥有更高的性能。

根据不同的业务特点，nginx作为静态web内容服务器、反向代理服务器或者提供图片缩略图功能（实时亚索图片）的服务器时，
其内核参数调整是不同的。

这里只针对最通用，使nginx支持更多并发请求的tcp网络参数做简单说明。

需要修改/etc/sysctl.conf来更改内核参数。
```bash
fs.file-max = 999999
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.ip_local_port_range = 1024 61000
net.ipv4.tcp_rmem = 4096 32768 262142
net.ipv4.tcp_wmem = 4096 32768 262142
net.core.netdev_max_backlog = 8096
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.rmem_max = 2097152
net.wmem_max = 2097152
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn.backlog = 1024

```
参数说明

- file-max: 这个参数表示进程可以同时打开的最大句柄数，这个参数直接限制最大并发连接数，需要根据实际情况配置
- tcp_tw_reuse: 这个参数设置为1，表示允许将TIME_WAIT状态的socket重新用于新的tcp连接，这对于服务器来说很有意义，因为服务器上总会有大量TIME-WAIT状态的连接
- tcp_keepalive_time: 这个参数表示当keepalive启用时，tcp发送keepalive消息的频度。默认是2小时，若将其设置的小一些，可以更快地清理无效的连接
- tcp_fin_timeout: 这个参数表示当服务器主动关闭连接时，socket保持在FIN-WAIT-2状态的最大时间。
- tcp_max_tw_buckets: 这个参数表示操作系统允许TIME-WAIT套接字数量的最大值，如果超过这个数字，TIME-WAIT套接字将立刻被清除并打印警告信息。这个参数默认为180000，过多的TIME-WAIT套接字会使web服务器变慢。
- tcp_max_syn_backlog: 这个参数表示TCP三次握手建立阶段接收syn请求队列的最大长度，默认为1024，将其设置得大一些可以使出现nginx繁忙来不及accept新连接的情况时，linux不至于丢失客户端发起的连接请求。
- ip_local_port_range: 这个参数定义了在udp和tcp连接中本地（不包括连接的远端）端口的取值范围。
- net.ipv4.tcp_rmem: 这个参数定义了tcp接收缓存（用于tcp接收滑动窗口）的最小值、默认值、最大值
- net.ipv4.tcp_wmem: 这个参数定义了tcp发送缓存（用于tcp发送滑动窗口）的最小值、默认值、最大值
- netdev_max_backlog:当网卡接收数据包的速度大于内核处理的速度时，会有一个队列保存这些数据包。这个参数表示该队列的最大值。
- rmem_default: 这个参数表示内核套接字接收缓存区默认的大小
- wmem_default: 这个参数表示内核套接字发送缓存区的默认大小
- rmem_max: 这个参数表示内核套接字接收缓存区的最大大小
- wmem_max: 这个参数表示内核套接字发送缓冲区的最大大小
- tcp_syncookies: 该参数与性能无关，用于解决tcp的syn攻击





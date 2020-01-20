---
title: "linux系统资源设置 之 Ulimit 命令"
date: 2019-12-10T14:14:25+08:00
keywords: ["linux", "command line", "ulimit"]
categories: ["linux"]
tags: ["linux", "ulimit"]
series: [""]
draft: false
toc: false
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
根据linux 开发手册， ulimit 设置和获取用户的资源限制

**ulimit 参数说明**

| 选项 | 说明 |
| :------: | :------: |
| -t | 最大 cpu 占用时间 (单位是秒) |
| -f | 进程创建文件大小的最大值 (单位是blocks) |
| -d | 进程最大的数据段的大小，以kbytes为单位 |
| -s | 线程栈的大小，以kbytes为单位 |
| -c | 最大的core文件的大小，以blocks为单位 |
| -m | 最大内存大小，以kbytes为单位 |
| -u | 用户最大的可用的进程数 |
| -n | 可以打开的最大文件描述符数量 |
| -l | 最大可加锁内存大小，以kbytes为单位 |
| -v | 进程最大可用的虚拟内存，以kbytes为单位 |
| -x |  |
| -i |  |
| -q |  |
| -e |  |
| -r |  |
| -N |  |
| -p | 管道缓冲区的大小，以kbytes为单位 |
| -a | 显示所有资源限制的设定 |
| -S | 设定资源的弹性限制 |

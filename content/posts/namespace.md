---
title: "Namespace 资源隔离"
date: 2019-03-19T14:38:54+08:00
keywords: ["linux", "docker", "namespace"]
categories: ["linux", "docker"]
tags: ["docker", "linux", "namespace"]
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


- 资源隔离 - linux有个chroot命令，可以实现资源隔离
- 主机隔离
- 网络隔离
- 进程间通信隔离
- 用户和用户组权限隔离
- 进程PID隔离



### namespace 6项隔离

namespace | 系统调用参数 | 隔离内容
---|--- | ----
UTS | CLONE_NEWUTS | 主机名与域名
IPC | CLONE_NEWIPC | 信号量、消息队列和共享内存
PID | CLONE_NEWPID | 进程编号
Network | CLONE_NEWNET | 网络设备、网络栈、端口等
Mount | CLONE_NEWNS | 挂载点（文件系统）
User | CLONE_NEWUSER | 用户和用户组


> 同一namespace下的进程可以感知彼此的变化，而对外界的进程一无所知。此处的namespace是指Linux内核3.8及以后版本。


#### 1. namespace api 4种操作方式
namespace的api包括clone()、setns()以及unshare()，还有/proc下的部分文件，


##### 通过clone()在创建新进程的同时创建namespace
使用clone()来创建一个独立namespace的进程是常见方法，也是docker使用namespace最基本的方法：
```
int clone(int (*child_func)(void *), void *child_stack, int flags, void *arg);
```

##### 查看/proc/[pid]/ns文件
用户就可以在/proc/[pid]/ns文件下看到指向不同namespace号的文件，形如[4034532445]者即为namespace号。

```
[root@localhost ~]# ls -l /proc/$$/ns
total 0
lrwxrwxrwx. 1 root root 0 Nov 25 21:21 ipc -> ipc:[4026531839]
lrwxrwxrwx. 1 root root 0 Nov 25 21:21 mnt -> mnt:[4026531840]
lrwxrwxrwx. 1 root root 0 Nov 25 21:21 net -> net:[4026531956]
lrwxrwxrwx. 1 root root 0 Nov 25 21:21 pid -> pid:[4026531836]
lrwxrwxrwx. 1 root root 0 Nov 25 21:21 user -> user:[4026531837]
lrwxrwxrwx. 1 root root 0 Nov 25 21:21 uts -> uts:[4026531838]

```

> 上面的link文件一旦被打开，只要打开的文件描述符（fd）存在，那么就算该namespace下的所有进程都已经结束，这个namespace也会一直存在，后续进程也可以再加入进来。docker通过文件描述符定位和加入一个存在的namespace是最基本的方式。


##### 通过setns()加入一个已经存在的namespace
可以通过挂载的形式把namespace保留下来。在docker中，使用docker exec命令在已经运行着的容器中执行一个新的命令，就需要用到这个方法。通过setns()系统调用，进程从原先的namespace加入某个已经存在的namespace。
```
int setns(int fd, int nstype);
```

为了把新加入的namespace利用起来，需要引入execve()系列函数，该函数可以执行用户命令，最常用的就是调用/bin/bash并接受参数，运行起一个shell。

```
fd = open(argv[1], O_RDONLY);
setns(fd, 0);
execvp(argv[2], &argv[2]);
```

##### 通过unshare()在原先进程上进行namespace隔离
调用unshare就是不启动一个新进程就可以起到隔离的效果，相当于跳出原先的namespace进行操作。linux自带的unshare就是通过unshare系统调用实现。docker目前并没有这个系统调用。
```
int unshare(int flags);
```

#### UTS namespace
UTS(UNIX Time-sharing System) namespace提供了主机名和域名的隔离，这样每个docker就可以拥有独立的主机名和域名了。

> docker 每个镜像基本都以自身所提供的服务的名称来命名镜像的hostname，且不会对宿主机产生任何影响，其原理就是利用UTS namespace。



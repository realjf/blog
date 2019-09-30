---
title: "Nginx服务的基本配置"
date: 2019-09-30T14:56:20+08:00
draft: false
---

按照用户使用时的预期功能分成了4个功能

- 用于调试、定位问题的配置项
- 正常运行的必备配置项
- 优化性能的配置项
- 事件类配置项

### 用于调试进程和定位问题的配置项
#### 1. 是否以守护进程方式运行nginx

**语法： daemon on|off;**

**默认：daemon on;**

守护进程是脱离终端并且在后台运行的进程。它脱离终端是为了避免进程执行过程中的信息在任何终端中显示，这样一来，进程也不会被任何终端所产生的信息所打断。
因此，默认都是以这种方式运行的。

#### 2. 是否以master/worker方式运行
**语法： master_process on|off;**

**默认： master_process on;**

一个master进程管理多个worker进程的方式运行的，几乎所有的产品环境下，nginx都是以这种方式工作。

#### 3. error日志的配置
**语法：error_log /path/file level;**

**默认：error_log logs/error.log error;**

error日志是定位nginx问题的最佳工具，我们可以根据自己的需求妥善设置error日志的路径和级别。

/path/file参数可以是一个具体的文件，最好将它放到一个磁盘足够大的位置；
也可以是/dev/null，这样就不会输出任何日志了，这也是关闭error日志的唯一手段；
也可以是stderr，这样日志会输出到标准错误文件中。

level是日志的输出级别，取值范围是debug、info、notice、warn、error、crit、alert、emerg。
当设置一个级别，大于或等于该级别的日志都会被输出到/path/file文件中。小鱼该级别的日志则不会输出。

#### 4. 是否处理几个特殊的调试点
**语法：debug_points [stop|abort]**

这个配置项也是用来帮助用户跟踪调试nginx的。他接受两个参数：stop和abort。
nginx在一些关键的错误逻辑中设置了调试点。如果设置了debug_points为stop，那么nginx的代码执行到这些调试点时就会发出sigstop信号用以调试。
如果设置为abort，则会生成一个coredump文件，可以使用gdb来查看nginx当时的各种信息。

通常不会使用这个配置项。

#### 5. 仅对指定的客户端输出debug级别的日志
**语法：debug_connection [IP|CIDR]**

这个配置项实际上属于事件类配置，因此，他必须放在events{...}中才有效，他的值可以是ip地址或cidr地址，如：

```bash
events{
    debug_connection 10.224.66.14;
    debug_connection 10.224.57.0/24;
}
```
这样，仅仅来自以上ip地址的请求才会输出debug级别的日志，其他请求仍然沿用error_log中配置的日志级别。

这个配置对修复bug很有用，特别是定位高并发请求下才会发生的问题。

> 在debug_connection前，需要确保在执行configure时已经加入了--with-debug参数，否则不会生效。

#### 6. 限制coredump核心转储文件的大小
**语法：worker_rlimit_core size;**

在Linux系统中，当进程发生错误或收到信号而终止时，系统会将进程执行时的内存内容（核心映像）写入一个文件（core文件），以作为调试之用，这就是所谓的核心转储（coredumps）。
当nginx进程出现一些非法操作导致进程直接被操作系统强制结束时，会生成核心转储文件，可以从文件获取当时的堆栈、寄存器信息，从而帮助我们定位问题。但
这种文件中的许多信息不一定是用户需要的，如果不加以限制，那么可能一个coredump文件会达到几个gb，引发严重问题。通过worker_rlimit_core配置可以限制core文件的大小，
从而有效帮助用户定位问题。

#### 7. 指定coredump文件生成目录
**语法：working_directory path;**

worker进程的工作目录。这个配置项的唯一用途就是设置coredump文件所放置的目录，协助定位问题。一次，需要确保worker进程有权限向woring_directory指定的目录中写入文件。


### 正常运行的配置项
#### 1. 定义环境变量
**语法：env VAR|VAR=VALUE**

这个配置项可以让用户直接设置操作系统上的环境变量。

#### 2. 嵌入其他配置文件
**语法：include /path/file;**

include 配置项可以将其他配置文件嵌入到当前的nginx.conf文件中，它的参数既可以是绝对路径，也可以是相对路径。
```bash
include mime.types;
include vhost/*.conf;

```
参数的值可以是一个明确的文件名，也可以是含有通配符*的文件名，同时可以一次嵌入多个配置文件。

#### 3. pid文件的路径
**语法：pid path/file**

**默认：pid logs/nginx.pid;**

保存master进程id的pid文件存放路径。默认与configure执行时的参数“--pid-path”所指定的路径是相同的，也可以随时修改，但应确保nginx
有权在相应的目标中创建pid文件，该文件直接影响nginx是否可以运行。

#### 4. nginx worker进程运行的用户及用户组
**语法：user username [groupname];**

**默认：user nobody nobody;**

user用于设置master进程启动后，fork出的worker进程运行在哪个用户和用户组下。

#### 5. 指定nginx worker进程可以打开的最大句柄描述符个数
**语法：worker_rlimit_nofile limit;**

设置一个worker进程可以打开的最大文件句柄数

#### 6. 限制信号队列
**语法：worker_rlimit_sigpending limit;**

设置每个用户发往nginx的信号队列的大小。也就是说，当某个用户的信号队列满了，这个用户咋发送的信号量会被丢掉。

### 优化性能的配置项
#### 1. nginx worker进程个数
**语法：worker_processes number;**

**默认：worker_processes 1;**

在master/worker运行方式下，定义worker进程的个数。
worker进程的数量会直接影响性能。

#### 2. 绑定nginx worker进程到指定的cpu内核
**语法：worker_cpu_affinity cpumask [cpumask...]**

#### 3. ssl硬件加速
**语法：ssl_engine device;**

如果服务器上有ssl硬件加速设备，那么就可以进行配置以加快ssl协议的处理速度。用户可以使用openssl提供的命令查看是否有ssl硬件加速设备：
```bash
openssl engine -t
```

#### 4. 系统调用gettimeofday的执行频率
**语法：timer_resolution t;**

默认情况下，每次内核的事件调用返回时，都会执行一次gettimeofday，实现用内核的时钟来更新nginx中的缓存时钟。
在早期linux内核中，gettimeofday执行代价不小，因为中间又一次内核态到用户态的内存复制。当需要降低gettimeofday的调用频率时，可以使用
timer_resolution配置。

> 如果希望在日志文件中每行打印的时间更准确，也可以使用它。

#### 5. nginx worker进程优先级设置
**语法：worker_priority nice;**

**默认：worker_priority 0;**

该配置项用于设置nginx worker进程的Nice优先级。

优先级由静态优先级和内核根据进程执行情况所做的动态调整共同决定。nice值是进程的静态优先级，它的取值范围是-20~+19，-20是最高优先级，+19是最低优先级。


### 事件类配置项
#### 1. 是否打开accept锁
**语法：accept_mutex [on|off]**

**默认：accept_mutex on;**

accept_mutex是nginx的负载均衡锁，可以让多个worker进程轮流地、序列化第与新客户端建立tcp连接。当某一个worker进程建立的连接数量达到
worker_connections配置的最大连接数的7/8时，会大大地减小该worker进程试图简历新tcp连接的机会，以此实现所有worker进程之上处理的客户端请求数尽量接近。

accept锁默认是打开的，如果关闭它，那么建立tcp连接的耗时会更短，但worker进程之间的负载会非常不均衡，因此不建议关闭它。

#### 2. lock文件的路径
**语法：lock_file path/file;**

**默认：lock_file logs/nginx.lock;**

accept锁可能需要这个lock文件，如果accept锁关闭，lock_file配置完全不生效。如果打开了accept锁，并且由于编译程序、操作系统架构等因素
导致nginx不支持原子锁，这时才会用文件锁实现accept锁，这样lock_file指定的lock文件才会生效。

#### 3. 使用accept锁后到真正建立连接之间的延迟时间
**语法：accept_mutex_delay Nms;**

**默认：accept_mutex_delay 500ms;**

在使用accept锁后，同一时间只有一个worker进程能够取到accept锁。这个accept锁不是阻塞锁，如果取不到立刻返回。如果有一个worker进程试图取accept锁而没有取到，
他至少要等待accept_mutex_delay定义的时间间隔后才能再次试图取锁。

#### 4. 批量建立新连接
**语法：multi_accept [on|off];**

**默认：multi_accept off;**

当事件模型通知有新连接时，尽可能地对本次调度中客户端发起的所有tcp请求都建立连接。

#### 5. 选择事件模型
**语法： use [kqueue|rtsig|epoll|/dev/poll|select|poll|eventport];**

**默认：nginx会自动使用最适合的事件模型**

#### 6. 每个worker的最大连接数
**语法：worker_connections number;**

定义每个worker进程可以同时处理的最大连接数。









---
title: "linux Cgroups"
date: 2019-03-21T05:14:39+08:00
draft: false
---

Namespace技术为docker容器做了重要的隔离，但是docker容器每个隔离空间之间怎么保持独立而不互相竞争资源呢？这就是cgroups要做的事情了


Linux Cgroups(control groups)提供了对一组进程及其子进程的资源限制、控制和统计的能力，包括cpu、内存、存储和网络等。

### cgroups组件
- cgroup
- subsystem
- hierarchy

#### cgroup
cgroup是对进程分组管理的一种机制，一个cgroup包含一组进程，并可以在这个cgroup上增加linux subsystem的各种配置参数，将一组进程和一组subsystem的系统参数关联起来。


#### subsystem
是一组资源控制的模块，包括
- blkio 设置对块设备输入输出的访问控制
- cpu 设置cgroup 中进程的cpu被调度的策略
- cpuacct 可以统计cgroup中进程的cpu占用
- cpuset 在多核机器上设置cgroup中进程可以使用的cpu和内存
- devices 控制cgroup中进程对设备的访问
- freezer 用于挂起和恢复cgroup中的进程
- memory 用于控制cgroup中进程的内存占用
- net_cls 用于将cgroup中进程产生的网络包分类，以便linux的tc可以根据分类区分来自某个cgroup的包并做限流和监控
- ns 使cgroup中的进程在新的namespace中fork新进程时，创建出一个新的cgroup，这个cgroup包含新的namespace中的进程

每个subsystem会关联到定义了相应限制的cgroup上，并对这个cgroup中的进行做相应的限制和控制。这些subsystem是逐步合并到内核中的。

> 如何看内核当前支持哪些subsystem呢？使用apt-get install cgroup-bin，然后通过lssubsys -a查看

#### hierarchy
把一组cgroup串成一个树状结构，一个这样的树便是一个hierarchy，通过这种树状结构，cgroups可以形成继承关系。



#### 三个组件的关系
- 系统在创建了新的hierarchy之后，系统中所有的进程都会加入这个hierarchy的cgroup根节点，这个cgroup根节点是hierarchy默认创建的
- 一个subsystem只能附加到一个hierarchy上面
- 一个hierarchy可以附加多个subsystem
- 一个进程可以作为多个cgroup的成员，但是这些cgroup必须在不同的hierarchy中。
- 一个进程fork出子进程时，子进程是和父进程在同一个cgroup中的，也可以根据需要将其移动到其他cgroup中。

#### kernel加载Cgroups
kernel通过虚拟树状文件系统配置cgroups，通过层级的目录虚拟出cgroup树。

##### 1. 首先，要创建并挂载一个hierarchy
```bash
mkdir cgroup-test
mount -t cgroup -o none,name=cgroup-test cgroup-test ./cgroup-test # 挂载一个hierarchy
ls ./cgroup-test

```
- cgroup.clone_children cpuset的subsystem会读取这个配置文件。如果是1，子cgroup才会继承父cgroup的cpuset的配置
- cgroup.procs 是树中当前节点cgroup中的进程组id
- notify_on_release和release_agent 会一起使用
- tasks 标识该cgroup下面的进程id,如果一个进程id写到tasks文件中，便会将相应的进程加入到这个cgroup中。

##### 2. 在刚创建好的hierarchy 上的cgroup根节点中扩展出的两个子cgroup
```bash
cd cgroup-test
mkdir cgroup-1
mkdir cgroup-2
tree

```
可以看到，在一个cgroup的目录下创建文件夹时，kernel会把文件夹标记为这个cgroup的子cgroup，他们会继承父cgroup的属性

##### 3. 在cgroup中添加和移动进程
一个进程在一个cgroups的hierarchy中，只能在一个cgroup节点上存在，系统的所有进程都会默认在根节点上存在，可以将进程移动到其他cgroup节点。
只需要将进程id写到移动到的cgroup节点的tasks文件中即可。
```bash
[cgroup-1] sh -c "echo $$ >> tasks" #将我所在的终端进程移动到cgroup-1中

```

##### 4. 通过subsystem限制cgroup中进程的资源
在hierarchy中创建cgroup，限制如下进程占用的内存
```bash
[memory] stress --vm-bytes 200m --vm-keep -m 1
[memory] # 创建一个cgroup
[memory] mkdir test-limit-memory && cd test-limit-memory
[test-limit-memory] # 设置最大cgroup的最大内存占用为100MB
[test-limit-memory] sh -c "echo "100m" > memory.limit_in_bytes"
[test-limit-memory] sh - c "echo $$ > tasks" # 将当前进程移动到这个cgroup中
[test-limit-memory] stress --vm-bytes 200m --vm-keep -m 1 # 再次运行占用内存200MB的stress进程

```





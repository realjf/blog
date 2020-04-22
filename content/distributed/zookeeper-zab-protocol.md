---
title: "zab协议 （Zookeeper Zab Protocol）"
date: 2020-04-22T09:18:44+08:00
keywords: ["分布式", "zab协议"]
categories: ["distributed"]
tags: ["分布式", "zab协议“]
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


ZAB协议，（ZooKeeper Atomic Broadcast, ZooKeeper原子消息广播协议）

ZAB协议不像Paxos算法，它是一种特别为Zookeeper设计的崩溃可恢复的原子消息广播协议

### ZAB协议的核心
所有事务请求必须由一个全局唯一的服务器来协调处理，这样的服务器被称为Leader服务器，而余下的其他服务器则成为follower服务器，
leader服务器负责将一个客户端事务请求转换成一个事务Proposal，并将该Proposal分发给集群中所有的follower服务器，之后leader服务器需要
等待所有follower服务器的反馈，一旦超过半数的follower服务器进行了正确的反馈后，那么leader就会再次向所有的follower服务器分发commit消息，
要求其将前一个Proposal进行提交。



### ZAB协议内容
ZAB协议包括两种基本模式：崩溃恢复和消息广播。

当整个服务框架在启动过程中，或是当leader服务器出现网络中断、崩溃退出与重启等异常情况时，ZAB协议就会进入恢复模式并选举产生新的leader服务器。
当选举产生新的leader服务器后，同时集群中已经有过半机器与该leader服务器完成了状态同步之后，ZAB协议就会退出恢复模式，其中，所谓的状态同步是指数据同步，
用来保证集群中存在过半的机器能够和leader服务器的数据状态保持一致。

当集群中已经有过半的follower服务器完成了和leader服务器的状态同步，那么整个服务器框架就可以进入消息广播模式了。当一台同样遵循ZAB协议的服务器启动后加入到集群中，
如果此时集群中已经存在一个leader服务器在负责进行消息广播，那么新加入的服务器就会自觉的进入数据恢复模式：找到leader所在的服务器，并与其进行数据同步，
然后一起参与到消息广播流程中。

ZooKeeper设计成只允许唯一的一个leader服务器来进行事务请求的处理。leader服务器在接收到客户端的事务请求后，会生成对应的事务提案并发起一轮广播协议，
而如果集群中的其他机器接收到客户端的事务请求，那么这些非leader服务器会首先将这个事务请求转发给leader服务器。

当leader服务器出现崩溃退出或机器重启，亦或集群中已经不存在过半的服务器与该leader服务器保持正常通信时，那么在重新开始新一轮的原子广播事务操作之前，
所有进程首先会使用崩溃恢复协议来使彼此达到一个一致的状态，于是整个ZAB流程就会从消息广播模式进入到崩溃恢复模式。


### 数据同步
在ZAB协议的事务编号ZXID设计中，ZXID是一个64位的数字，其中低32位可以看作是一个简单的单调递增的计数器，针对客户端的每一个事务请求，leader服务器在产生
一个新的事务Proposal的时候，都会对该计数器进行加1操作，而高32位则代表了leader周期epoch的编号，每当选举产生一个新的leader服务器，就会从这个leader
服务器上取出其本地日志中最大事务Proposal的ZXID，并从该ZXID中解析出对应的epoch值，然后再对其进行加1操作，之后就会以此编号作为新的epoch，并
将低32位置0来开始生成新的ZXID。ZAB协议中的这一通过epoch编号来区分leader周期变化的策略，能够有效避免不同的leader服务器错误地使用相同的ZXID编号
提出不一样的事务Proposal的异常情况，这对于识别在leader崩溃恢复前后生成的Proposal非常有帮助。


基于这样的策略，当一个包含了上一个leader周期中尚未提交过的事务Proposal的服务器启动时，其肯定无法成为leader，因为当前集群中一定包含一个Quorum集合，
该集合中的机器一定包含了更高epoch的事务Proposal，因此这台机器的事务Proposal肯定不是最高，也就无法成为leader了。


### ZAB与Paxos算法的联系与区别
#### 联系
- 两者都存在一个类似leader进程的角色，由其负责协调多个follower进程的运行
- leader进程都会等待超过半数的follower做出正确的反馈后，才会将一个提案进行提交
- 在ZAB协议中，每个Proposal中都包含了一个epoch值，用来代表当前leader周期，在Paxos算法中，同样存在这样一个标识，只是名字是Ballot。
#### 区别
Paxos算法一个新选举产生的主进程会进行两个阶段的工作，第一阶段称为读阶段，与所有其他进程通信收集上一个主进程提出的提案，并将它们提交。
第二个阶段称为写阶段，主进程开始提出自己的提案。

ZAB协议在Paxos算法上额外添加了一个同步阶段。在同步阶段之前，ZAB有个类似Paxos算法的读阶段，称为发现阶段。同步阶段之后，也有一个类似的写阶段。










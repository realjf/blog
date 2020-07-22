---
title: "分布式锁的实现方式和原理"
date: 2020-04-28T14:53:32+08:00
keywords: ["分布式"]
categories: ["distributed"]
tags: ["分布式"]
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

#### 我们需要的分布式锁应该是怎么样的？
- 可以保证在分布式部署的应用集群中，同一个方法在同一时间只能被一台机器上的一个线程执行。
- 这把锁要是一把可重入锁（避免死锁）
- 这把锁最好是一把阻塞锁（根据业务需求考虑要不要这条）
- 有高可用的获取锁和释放锁功能
- 获取锁和释放锁的性能要好


#### 实现分布式锁的几种方法

分布式锁是控制分布式系统之间同步访问共享 资源的一种方式。在分布式系统中，常常需要协调他们的动作，如果不同的系统或是同一个系统的不同主机之间共享了一个或一组资源，那么访问这些资源的时候，往往需要互斥来防止彼此干扰来保证一致性，这种情况下，便需要使用到分布式锁。


- 基于缓存实现，如Redis实现——使用redis的setnx()、get()、getset()方法，用于分布式锁，解决死锁问题
- 基于数据库乐观锁实现
- 基于zookeeper实现

> 乐观锁通常实现基于数据版本(version)的记录机制实现的，比如有一张红包表（t_bonus），有一个字段(left_count)记录礼物的剩余个数，用户每领取一个奖品，对应的left_count减1，在并发的情况下如何要保证left_count不为负数，乐观锁的实现方式为在红包表上添加一个版本号字段（version），默认为0。

```shell
SETNX key val 
# 原子性操作，当且仅当key不存在时，set一个key为val的字符串，返回1；若key存在，则什么都不做，返回0。
expire key timeout 
# 为key设置一个超时时间，单位为second，超过这个时间锁会自动释放，避免死锁。
delete key 
# 删除key

GETSET key value
# 将给定 key 的值设为 value ，并返回 key 的旧值 (old value)，当 key 存在但不是字符串类型时，返回一个错误，当key不存在时，返回nil
```

#### 基于数据库实现
使用数据库乐观锁，包括主键防重，版本号控制。但是这两种方法各有利弊。

- 使用主键冲突的策略进行防重，在并发量非常高的情况下对数据库性能会有影响，尤其是应用数据表和主键冲突表在一个库的时候，表现更加明显。其实针对是否会对数据库性能产生影响这个话题，我也和一些专业的DBA同学讨论过，普遍认可的是在MySQL数据库中采用主键冲突防重，在大并发情况下有可能会造成锁表现象，比较好的办法是在程序中生产主键进行防重。

- 使用版本号策略 
这个策略源于mysql的mvcc机制，使用这个策略其实本身没有什么问题，唯一的问题就是对数据表侵入较大，我们要为每个表设计一个版本号字段，然后写一条判断sql每次进行判断。


##### 基于数据库表实现
要实现分布式锁，最简单的方式可能就是直接创建一张锁表，然后通过操作该表中的数据来实现了。

当我们要锁住某个方法或资源时，我们就在该表中增加一条记录，想要释放锁的时候就删除这条记录。

上面这种简单的实现有以下几个问题：
- 1、这把锁强依赖数据库的可用性，数据库是一个单点，一旦数据库挂掉，会导致业务系统不可用。

- 2、这把锁没有失效时间，一旦解锁操作失败，就会导致锁记录一直在数据库中，其他线程无法再获得到锁。

- 3、这把锁只能是非阻塞的，因为数据的insert操作，一旦插入失败就会直接报错。没有获得锁的线程并不会进入排队队列，要想再次获得锁就要再次触发获得锁操作。

- 4、这把锁是非重入的，同一个线程在没有释放锁之前无法再次获得该锁。因为数据中数据已经存在了。

##### 如何解决以上问题？
- 数据库是单点？搞两个数据库，数据之前双向同步。一旦挂掉快速切换到备库上。
- 没有失效时间？只要做一个定时任务，每隔一定时间把数据库中的超时数据清理一遍。
- 非阻塞的？搞一个while循环，直到insert成功再返回成功。
- 非重入的？在数据库表中加个字段，记录当前获得锁的机器的主机信息和线程信息，那么下次再获取锁的时候先查询数据库，如果当前机器的主机信息和线程信息在数据库可以查到的话，直接把锁分配给他就可以了

##### 基于数据库排他锁
除了可以通过增删操作数据表中的记录以外，其实还可以借助数据中自带的锁来实现分布式的锁。

可以通过数据库的排他锁来实现分布式锁。 基于MySql的InnoDB引擎，可以使用以下方法来实现加锁操作：
```
public boolean lock(){
    connection.setAutoCommit(false)
    while(true){
        try{
            result = select * from methodLock where method_name=xxx for update;
            if(result==null){
                return true;
            }
        }catch(Exception e){

        }
        sleep(1000);
    }
    return false;
}
```
在查询语句后面增加for update，数据库会在查询过程中给数据库表增加排他锁（这里再多提一句，InnoDB引擎在加锁的时候，只有通过索引进行检索的时候才会使用行级锁，否则会使用表级锁。这里我们希望使用行级锁，就要给method_name添加索引，值得注意的是，这个索引一定要创建成唯一索引，否则会出现多个重载方法之间无法同时被访问的问题。重载方法的话建议把参数类型也加上。）。当某条记录被加上排他锁之后，其他线程无法再在该行记录上增加排他锁。


- 阻塞锁？ for update语句会在执行成功后立即返回，在执行失败时一直处于阻塞状态，直到成功。
- 锁定之后服务宕机，无法释放？使用这种方式，服务宕机之后数据库会自己把锁释放掉


但是还是无法直接解决数据库单点和可重入问题

> 这里还可能存在另外一个问题，虽然我们对method_name 使用了唯一索引，并且显示使用for update来使用行级锁。但是，MySql会对查询进行优化，即便在条件中使用了索引字段，但是否使用索引来检索数据是由 MySQL 通过判断不同执行计划的代价来决定的，如果 MySQL 认为全表扫效率更高，比如对一些很小的表，它就不会使用索引，这种情况下 InnoDB 将使用表锁，而不是行锁

> 还有一个问题，就是我们要使用排他锁来进行分布式锁的lock，那么一个排他锁长时间不提交，就会占用数据库连接。一旦类似的连接变得多了，就可能把数据库连接池撑爆


#### zookeeper实现
##### 利用节点名称的唯一性来实现独占锁

ZooKeeper机制规定同一个目录下只能有一个唯一的文件名，zookeeper上的一个znode看作是一把锁，通过createznode的方式来实现。所有客户端都去创建/lock/${lock_name}_lock节点，最终成功创建的那个客户端也即拥有了这把锁，创建失败的可以选择监听继续等待，还是放弃抛出异常实现独占锁。

##### 利用临时顺序节点控制时序实现

lock已经预先存在，所有客户端在它下面创建临时顺序编号目录节点，和选master一样，编号最小的获得锁，用完删除，依次方便

算法思路：对于加锁操作，可以让所有客户端都去/lock目录下创建临时顺序节点，如果创建的客户端发现自身创建节点序列号是/lock/目录下最小的节点，则获得锁。否则，监视比自己创建节点的序列号小的节点（比自己创建的节点小的最大节点），进入等待。

对于解锁操作，只需要将自身创建的节点删除即可。


#### 基于redis实现
##### 第一种：使用redis的setnx()、expire()方法，用于分布式锁
•setnx(lockkey, 1) 如果返回0，则说明占位失败；如果返回1，则说明占位成功
•expire()命令对lockkey设置超时时间，为的是避免死锁问题。
•执行完业务代码后，可以通过delete命令删除key。


这个方案其实是可以解决日常工作中的需求的，但从技术方案的探讨上来说，可能还有一些可以完善的地方。比如，如果在第一步setnx执行成功后，在expire()命令执行成功前，发生了宕机的现象，那么就依然会出现死锁的问题

##### 第二种：使用redis的setnx()、get()、getset()方法，用于分布式锁，解决死锁问题
1. setnx(lockkey, 当前时间+过期超时时间) ，如果返回1，则获取锁成功；如果返回0则没有获取到锁，转向2。
2. get(lockkey)获取值oldExpireTime ，并将这个value值与当前的系统时间进行比较，如果小于当前系统时间，则认为这个锁已经超时，可以允许别的请求重新获取，转向3。
3. 计算newExpireTime=当前时间+过期超时时间，然后getset(lockkey, newExpireTime) 会返回当前lockkey的值currentExpireTime。
4. 判断currentExpireTime与oldExpireTime 是否相等，如果相等，说明当前getset设置成功，获取到了锁。如果不相等，说明这个锁又被别的请求获取走了，那么当前请求可以直接返回失败，或者继续重试。

5. 在获取到锁之后，当前线程可以开始自己的业务处理，当处理完毕后，比较自己的处理时间和对于锁设置的超时时间，如果小于锁设置的超时时间，则直接执行delete释放锁；如果大于锁设置的超时时间，则不需要再锁进行处理。


> 失效时间我设置多长时间为好？如何设置的失效时间太短，方法没等执行完，锁就自动释放了，那么就会产生并发问题。如果设置的时间太长，其他获取锁的线程就可能要平白的多等一段时间。这个问题使用数据库实现分布式锁同样存在






#### 参考文档：
- https://blog.csdn.net/jp413670706/article/details/52737282
- https://www.cnblogs.com/SophieLSR/p/9001789.html
- redis乐观锁 https://blog.csdn.net/chunlongyu/article/details/53346436
- http://www.hollischuang.com/archives/1716?utm_source=tuicool&utm_medium=referral
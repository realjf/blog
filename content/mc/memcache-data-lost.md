---
title: "memcache数据提前过期（丢失）Memcache Data Lost"
date: 2020-04-15T10:51:20+08:00
keywords: ["memcache"]
categories: ["mc"]
tags: ["memcache"]
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


### 背景
今天遇到一个比较奇葩的问题，使用脚本测试接口防洪攻击时，mc的封禁数据还未到过期时间就出现数据“丢失”的情况，
一直以为是代码问题，后来偶然想到memcache在达到内存超过50%以上时，就可能采用LRU算法回收部分内存，考虑到防洪封禁数据
比较多，所以做了本地测试

### 了解下memcache的一些状态信息
php通过getStat函数获取memcache状态信息。

- pid mc进程号
- uptime 服务器已运行秒数
- version 版本
- time 当前时间
- libevent libevent版本
- pointer_size 当前os的指针大小(64位系统一般为64)
- rusage_user 进程的累计用户时间
- rusage_system 进程的累计系统时间
- curr_connections 服务器当前打开的连接数
- total_connections 从服务器启动后累计打开的总连接数
- connection_structures 服务器分配的连接结构数
- reserved_fds 
- cmd_get get命令总请求次数
- cmd_set set命令总请求次数
- cmd_flush flush命令请求次数
- cmd_touch touch命令请求次数
- get_hits get命令总命中次数
- get_misses get命令总未命中次数
- delete_misses
- delete_hits
- incr_misses
- incr_hits
- decr_misses
- decr_hits
- cas_misses
- cas_hits
- cas_badval 使用擦拭次数
- touch_hits
- touch_misses
- auth_cmds 认证命令处理次数
- auth_errors 认证失败次数
- bytes_read 总读取字节数（请求字节数）
- byte_written 总发送字节数（结果字节数）
- limit_maxbytes 分配给memcache的内存大小（字节）
- accepting_conns 服务器是否大打过最大连接数
- listen_disabled_num 失效的监听数
- threads 当前线程数
- conn_yields 连接操作主动放弃数目
- hash_power_level 
- hash_bytes
- hash_is_expanding
- malloc_fails
- bytes 当前存储内容所占总字节数
- curr_items 当前存储的items数量
- total_items 从启动后存储的items总数量
- expired_unfetched 
- evicted_unfetched
- evictions 为获取空闲内存而删除的items数，LRU算法释放（分配给memcache的空间用满后需要删除旧的items来得到空间分配给新的items）
- reclaimed 已过期的数据条目来存储新数据的数目
- crawler_reclaimed
- lrutail_reflocked


解决方法是，增大MC使用内存



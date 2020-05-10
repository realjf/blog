---
title: "docker error creating overlay mount to invalid argument 解决方法"
date: 2020-04-28T15:29:31+08:00
keywords: ["docker"]
categories: ["docker"]
tags: ["docker"]
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


#### 原因
由于docker的不同版本在centos上产生的mount问题，1.2.x没有出现这个问题，当使用yum install时，安装的最新版本(1.3.x)，会导致overlay2的错误。

#### 解决方法
修改docker启动参数storage-driver
```
vim /etc/sysconfig/docker-storage
# 将文件中的DOCKER_STORAGE_OPTIONS="-s overlay2"修改为DOCKER_STORAGE_OPTIONS="-s overlay"

```
然后重新加载daemon
```
systemctl daemon-reload
```

重启docker
```
systemctl restart docker
```





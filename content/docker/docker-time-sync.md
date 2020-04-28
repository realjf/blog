---
title: "Docker容器和宿主机时间不一致问题解决"
date: 2020-04-28T15:26:29+08:00
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


#### 1. 在Dockerfile中解决（永久性，推荐）
在Dockerfile文件中加上如下：
```
ENV TZ=Asia/Shanghai # 添加你需要的时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
```

#### 2. 临时性设置
在container的shell交互里输入
```
TZ=Asia/Shanghai
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

## 检查时间
date

```



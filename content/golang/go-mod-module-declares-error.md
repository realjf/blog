---
title: "Go Mod Module Declares Its Path as: xxxx but was required as: xxxx"
date: 2020-09-09T09:18:15+08:00
keywords: ["golang"]
categories: ["golang"]
tags: ["golang"]
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
今天在一个新项目文件下执行了go mod init初始化后，进行go build，报如下错误：
```shell
go: example imports
        github.com/realjf/goframe: github.com/realjf/goframe@v0.0.0-20200908085940-3b9391b761c4: parsing go.mod:
        module declares its path as: goframe
                but was required as: github.com/realjf/goframe
```

意思是，模块声明为goframe，但是却使用github.com/realjf/goframe作为包引入

### 解决方法
首先确认引入的包的go.mod文件里的module名称是否为github.com/realjf/goframe,

如果是，则进行下一步，如果不是，则需要修改为module github.com/realjf/goframe

然后是在新项目的go.mod文件中新增一行如下内容：
```shell
# 格式为：replace (module declares its path as:后边那部分) => (but was required as:后边那部分) 版本号
replace goframe => github.com/realjf/goframe v0.0.0 // indirect
```
之后重新执行go build，可以发现问题解决，并且在go.mod文件中多了一行：
```shell
require github.com/realjf/goframe v0.0.0-20200908095551-2f2da0b85d99
```



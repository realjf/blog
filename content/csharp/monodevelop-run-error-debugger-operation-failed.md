---
title: "Monodevelop运行代码报错 Monodevelop Run Error Debugger Operation Failed, Native error=cannot find the specified file"
date: 2020-12-18T06:01:37+08:00
keywords: ["csharp", "monodevelop"]
categories: ["csharp"]
tags: ["csharp", "monodevelop"]
series: [""]
draft: false
toc: false
related:
  threshold: 50
  includeNewer: true
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


## 背景
今天使用monodevelop创建一个项目后，运行代码，报如下错误：
```sh
Debugger operation failed
ApplicationName='/usr/lib/gnome-terminal/gnome-terminal-server', CommandLine='--app-id mono.develop.id1f71c1c4cede406e9ae6cc55355f30e2', CurrentDirectory='', Native error= Cannot find the specified file
```

这个是因为monodevelop使用的/usr/lib/gnome-terminal/gnome-terminal-server 文件实际路径是在/usr/libexec/gnome-terminal-server下，
所以只需要把/usr/libexec/gnome-terminal-server文件复制到原路径下即可。

## 解决
```sh
mkdir -p /usr/lib/gnome-terminal
ln -s /usr/libexec/gnome-terminal-server /usr/lib/gnome-terminal/
```

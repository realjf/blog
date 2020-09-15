---
title: "windows环境下安装Php扩展Mcrypt"
date: 2020-09-15T14:34:59+08:00
keywords: ["php"]
categories: ["php"]
tags: ["php", "mcrypt"]
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

## 准备
- xampp环境
mcrypt扩展下载地址[https://windows.php.net/downloads/pecl/releases/mcrypt/](https://windows.php.net/downloads/pecl/releases/mcrypt/)

## 解压安装
解压后，直接复制php_mcrypt.dll到php/ext目录下，
然后在php.ini中添加一行extension=php_mcrypt.dll，重启apache即可









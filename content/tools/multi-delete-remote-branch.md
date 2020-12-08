---
title: "git批量删除远程分支 Multi Delete Remote Branch"
date: 2020-12-09T04:08:48+08:00
keywords: ["tools"]
categories: ["tools"]
tags: ["tools", "git"]
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

### 批量删除本地分支
```shell script
git branch -a| grep -v -E 'master|develop' | xargs git branch -D
# -v 排除
# -E 使用正则表达式
```

### 批量删除远程分支
```shell script
# 方法一
git branch -r | grep -v -E 'master|dev' | sed 's/origin\///g' | xargs -I {} git push origin :{}
# -I {} 使用占位符来构造后面的命令
# 保留master和dev远程分支

# 方法二
git branch -r| awk -F '[/]' '/origin\/dev/ {printf "%s\n", $2}' |xargs -I{} git push origin :{}

# 方法三
git branch -r| grep -E 'develop_|fix_' |xargs -I{} git push origin :{}
```





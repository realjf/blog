---
title: "sphinx的 total 和 total_found的区别"
date: 2020-04-28T14:26:04+08:00
keywords: [""]
categories: ["sphinx"]
tags: [""]
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

sphinx.conf文件里面有一个配制最大匹配数的参数max_matches ,默认值是1000假如一次搜索里应该查询到2000个匹配,但是在sphinx结果集中只会返回1000个匹配，因为受到max_matches=1000的限制,这时候,结果集里,
total=1000,total_found=2000,假设一页显示20条,那么如果用total_found做为分页的总数来设定,在第51页之后的数据都将显示为空白,因为操过了1000条记录.

于是,我修改了sphinx.conf里的max_matches=2000,结果发现,改成2000之后还是没有取到2000条记录,在第51页之后都是空白数据,为什么?

这时候我又去网上查了资料,发现,$s->SetLimits($start, $limit)的第三个参数,默认为1000,这个参数也是用来设定返回的最大匹配数的,所以这就是这为什么配制文件里改成2000后还是只取到1000条记录的原因...

还有一点,就是setLimits的第三个参数的值不能超过max_matches的值,否则将取不到记录

所以,total_found返回的是所有的匹配数,不受max_matches和setLimits的第三个参数的限制,而total返回的匹配数最大不超过max_matches和setLimits里的最小值

比如我们经常看到的,淘宝搜索返回的页面最多只返回100页的数据,这时候,total和total_found就能很好的起到作用


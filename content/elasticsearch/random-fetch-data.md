---
title: "elasticsearch随机获取数据 random Fetch Data"
date: 2020-06-10T11:47:39+08:00
keywords: ["elasticsearch"]
categories: ["elasticsearch"]
tags: ["elasticsearch"]
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

搜索的形式随机获取数据
```json
{
  "query": {
    "bool": {
      "must": [{
        "term": {
          "game_id": 132
        }
      }]
    }
  },
  "from": 1,
  "size": 100,
  "sort": {
    "_script": {
      "script": "Math.random()",
      "type": "number",
      "order": "asc"
    }
  }
}
```




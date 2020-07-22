---
title: "elasticsearch的doc_values和fielddata区别"
date: 2020-06-04T18:15:14+08:00
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

Elasticsearch 首先分析文档，之后根据结果创建倒排索引。

### 倒排索引
Elasticsearch 使用一种称为 倒排索引 的结构，它适用于快速的全文搜索。一个倒排索引由文档中所有不重复词的列表构成，对于其中每个词，有一个包含它的文档列表。



### doc_values
doc_values使聚合更快、更高效且内存使用率高。

在 Elasticsearch 中，doc_values 就是一种列式存储结构，默认情况下每个字段的 doc_values 都是激活的，
doc_values 是在索引时创建的。当字段索引时，Elasticsearch 为了能够快速检索，会把字段的值加入倒排索引中，同时它也会存储该字段的 `doc_values`。

Elasticsearch 中的 doc_values 常被应用到以下场景：

- 对一个字段进行排序
- 对一个字段进行聚合
- 某些过滤，比如地理位置过滤
- 某些与字段相关的脚本计算

因为文档值（doc_values）被序列化到磁盘，我们可以依靠操作系统的帮助来快速访问。
当 working set 远小于节点的可用内存，系统会自动将所有的文档值保存在内存中，使得其读写十分高速；
当其远大于可用内存，操作系统会自动把 doc_values 加载到系统的页缓存中，从而避免了 jvm 堆内存溢出异常。

> 因此，搜索和聚合是相互紧密缠绕的。搜索使用倒排索引查找文档，聚合操作收集和聚合 doc_values 里的数据。

doc_values 支持大部分字段类型，但是text 字段类型不支持（因为analyzed）。

```json
{
  "mappings": {
    "properties": {
      "status_code": {
        "type": "keyword"
      },
      "session_id": {
        "type": "keyword",
        "doc_values": false
      }
    }
  }
}
```
- (1) status_code 字段默认启动 doc_values 属性；
- (2) session_id 显式设置 doc_values = false，但是仍然可以被查询；

> 如果确信某字段不需要排序或者聚合，或者从脚本中访问字段值，那么我们可以设置 doc_values = false，这样可以节省磁盘空间。

### fielddata
与 doc values 不同，fielddata 构建和管理 100% 在内存中，常驻于 JVM 内存堆。这意味着它本质上是不可扩展的。


fielddata可能会消耗大量的堆空间，尤其是在加载高基数（high cardinality）text字段时。一旦fielddata已加载到堆中，
它将在该段的生命周期内保留。此外，加载fielddata是一个昂贵的过程，可能会导致用户遇到延迟命中。
这就是默认情况下禁用fielddata的原因。

如果需要对 text 类型字段进行排序、聚合、或者从脚本中访问字段值，则会出现如下异常：
```
Fielddata is disabled on text fields by default. Set fielddata=true on [your_field_name] in order to load fielddata in memory by uninverting the inverted index. Note that this can however use significant memory.
```
但是，在启动fielddata 设置之前，需要考虑为什么针对text 类型字段进行排序、聚合、或脚本呢？通常情况下，这是不太合理的。
text字段在索引时，例如New York，这样的词会被分词，会被拆成new、york 2个词项，这样当搜索new 或 york时，可以被搜索到。在此字段上面来一个terms的聚合会返回一个new的bucket和一个york的bucket，但是你可能想要的是一个单一new york的bucket。
 
怎么解决这一问题呢？
你可以使用 text 字段来实现全文本查询，同时使用一个未分词的 keyword 字段，且启用doc_values，来处理聚合操作。

```json
{
  "mappings": {
    "properties": {
      "my_field": {
      "type": "text",
      "fields": {
        "keyword": {
          "type": "keyword"
        }
       }
      }
    }
  }
}

```

- (1) 使用my_field 字段用于查询；
- (2) 使用my_field.keyword 字段用于聚合、排序、或脚本；
 
可以使用 PUT mapping API 在现有text 字段上启用 fielddata，
```json
{
  "properties": {
    "my_field": {
      "type": "text",
      "fielddata": true
    }
  }
}
```

 
 
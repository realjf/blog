---
title: "opengl光照之三 材质 Materials"
date: 2021-05-13T10:14:28+08:00
keywords: ["opengl"]
categories: ["opengl"]
tags: ["opengl"]
series: [""]
draft: true
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

每个物体对镜面高光也有不同的反应。有些物体反射光的时候不会有太多的散射(Scatter)，因而产生一个较小的高光点，而有些物体则会散射很多，产生一个有着更大半径的高光点。如果想要在OpenGL中模拟多种类型的物体，必须为每个物体分别定义一个材质(Material)属性。



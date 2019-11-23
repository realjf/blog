---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
keywords: [""]
categories: ["{{ .Section }}"]
tags: [""]
series: [""]
draft: true
toc: true
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


---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
keywords: [""]
categories: ["{{ .Section }}"]
tags: [""]
series: [""]
draft: true
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
  - name: date
    weight: 10
---


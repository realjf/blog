---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
keywords: ["{{ .Section }}"]
categories: ["{{ .Section }}"]
tags: ["{{ .Section }}"]
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


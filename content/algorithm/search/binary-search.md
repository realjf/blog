---
title: "Binary Search"
date: 2020-05-13T11:00:54+08:00
keywords: ["algorithm"]
categories: ["algorithm"]
tags: ["algorithm"]
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

对于已排序的数组A进行二分查找，实现如下：

```c
int binarySearch(int key){
    int left = 0;
    int right = n;
    int mid;
    while(left < right){
        mid = (left+right)/2;
        if(key == A[mid]) return 1;
        if(key > A[mid]) left = mid+1;
        else if(key < A[mid]) right = mid;
    }

    return 0;
}

```

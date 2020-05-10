---
title: "排序算法之插入排序 Insert Sort"
date: 2020-04-28T15:03:02+08:00
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


插入排序是简单的说，就是遍历整个数组，每次将一个元素插入到已排序的数组中，直到插入最后一个元素即完成整个排序过程。

#### 基本思想
1. 将开头第一个元素视作已排序部分，后续元素视作未排序部分
2. 对未排序部分执行一下操作，直到未排序部分被消除
   - 取出未排序部分开头第一个元素作为待排序元素t
   - 将t与已排序部分进行对比，将比t顺序大的元素往后移动一个，即确定排序位置
   - 将待排序元素t插入空出的排序位置中
   

```c

#include <stdio.h>
int main(){
    int a[10],i,j;

    for(i=0;i<10;i++){scanf("%d", &a[i]);}

    for (i=1;i<10;i++){
        int t = a[i]; // 待排序元素
        j = i-1;
        while(j>=0 && a[j] > t){
          a[j+1] = a[j]; // 往后移动一个
          j--;
        }
        a[j+1] = t; // 插入
    }

   for(i=0; i<10;i++){
    printf("%d ", a[i]);
  }
}
```

插入排序算法最坏的情况时间复杂度也是O(n^2)




---
title: "排序算法之冒泡排序 Bubble Sort"
date: 2020-04-28T15:00:51+08:00
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


冒泡排序算法很简单，对相邻的元素进行两两比较，顺序相反则进行交换，这样，每一趟会将最小或最大的元素“浮”到顶端，最终达到完全有序。

基本思想：
1. 


```c
#include <stdio.h>
void swap(int* a, int* b){
    if(*a > &b){
        *a = *a+*b;
        *b = *a-*b;
        *a = *a-*b;
    }
    return;
}
int main(){
    int a[10],i,j;

    for(i=0;i<10;i++){scanf("%d", &a[i]);}

    for (i=0;i<10;i++){
        for(j=0; j<i; j++){
            swap(&a[i], &a[j]);
        }
    }

   for(i=0; i<10;i++){
    printf("%d", a[i]);
  }
}

```
由以上程序可以看出，程序的时间复杂度是O(n^2)





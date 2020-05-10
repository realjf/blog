---
title: "排序算法之选择排序 Select Sort"
date: 2020-04-28T15:03:27+08:00
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

选择排序算法是每次循环遍历出未排除中最小值的位置，然后与将其与未排序部分第一个元素进行交换

```c
#include <stdio.h>

void swap(int* a, int* b)
{
    if(*a > *b){
        *a = *a + *b;
        *b = *a - *b;
        *a = *a - *b;
    }

}

int main(){
    int a[10],i,j;
    for(i=0;i<10;i++){
        scanf("%d", &a[i]);
    }
    
    for(i=0;i<9;i++){
        int min = i;
        for(j=i+1;j<10;j++){
            if(a[j] < a[min]){
                min = j;
            }
        }
        swap(&a[min], &a[i]);
    }
    return 0;
}
```

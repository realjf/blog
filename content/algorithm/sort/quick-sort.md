---
title: "排序算法之快速排序 Quick Sort"
date: 2020-04-28T15:03:14+08:00
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

快速排序的基本思想是：
- 以整个数组为对象执行quickSort
- quickSort流程如下
    - 通过分割将对象局部数组分割为前后两个局部数组
    - 对前半部分的局部数组执行quickSort
    - 对后半部分的局部数组执行quickSort
   
> 分割后前半部分数组都小于等于分割点元素，后半部分都大于分割点元素

```c
#include <stdio.h>
#define MAX 100000
#define SENTINEL 200000000

struct Card{
    char suit;
    int value;
};

struct Card L[MAX / 2 + 2], R[MAX/2 + 2];

int partition(struct Card A[], int, n, int p, int r){
    int i, j;
    struct Card t, x;
    x = A[r];
    i = p -1;
    for(j = p; j < r; j++){
        if(A[j].value <= x.value){
            i++;
            t = A[i];
            A[i] = A[j];
            A[j] = t;
        }
    }
    t = A[i+1];
    A[i+1] = A[r];
    A[r] = t;
    return i+1;
}

// 快速排序
void quickSort(struct Card A[], int n, int p, int r){
    int q;
    if(p < r){
        q = partition(A, n, p, r);
        quickSort(A, n, p, q - 1);
        quickSort(A, n, q + 1, r);
    }
}


```

对比下归并排序
```c

void merge(struct Card A[], int n, int left, int mid, int right){
    int i, j, k;
    int n1 = mid - left;
    int n2 = right - mid;
    for (i = 0; i < n1; i++) L[i] = A[left+i];
    for (i = 0; i < n2; i++) R[i] = A[mid+i];
    
    L[n1].value = R[n2].value = SENTINEL;
    i = j = 0;
    for (k = left; k < right; k++){
        if(L[i].value <= R[j].value){
            A[k] = L[i++];
        }else{
            A[k] = R[j++];
        }
    }
}

// 归并排序
void mergeSort(struct Card A[], int n, int left, int right){
    int mid;
    if(left + 1 < right) {
        mid = (left + right) / 2;
        mergeSort(A, n, left, mid);
        mergeSort(A, n, mid, right);
        merge(A, n, left, mid, right);
    }
}
```


---
title: "排序算法之希尔排序 Shell Sort"
date: 2020-04-28T15:03:09+08:00
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

希尔排序充分利用插入排序可以高速处理顺序较整齐的数据的特点，重复进行以间隔为g的插入排序。g是一组数列集合。

```c
void shellSort(int A[], int n)
{
    // 生成数列G={1, 4, 13, 40, 121, 364, 1093, ...}
    for(int h = 1; ; ){
        if(h > n) break;
        G.push_back(h);
        h = 3*h + 1;
    }

    // 按逆序指定G[i]=g
    for (int i = G.size() - 1; i >= 0; i--){
        insertionSort(A, n, G[i]);
    }
}

void insertionSort(int A[], int n, int g)
{
    for(int i = g; i < n; i++){
        int v = A[i];
        int j = i - g;
        while(j >= 0 && A[j] > v){
            A[j+g] = A[j];
            j -= g;
            cnt++;
        }
        A[j + g] = v;
    }
}

```


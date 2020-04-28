---
title: "排序算法之归并排序 Merge Sort"
date: 2020-04-28T15:03:19+08:00
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

归并排序的基本思想是：
- 将给定的包含n个元素的局部数组“分割”成两个局部数组，每个数组各包含n/2各元素。
- 对两个局部数组分别执行mergeSort排序。
- 通过merge将两个已排序完毕的局部数组整合成一个数组。


```cpp
#inlcude <iostream>
using namespace std;
#define MAX 500000
#define SENTINEL 2000000000

int L[MAX/2+2], R[MAX/2+2];
int cnt;


void merge(int A[], int n, int left, int mid, int right){
    int n1 = mid - left;
    int n2 = right - mid;
    for(int i=0; i< n1; i++)L[i] = A[left+i];
    for(int i = 0; i< n2;i++) R[i] = A[mid+i];
    L[n1] = R[n2] = SENTINEL;
    int i = 0; j = 0;
    for(int k = left; k<right;k++){
        cnt++;
        if(L[i]<=R[j]){
            A[k] = L[i++];
        }else{
            A[k] = R[j++];
        }
    }
}

void mergeSort(int A[], int n, int left, int right){
    if(left+1 < right){
        int mid = (left + right) / 2;
        mergeSort(A, n, left, mid);
        mergeSort(A, n, mid, right);
        merge(A, n, left, mid, right);
    }
}

int main(){
    int A[MAX], n, i;
    cnt = 0;
    
    cin >> n;
    for(i = 0; i<n; i++) cin>>A[i];
    
    mergeSort(A, n, 0, n);
    
    for(i=0; i<n; i++){
        if(i) cout << " ";
        cout << A[i];
    }
    
    cout << endl;
    cout << cnt << endl;
    return 0;
}

```



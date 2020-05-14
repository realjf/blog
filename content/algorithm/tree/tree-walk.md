---
title: "树的遍历 Tree Walk"
date: 2020-05-14T16:14:16+08:00
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

### 前序遍历
按照根节点、左子树、右子树的顺序输出节点编号。称为树的前序遍历
```c
#define MAX 10000
#define NIL -1

struct Node { int p, l, r;};
struct Node T[MAX];

void preOrder(int u) {
    if(u == NIL) return;
    printf(" %d", u);
    preOrder(T[u].l);
    preOrder(T[u].r);
}
```

### 中序遍历
按照左子树、根节点、右子树的顺序输出节点编号。称为树的中序遍历
```c
void inOrder(int u) {
    if(u == NIL) return;
    inOrder(T[u].l);
    printf(" %d", u);
    inOrder(T[u].r);
}
```

### 后序遍历
按照左子树、右子树、根节点的顺序输出节点编号。称为树的后序遍历
```c
void postOrder(int u) {
    if(u == NIL) return;
    postOrder(T[u].l);
    postOrder(T[u].r);
    printf(" %d", u);
}
```


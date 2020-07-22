---
title: "二叉搜索树 Binary Search Tree"
date: 2020-07-22T09:37:10+08:00
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

### 二叉搜索树的性质
- 若任意节点的左子树不空，则左子树上所有节点的值均不大于它的根节点的值
- 若任意节点的右子树不空，则右子树上所有节点的值均不小于它的根节点的值
- 任意节点的左右子树分别为二叉搜索树

### 二叉搜索树的特点
- 有链表的快速插入与删除操作
- 也有数组快速查找的优势

### 二叉搜索树的复杂度
- 平均每次操作需要O(logn)的时间

在最优的情况下，二叉搜索树为完全二叉树，其平均比较次数为logN,在最差情况下，二叉搜索树退化为单支树，其平均比较次数为N

如果退化成单支树，二叉搜索树的性能就失去了，如何改进呢？这将在平衡二叉树AVL树中进行讲述。


### 二叉搜索树的实现
```c++
#include <iostream>
using namespace std;

template<class T>
struct BSTNode
{
    BSTNode(const T& key = T())
    : _left(nullptr), _right(nullptr), _key(key)
    {

    }

    BSTNode<T>* _left;
    BSTNode<T>* _right;
    T _key;
};

template<class T>
class BSTree
{
    typedef BSTNode<T> Node;
public:
    BSTree() : _root(nullptr)
    {

    }

    ~BSTree()
    {

    }

    BSTree(const BSTree<T>& tree)
    {
        _root = Copy(tree._root);
    }

    Node* Copy(Node* root)
    {
        if(root == nullptr)
            return nullptr;
        Node* tmp = new Node;
        tmp->_key = root->_key;
        tmp->_left = Copy(root->_left);
        tmp->_right = Copy(root->_right);
        return tmp;
    }

    BSTree& operator=(const BSTree& tree)
    {
        if(this != &tree){
            Destroy(this->_root);
            this->_root = Copy(tree._root);
        }
        return *this;
    }

    bool Insert(const T& key)
    {
        if(_root == nullptr)
        {
            _root = new Node(key);
            return true;
        }

        // 查找要插入的位置
        Node* cur = _root;
        Node* parent = nullptr;
        while(cur)
        {
            parent = cur;
            if(key < cur->_key)
            {
                cur = cur->_left;
            }
            else if(key > cur->_key)
            {
                cur = cur->_right;
            }
            else{
                return false;
            }
        }

        // 插入元素
        cur = new Node(key);
        if(key < parent->_key)
        {
            parent->_left = cur;
        }
        else{
            parent->_right = cur;
        }
        return true;
    }

    Node* Find(const T& key)
    {
        Node* cur = _root;
        while(cur)
        {
            if(cur->_key == key)
            {
                return cur;
            }
            else if(key < cur->_key)
            {
                cur = cur->_left;
            }
            else{
                cur = cur->_right;
            }
        }
        return nullptr;
    }

    bool Erase(const T& key)
    {
        if(_root == nullptr)
            return false;

        Node* cur = _root;
        Node* parent = nullptr;
        while(cur)
        {
            if(key == cur->_key)
            {
                break;
            }else if(key < cur->_key)
            {
                parent = cur;
                cur = cur->_left;
            }else{
                parent = cur;
                cur = cur->_right;
            }
        }

        //遍历了整棵树，如果key不在树中，无法删除
        if(cur == nullptr)
            return false;

        //如果在树中找到了key，进行删除结点,要分三种情况：
		//1.该结点只有右孩子
		//2.该结点只有左孩子
		//3.该结点左右子树都存在
		if(cur->_left == nullptr)
		{
            //情况1：
			//只有根结点和根的右孩子，此时要删除的结点正好是树的根
            if(cur == _root)
            {
                _root = cur->_right;
            }else{
                if(cur == parent->_left)
                {
                    parent->_left = cur->_right;
                }else{
                    parent->_right = cur->_right;
                }
            }
		}
		else if(cur->_right == nullptr)
        {
            if(cur == _root){
                _root = cur->_left;
            }else{
                if(cur == parent->_right){
                    parent->_right = cur->_left;
                }else{
                    parent->_left = cur->_left;
                }
            }
        }
        else{
                //当前结点左右孩子都存在，直接删除不好删，可以在其子树中找一个替代结点，比如找其左子树中的最大结点，即左子树中最右侧的结点，或者找其右子树中最小的结点，即右子树中最小的结点。替换结点找到后，将替代结点中的值交给待删除结点，转换成删除替代结点。
				if (cur->_left != nullptr || cur->_right != nullptr)
				{
					//找右子树中最小的结点替换待删除的结点
					Node* repalce = cur->_right;
					parent = cur;
					while (repalce->_left)
					{
						parent = repalce;
						repalce = repalce->_left;
					}
					cur->_key = repalce->_key;
					if (repalce == parent->_left)
					{
						parent->_left = repalce->_right;
					}
					else
					{
						parent->_right = repalce->_right;
					}
					delete repalce;
					repalce = nullptr;
				}
				return true;
        }
        return false;
    }

    void Inorder()
    {
        _Inorder(_root);
    }

private:
    // 中序遍历
    void _Inorder(Node* root)
    {
        if(root)
        {
            _Inorder(root->_left);
            cout << root->_key << " ";
            _Inorder(root->_right);
        }
    }

    void Destroy(Node*& root)
    {
        if(root)
        {
            Destroy(root->_left);
            Destroy(root->_right);
            root = nullptr;
        }
    }

private:
    Node* _root;
};
```


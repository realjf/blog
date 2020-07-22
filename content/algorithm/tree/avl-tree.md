---
title: "平衡二叉树 Avl Tree"
date: 2020-07-22T10:31:57+08:00
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

### 平衡二叉树定义
- 左子树上的所有节点的值都比根节点的值小
- 右子树上的所有节点的值都比根节点的值大
- 左子树与右子树的高度差最大为1
- 二叉树中每棵子树都要求是平衡二叉树

### 平衡二叉树性质
- 高为h的BT, 其结点的数目在2^(h+1)-1和1/2(3^(h+1)−1)之间, 叶的数目在2^h和3^h之间

### 平衡因子
平衡因子：左子树的高度减去右子树的高度，即B = B左 - B右。
由平衡二叉树的定义可知，平衡因子的取值只可能为0，1，-1。

- 0：左右子树等高。
- 1：左子树比较高。
- -1：右子树比较高。

### 平衡二叉树失衡与再平衡
当平衡因子的值大于-1或者大于1时，则该树不再平衡，需要进行再平衡，再平衡通过旋转的方式实现。

再平衡可以通过LL、RR、LR、RL旋转方式进行

#### LL旋转
LL，如下图，我们真实的三个节点为Y > X > Z。然后我们为了方便描述，增加几个虚拟的节点，节点间的大小关系：T1<Z<T2< X <T3<Y<T4
```
    ///////////////////////////////////////////////////
    // LL T1<Z<T2< X <T3<Y<T4                        //
    //        y                              x       //
    //       / \                           /   \     //
    //      x   T4     向右旋转 (y)        z     y    //
    //     / \       - - - - - - - ->    / \   / \   //
    //    z   T3                        T1 T2 T3 T4  //
    //   / \                                         //
    // T1   T2                                       //
    ///////////////////////////////////////////////////
```
对于LL，我们要右旋才能达到再平衡，根据之前描述，我们需要将Y节点顶替T3的位置，问题来了，T3放哪呢？
根据大小关系 X < T3 < Y。我们可以将T3放到Y的左孩子节点的位置，这样进行旋转后得到的结果如上所示。
我们发现这棵树不但达到了再平衡的目的，节点间的大小关系，依然维持了：T1<Z<T2< X <T3<Y<T4的关系。


**代码实现**

```c++
template<class K, class V>
void AVLTree<K, V>::_RotateR(AVLTreeNode<K, V>*& parent)
{
    AVLTreeNode<K, V>* subL = parent->_left;
    AVLTreeNode<K, V>* subLR = subL->_right;
    AVLTreeNode<K, V>* ppNode = parent->_parent;
    // 构建parent子树，将parent和subLR链接起来
    parent->_left = subLR;
    if(subLR) subLR->_parent = parent;
    // 构建subL子树，将subL与parent链接起来
    subL->_right = parent;
    parent->_parent = subL;
    // 将祖先节点与subL链接起来
    if(ppNode == nullptr)
    {
        //如果祖先为Nullptr，说明当前subL节点为根节点
        subL->_parent = nullptr;
        _root = subL;
    }
    else
    {
        subL->_parent = ppNode;
        if(ppNode->_left == parent)
            ppNode->_left = subL;
        else if(ppNode->_right == parent)
            ppNode->_right = subL;
    }

    // 重置平衡因子
    parent->_bf = 0;
    subL->_bf = 0;
    // 更新subL为当前父节点
    parent = subL;
}

```

#### RR旋转
RR, 对于RR我们要进行左旋转才能实现再平衡。同样的，我们如果想通过旋转达到再平衡，AVL树的性质依然是我们实现这个操作的根本。
```
    ////////////////////////////////////////////////
    // RR T1<Y<T2< X <T3<Z<T4                     //
    //    y                             x         //
    //  /  \                          /   \       //
    // T1   x      向左旋转 (y)       y     z      //
    //     / \   - - - - - - - ->   / \   / \     //
    //    T2  z                    T1 T2 T3 T4    //
    //       / \                                  //
    //      T3 T4                                 //
    ////////////////////////////////////////////////
```
节点间的大小关系：T1<Y<T2< X <T3<Z<T4。对于RR我们对Y节点进行左旋转。
即让Y节点顶替T2，然后根据大小关系：Y < X < T2可知，我们可以将T2放到Y的右孩子节点处即可。
对Y节点左旋完了如上图所示的结果。通过比较，节点间的大小关系，依然为：T1<Y<T2< X <T3<Z<T4。
通过对Y节点的左旋转，达到了AVL的再平衡，并维持了AVL的性质不变。

**代码实现**

```c++
template<class K, class V>
void AVLTree<K, V>::_RotateL(AVLTreeNode<K, V>*& parent)
{
    AVLTreeNode<K, V>* subR = parent->_right;
	AVLTreeNode<K, V>* subRL = subR->_left;
	AVLTreeNode<K, V>* ppNode = parent->_parent;		//标记祖先节点

	//1.构建parent子树 链接parent和subRL
	parent->_right = subRL;
	if (subRL) subRL->_parent = parent;
	//2.构建subR子树 链接parent和subR
	subR->_left = parent;
	parent->_parent = subR;
	//3.链接祖先节点和subR节点
	subR->_parent = ppNode;
	if (ppNode== nullptr)
	{//如果祖先节点为nullptr，说明目前的根节点为subR
		_root = subR;
	}
	else
	{	//将祖先节点和subR节点链接起来
		if (parent == ppNode->_left)
			ppNode->_left = subR;
		else
			ppNode->_right = subR;
	}
	//4.重置平衡因子
	parent->_bf = 0;
	subR->_bf = 0;
	//5.更新subR为当前父节点
	parent = subR;
}
```

#### LR旋转
这种情况有点复杂，而且有个很想当然的坑，就是将根节点直接换成x不就完事了？
可是如果我们这么做，发现，x的左节点为z，不满足：左孩子 < 父节点 < 右孩子的大小关系了。
这种情况呢，正确的做法是先将x节点左旋，然后再将y节点右旋。大家通过之前对LL和RR的分析，在脑子中能不能想象到这个画面呢？
```
    //////////////////////////////////////////////////////////////////////////////////////////
    //  LR  T1<X<T2< Z <T3<Y<T4                                                             //
    //         y                                y                              z            //
    //        / \                              / \                           /   \          //
    //       x  t4    向左旋转（x）             z   T4      向右旋转（y）     　x     y         //
    //      / \     --------------->         / \        --------------->   / \   / \        //
    //     T1  z                            x   T3                        T1  T2 T3 T4      //
    //        / \                          / \                                              //
    //       T2  T3                      T1   T2                                            //
    //////////////////////////////////////////////////////////////////////////////////////////
```
对于原始的这棵树呢，大小关系：T1<X<T2< Z <T3<Y<T4。如果我们先不看Y节点，看X，Z，T3节点，是不是可以发现，这正是我们上面描述的RR的情况啊。
对RR，我们上面已经进行了详细的分析，通过对X节点进行左旋，得到中间那棵树。
这时又一个神奇的事情发生了，这棵树的形状又变成了前面我们说的，LL的情况。那大家就清楚了，对Y节点进行右旋转即可。
最终的结果如上第三棵树，达到了AVL的再平衡并依然满足：T1<X<T2< Z <T3<Y<T4。

**代码实现**

```c++
template<class K, class V>
void AVLTree<K, V>::_RotateLR(AVLTreeNode<K, V>*&  parent)
{
	AVLTreeNode<K, V>* pNode = parent;
	AVLTreeNode<K, V>* subL = parent->_left;
	AVLTreeNode<K, V>* subLR = subL->_right;
	int bf = subLR->_bf;

	_RotateL(parent->_left);
	_RotateR(parent);
	
	if (bf == 1)
	{
		pNode->_bf = 0;
		subL->_bf = -1;
	}
	else if (bf == -1)
	{
		pNode->_bf = 1;
		subL->_bf = 0;
	}
	else
	{
		pNode->_bf = 0;
		subL->_bf = 0;
	}

}

```

#### RL旋转
RL,
```
    //////////////////////////////////////////////////////////////////////////////////////////
    // RL: T1<Y<T2< Z <T3<X<T4                                                              //
    //      y                           y                                       z           //
    //     / \                         / \                                    /   \         //
    //    T1  x       向右旋转（x）   　T1  z         向左旋转（y）              y     x        //
    //       / \    - - - - - - ->       / \      - - - - - - - - ->        / \   / \       //
    //      z  T4                       T2  x                              T1 T2 T3 T4      //
    //     / \                             / \                                              //
    //    T2  T3                          T3  T4                                            //
    //////////////////////////////////////////////////////////////////////////////////////////
```
同理，先排除y的影响，x和z构成了LL型，可以先对x进行右旋，然后得到中间的树，通过观察y、z可以看出属于RR型，所以可以
对y进行左旋，然后得到右边的树，
最终的结果如上第三棵树，达到了AVL的再平衡并依然满足：T1<Y<T2< Z <T3<X<T4。

**代码实现**

```c++
template<class K, class V>
void AVLTree<K, V>::_RotateRL(AVLTreeNode<K, V>*&  parent)
{
	AVLTreeNode<K, V>* pNode = parent;
	AVLTreeNode<K, V>* subR = parent->_right;
	AVLTreeNode<K, V>* subRL = subR->_left;
	int bf = subRL->_bf;

	_RotateR(parent->_right);
	_RotateL(parent);

	if (bf == 1)
	{
		pNode->_bf = 0;
		subR->_bf = -1;
	}
	else if (bf == -1)
	{
		pNode->_bf = 1;
		subR->_bf = 0;
	}
	else
	{
		pNode->_bf = 0;
		subR->_bf = 0;
	}
} 

```


### 平衡二叉树完整代码实现
```c++
#pragma once

#include <iostream>
using namespace std;

template<class K, class V>
struct AVLTreeNode
{
    K _key;
    V _value;
    int _bf; // 平衡因子
    AVLTreeNode<K, V>* _parent;
    AVLTreeNode<K, V>* _left;
    AVLTreeNode<K, V>* _right;

    AVLTreeNode(const K& key = K(), const V& value = V())
    : _key(key)
    , _value(value)
    , _bf(0)
    , _parent(nullptr)
    , _left(nullptr)
    , _right(nullptr)
    {}

};

template<class K, class V>
class AVLTree
{
public:
    AVLTree() : _root(nullptr)
    {}

    bool Insert(const K& key, const V& value);
    void InOrder()
    {
        _InOrder(_root);
        cout << endl;
    }

    bool IsBalance()
    {
        return _IsBalance(_root);
    }

    int Height()
    {
        return _Height(_root);
    }

private:
    void _RotateR(AVLTreeNode<K, V>*&  parent);
	void _RotateL(AVLTreeNode<K, V>*&  parent);
	void _RotateLR(AVLTreeNode<K, V>*&  parent);
	void _RotateRL(AVLTreeNode<K, V>*&  parent);
	void _InOrder(AVLTreeNode<K, V>* root);
	bool _IsBalance(AVLTreeNode<K, V>* root);
	int _Height(AVLTreeNode<K, V>* root);

private:
    AVLTreeNode<K, V>* _root; // 根节点
};

template<class K, class V>
bool AVLTree<K, V>::Insert(const K& key, const V& value)
{
    // 空树
    if(_root == nullptr)
    {
        _root = new AVLTreeNode<K, V>(key, value);
        return true;
    }

    // avl树不为nullptr
    AVLTreeNode<K, V>* parent = nullptr;
    AVLTreeNode<K, V>* cur = _root;
    // 找到数据插入位置
    while(cur)
    {
        if(cur->_key < key)
        {
            parent = cur;
            cur = cur->_right;
        }
        else if(cur->_key > key)
        {
            parent = cur;
            cur = cur->_left;
        }
        else
        {
            return false;
        }
        
    }

    // 插入数据
    cur = new AVLTreeNode<K, V>(key, value);
    cur->_parent = parent;
    if(parent->_key > key)
        parent->_left = cur;
    else
        parent->_right = cur;
    
    while(parent)
    {
        // 更新平衡因子
        if(cur == parent->_left)
            parent->_bf--;
        else if(cur == parent->_right)
            parent->_bf++;

        // 检验平衡因子是否合法
        if(parent->_bf == 0)
            break;
        else if(parent->_bf == -1 || parent->_bf == 1)
        {
            // 回溯上升，更新祖父节点的平衡因子并检测合法性
            cur = parent;
            parent = cur->_parent;
        }
        else
        {
            // 平衡因子不合法，需要进行旋转 降低高度
            if(parent->_bf == 2)
            {
                if(cur->_bf == 1)
                    _RotateL(parent);
                else
                    _RotateRL(parent);
            }
            else if(parent->_bf == -2)
            {
                if(cur->_bf == -1)
                    _RotateR(parent);
                else
                    _RotateLR(parent);
            }
            break;
        }
        
    }
}

// 右旋
template<class K, class V>
void AVLTree<K, V>::_RotateR(AVLTreeNode<K, V>*& parent)
{
    AVLTreeNode<K, V>* subL = parent->_left;
    AVLTreeNode<K, V>* subLR = subL->_right;
    AVLTreeNode<K, V>* ppNode = parent->_parent;
    // 构建parent子树，将parent和subLR链接起来
    parent->_left = subLR;
    if(subLR) subLR->_parent = parent;
    // 构建subL子树，将subL与parent链接起来
    subL->_right = parent;
    parent->_parent = subL;
    // 将祖先节点与subL链接起来
    if(ppNode == nullptr)
    {
        //如果祖先为Nullptr，说明当前subL节点为根节点
        subL->_parent = nullptr;
        _root = subL;
    }
    else
    {
        subL->_parent = ppNode;
        if(ppNode->_left == parent)
            ppNode->_left = subL;
        else if(ppNode->_right == parent)
            ppNode->_right = subL;
    }

    // 重置平衡因子
    parent->_bf = 0;
    subL->_bf = 0;
    // 更新subL为当前父节点
    parent = subL;
}

// 左旋
template<class K, class V>
void AVLTree<K, V>::_RotateL(AVLTreeNode<K, V>*& parent)
{
    AVLTreeNode<K, V>* subR = parent->_right;
	AVLTreeNode<K, V>* subRL = subR->_left;
	AVLTreeNode<K, V>* ppNode = parent->_parent;		//标记祖先节点

	//1.构建parent子树 链接parent和subRL
	parent->_right = subRL;
	if (subRL) subRL->_parent = parent;
	//2.构建subR子树 链接parent和subR
	subR->_left = parent;
	parent->_parent = subR;
	//3.链接祖先节点和subR节点
	subR->_parent = ppNode;
	if (ppNode== nullptr)
	{//如果祖先节点为nullptr，说明目前的根节点为subR
		_root = subR;
	}
	else
	{	//将祖先节点和subR节点链接起来
		if (parent == ppNode->_left)
			ppNode->_left = subR;
		else
			ppNode->_right = subR;
	}
	//4.重置平衡因子
	parent->_bf = 0;
	subR->_bf = 0;
	//5.更新subR为当前父节点
	parent = subR;
}

//左右双旋
template<class K, class V>
void AVLTree<K, V>::_RotateLR(AVLTreeNode<K, V>*&  parent)
{
	AVLTreeNode<K, V>* pNode = parent;
	AVLTreeNode<K, V>* subL = parent->_left;
	AVLTreeNode<K, V>* subLR = subL->_right;
	int bf = subLR->_bf;

	_RotateL(parent->_left);
	_RotateR(parent);
	
	if (bf == 1)
	{
		pNode->_bf = 0;
		subL->_bf = -1;
	}
	else if (bf == -1)
	{
		pNode->_bf = 1;
		subL->_bf = 0;
	}
	else
	{
		pNode->_bf = 0;
		subL->_bf = 0;
	}

}

//右左双旋
template<class K, class V>
void AVLTree<K, V>::_RotateRL(AVLTreeNode<K, V>*&  parent)
{
	AVLTreeNode<K, V>* pNode = parent;
	AVLTreeNode<K, V>* subR = parent->_right;
	AVLTreeNode<K, V>* subRL = subR->_left;
	int bf = subRL->_bf;

	_RotateR(parent->_right);
	_RotateL(parent);

	if (bf == 1)
	{
		pNode->_bf = 0;
		subR->_bf = -1;
	}
	else if (bf == -1)
	{
		pNode->_bf = 1;
		subR->_bf = 0;
	}
	else
	{
		pNode->_bf = 0;
		subR->_bf = 0;
	}
}

//中序打印
template<class K, class V>
void AVLTree<K, V>::_InOrder(AVLTreeNode<K, V>* root)
{
	if (root == nullptr)
		return;
	_InOrder(root->_left);
	cout << root->_key << " ";
	_InOrder(root->_right);
}

//求AVL树的高度
template<class K, class V>
int AVLTree<K, V>::_Height(AVLTreeNode<K, V>* root)
{
	if (root == nullptr)
		return 0;

	int high = 0;
	int left = _Height(root->_left);
	int right = _Height(root->_right);

	if (left > right)
		high = left;
	else
		high = right;

	if (root != _root)
        return 1 + high;
	else
		return high;
}

//检验AVL树是否失衡
template<class K, class V>
bool AVLTree<K, V>::_IsBalance(AVLTreeNode<K, V>* root)
{
	if (root == nullptr)
		return true;
	int bf = _Height(root->_right) - _Height(root->_left);
	if (root->_bf != bf)
	{	
		cout << root->_key << endl;
		return false;
	}
	//bf的绝对值小于2，并且左树和右树都平衡则以root为根的子树才处于平衡状态
	return abs(bf) < 2 && _IsBalance(root->_left) && _IsBalance(root->_right);
}

```
---
title: "topk问题golang实现 Topk Golang"
date: 2021-03-26T16:40:24+08:00
keywords: ["algorithm"]
categories: ["algorithm"]
tags: ["algorithm"]
series: [""]
draft: true
toc: false
related:
  threshold: 50
  includeNewer: true
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


```golang
package main 

import (
	"fmt"
)

// 方法一：堆排序 O(NlogK)
// 小顶堆（特点：只找到topk，不排序topk）
func topk_minHeap(nums []int, k int) []int {
	length := len(nums)
	// 数组长度小于k，直接返回
	if length < k {
		return nums
	}

	// 数组前k个数据取出，并生成小顶堆
	minHeap := make([]int, 0)
	minHeap = append(minHeap, nums[:k]...)
	CreateMinHeap(minHeap)

	// 遍历数组剩余数据，大于堆顶数据时，替换堆顶，重新维护小顶堆
	for i := k; i < length; i++ {
		if nums[i] > minHeap[0] {
			minHeap[0] = nums[i]
			minHeapify(minHeap, 0, k)
		}
	}

	return minHeap
}

// 自底向上创建小顶堆
func CreateMinHeap(nums []int) {
	length := len(nums)
	for i := length - 1; i >= 0; i-- {
		minHeapify(nums, i, length)
	}
}

// 维护小顶堆
func minHeapify(nums []int, posIndex, length int) {
	// 堆左孩子节点索引
	leftIndex := 2 * posIndex + 1
	// 堆右孩子节点索引
	rightIndex := 2 * posIndex + 2
	// 当前节点以及左右孩子节点中最小值的索引，初始化为当前节点索引
	minIndex  := posIndex
	// 左孩子存在并且小于当前节点值时，最小值索引替换为左孩子索引
	if leftIndex < length && nums[leftIndex] < nums[minIndex] {
		minIndex = leftIndex
	}
	// 右孩子存在并且小于当前节点值时，最小值索引替换为右孩子索引
	if rightIndex < length && nums[rightIndex] < nums[minIndex] {
		minIndex = rightIndex
	}
	// 最小值节点索引不等于当前节点时，替换当前节点和其中较小孩子节点值
	if minIndex != posIndex {
		nums[posIndex], nums[minIndex] = nums[minIndex], nums[posIndex]
		minHeapify(nums, minIndex, length)
	}
}


// 方法二：快排 O(N)
func topk_quickSort(nums []int, k int) []int {
	length := len(nums)
	/// 数组长度小于k，直接返回
	if length < k {
		return nums
	}

	// 数组进行快排，左侧边界
	left := 0
	// 数据进行快排，右侧边界
	right := length
	// 第一次快排后，获取分界点index
	pivotIndex := partition(nums, left, right)

	// 循环快排，找到分界点index刚好等于k
	for pivotIndex != k {
		if pivotIndex < k {
			// 分界点index小于k，继续对分界点右侧进行快排，重新获取分界点index
			left = pivotIndex + 1
		}else {
			// 分界点index大于k, 缩小快排范围为上次分界点与本次分界点之间数据，重新获取分界点index
			right = pivotIndex
		}
		pivotIndex = partition(nums, left, right)
	}

	return nums[:k]
}

func partition(nums []int, left, right int) int {
	// 初始化分界点为左边界值
	pivot := nums[left]
	// 所有大于分界值的数据边界index
	pos := left

	// 小于分界值时，边界扩展，将数据替换到边界值index位置
	for i := left; i < right; i++ {
		if nums[i] > pivot {
			pos++
			nums[i], nums[pos] = nums[pos], nums[i]
		}
	}

	// 交换分界值的数据边界index和分界点index，使得分界点左侧均大于边界点，右侧均小于分界点
	nums[pos], nums[left] = nums[left], nums[pos]

	return pos
}


func main() {
	a := []int{5,3,7,1,8,2,9,4,7,2,6,6}
	b := topk_minHeap(a, 5)
	for k, v := range b {
		fmt.Printf("%d => %d\n", k, v)
	}

	fmt.Println();

	c := topk_quickSort(a, 5)
	for k, v := range c {
		fmt.Printf("%d => %d\n", k, v)
	}
}

```


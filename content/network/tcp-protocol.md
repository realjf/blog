---
title: "TCP协议流量控制与拥塞控制详解"
date: 2020-04-23T17:31:45+08:00
keywords: ["tcp", "流量控制", "拥塞控制"]
categories: ["network"]
tags: ["tcp", "流量控制", "拥塞控制"]
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

### TCP的主要特点
- 面向连接的运输层协议
- 可靠交付服务
- 提供全双工通信
- 面向字节流

### 连续ARQ协议
- 连续ARQ协议规定：发送方维持一个发送窗口，每收到一个确认，就把发送窗口向前滑动一个分组的位置。
- 接收方采用累积确认的方式，在收到几个分组后，对按序到达的最后一个分组发送确认。

> MSS最大报文段长度

### 滑动窗口协议
以字节为单位的滑动窗口。每个tcp活动连接的两端都维护一个发送窗口结构和接收窗口结构。tcp以字节为单位维护其窗口结构。
随着时间推移，当接收到返回的数据ack，滑动窗口也随之右移。

每个tcp报文段都包含ack号和窗口通告信息，tcp发送端可以据此调节窗口结构。

### 流量控制
所谓流量控制，就是让发送方的发送速率不要太快，要让接收方来得及接收，利用滑动窗口机制可以很方便在tcp连接上实现对发送方的流量控制。

图例说明下
![流量控制](/image/flow_control.png)


#### TCP报文段发送机制
- 第一种机制是TCP维持一个tcp报文段发送出去
- 第二种机制是由发送方的应用进程指明要求发送报文段
- 第三种机制是发送方的一个计时器期限到了，这时就把当前已有的缓存数据装入报文段发送出去。



### 拥塞控制
#### 拥塞控制原理
所谓拥塞控制就是防止过多的数据注入到网络中，这样就可以使网络中的路由器或链路不致过载。拥塞控制索要做的都有一个前提，
就是网络能够承受现有的网络负荷。拥塞控制是一个全局性的过程，涉及所有的主机、所有的路由器，以及与降低网络传输性能有关的所有因素。

流量控制往往是指点对点通信量的控制。

#### 拥塞控制方法
拥塞控制是一个动态的问题，从大的方面看，可以分为开环控制和闭环控制两种方法。

##### 开环控制
就是在设计网络时事先将有关发生拥塞的因素考虑周到，力求网络在工作时不产生拥塞。
##### 闭环控制
闭环控制基于反馈环路，主要有以下几种措施：

- 监测网络系统以便检测到拥塞在何时、何处发生。
- 把拥塞发生的信息传送到可采取行动的地方
- 调整网络系统的运行以解决出现的问题

#### 拥塞控制的算法
tcp进行拥塞控制的算法有四种，即慢开始(slow-start)、拥塞避免(congestion avoidance)、快重传(fast retransmit)和快恢复(fast recovery)

##### 慢开始和拥塞避免
> 发送方让自己的发送窗口等于拥塞窗口
> 判断网络出现拥塞的依据就是出现了超时

**慢开始算法思路**：当主机开始发送数据时，由于并不清楚网络的负荷情况，所以如果立即把大量数据字节注入到网络，那么就有可能引起网络发生拥塞。
经验证明，较好的方法是先探测一下，即由小到大逐渐增大发送窗口，也就是说，由小到大逐渐增大拥塞窗口数值。

RFC5681规定初始拥塞窗口cwnd设置为不超过2至4个SMSS（最大报文段）的数值，具体如下：

- 若SMSS>2190字节，则设置初始拥塞窗口cwnd=2xSMSS字节，且不得超过2个报文段。
- 若SMSS>1095且SMSS<=2190字节，则设置初始拥塞窗口cwnd=3xSMSS字节，且不得超过3个报文段。
- 若SMSS<=1095字节，则设置初始拥塞窗口cwnd=4xSMSS字节，且不得超过4个报文段。

慢开始规定：在每收到一个对新的报文段的确认后，可以把拥塞窗口增加最多一个SMSS的数值。即

拥塞窗口cwnd每次的增加量 = min(N,SMSS)

这里使用报文段的个数作为窗口大小的单位，来阐述拥塞控制原理

![拥塞控制原理](/image/slow_start.png)

> 因此，使用慢开始算法后，每经过一个传输轮次，拥塞窗口cwnd就加倍。

为了防止拥塞窗口cwnd增长过大引起网络拥塞，还需要设置一个慢开始门限ssthresh状态变量。慢开始门限ssthresh用法如下：

- 当cwnd<ssthresh时，使用上述慢开始算法
- 当cwnd>ssthresh时，停止使用慢开始算法，改用拥塞避免算法
- 当cwnd=ssthresh时，既可以使用慢开始算法，也可以使用拥塞避免算法。


**拥塞避免算法的思路**：让拥塞窗口cwnd缓慢增大，即每经过一个往返时间RTT就把发送方的拥塞窗口cwnd加1，而不是像慢开始开始阶段那样加倍增长。
因此在拥塞避免阶段就有加法增大的特点。这表明在拥塞避免阶段，拥塞窗口cwnd按线性规律缓慢增长，比慢开始算法的拥塞窗口增长速率缓慢得多。

下图为拥塞窗口cwnd在拥塞控制时的变化情况
![拥塞控制变化情况](/image/congestion_avoidance.png)

- 当拥塞窗口cwnd=24时，网络出现超时（图中点2），发送方判断为网络拥塞，于是调整门限值ssthresh=cwnd/2=12，同时设置拥塞窗口cwnd=1，进入慢开始阶段
- 按照慢开始算法，发送方接收到一对新报文段的确认ack，就把拥塞窗口值加1，当拥塞窗口cwnd=ssthresh=12时（图中点3），改为执行拥塞避免算法，拥塞窗口按线性增大。
- 当拥塞窗口cwnd=16时（图中点4），出现了一个新情况，就是发送方一连收到3个对同一个报文段的重复确认。
> 这个问题的解释是，有时，个别报文段会在网络中丢失，但实际上网络并未发生拥塞，如果发送方迟迟收不到确认，就会产生超时，就会误认为网络发生了拥塞。
> 这就导致发送方错误地启动慢开始，把拥塞窗口cwnd又设置为1，因而减低了传输效率。采用快重传可以让发送方尽早知道发生了个别报文段的丢失。
- 在图中点4，发送方知道现在只是丢失了个别的报文段，于是不启动慢开始，而是执行**快恢复**算法，这时，发送方调整门限值ssthresh=cwnd/2=8，同时设置拥塞窗口cwnd=ssthresh=8（图中点5），并开始执行拥塞避免算法。


**快重传**要求接收方在收到一个失序的报文段后就立即发出重复确认（为的是使发送方及早知道有报文段没有到达对方）而不要等到自己发送数据时捎带确认。

![快重传](/image/fast_retransmit.png)

**快重传算法**规定：发送方只要一连收到三个重复确认就应当立即重传对方尚未收到的报文段，而不必继续等待设置的重传计时器时间到期

整个拥塞控制算法图如下
![拥塞控制](/image/tcp_congestion_control.jpg)

### 主动队列管理AQM与随机早期检测RED
上面讨论的都是tcp拥塞控制并没有结合网络层的策略。

网络层的策略对tcp拥塞控制影响最大的就是路由器的分组丢弃策略。

在最简单的情况下，路由器的队列都是按照先进先出的规则处理的，但是队列总是有限，因此，当队列满时，以后再有到达的所有分组都将被丢弃，这叫尾部丢弃策略。

这样就会导致分组丢失，发送方认为网络产生拥塞。更为严重的是网络中存在很多的TCP连接，这些连接中的报文段通常是复用路由路径。若发生路由器的尾部丢弃，可能影响到很多条TCP连接，结果就是这许多的TCP连接在同一时间进入慢开始状态。
这在术语中称为**全局同步**。全局同步会使得网络的通信量突然下降很多，而在网络恢复正常之后，其通信量又突然增大很多。


为了避免发生网络中的全局同步现象，引入了主动队列管理AQM，AQM可以有不同实现方法，比较流行的有随机早期检测RED。

使路由器的队列维持两个参数，即队列长队最小门限min和最大门限max，每当一个分组到达的时候，RED就计算平均队列长度。然后分情况对待到来的分组：

- 若平均队列长度小于最小门限，则把新到达的分组放入队列排队。
- 若平均队列长度在最小门限与最大门限之间，则按照某一概率将分组丢弃。
- 若平均队列长度超过最大门限,则把新到达的分组丢弃。






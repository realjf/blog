---
title: "K8s Operator"
date: 2023-03-25T00:38:38+08:00
keywords: ["k8s"]
categories: ["k8s"]
tags: ["k8s"]
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

### 比较流行的k8s operator 工具集

- redhat Operator Framework [https://github.com/operator-framework](https://github.com/operator-framework)
- Kubebuilder [https://github.com/kubernetes-sigs/kubebuilder](https://github.com/kubernetes-sigs/kubebuilder) [https://book.kubebuilder.io/](https://book.kubebuilder.io/)
- Kopf [https://github.com/zalando-incubator/kopf](https://github.com/zalando-incubator/kopf)

本次使用kubebuilder进行operator开发

### 实验环境

- Debian 10 64-bit
- go v1.19.0
- docker v20.10.21
- kubectl v1.26
- kubernetes

### 安装kubectl

```sh
# 下载最新二进制安装包
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# 验证包哈希值
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# 如果输出如下标识验证通过
kubectl: OK

# 安装
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 测试
kubectl version --client --output=yaml
```

### 安装minikube和kubernetes

minikube文档<https://minikube.sigs.k8s.io/docs/start/>

```sh
# 安装minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 启动k8s集群
minikube start

# 停止集群
minikube stop

# 删除所有minikube集群信息
minikube delete --all
```

### 安装docker

具体可以查看<https://docs.docker.com/engine/install/>

### 安装kubebuilder

```sh
# download kubebuilder and install locally.
curl -L -o kubebuilder https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)
chmod +x kubebuilder && mv kubebuilder /usr/local/bin/

```

### 创建项目

```sh
# 创建项目目录
mkdir <YOUR_PROJECT_NAME>
cd <YOUR_PROJECT_NAME>

# create project
kubebuilder init --plugins go/v3 --domain <YOUR_DOMAIN> --owner "realjf" --repo github.com/<YOUR_ACCOUNT>/<YOUR_PROJECT_NAME>

Writing kustomize manifests for you to edit...
Writing scaffold for you to edit...
Get controller runtime:
$ go get sigs.k8s.io/controller-runtime@v0.14.1
Update dependencies:
$ go mod tidy
Next: define a resource with:
$ kubebuilder create api
```

其中生成的文件中：

- go.mod 已经引入了依赖库
- Makefile 构建targets用于构建和部署
- PROJECT 用于搭建新组件的 Kubebuilder 元数据
- config 主要是一些启动配置和RBAC配置，还有CRD，Webhook配置等

main.go文件中：

```go
var (
 scheme   = runtime.NewScheme()
 setupLog = ctrl.Log.WithName("setup")
)

func init() {
 utilruntime.Must(clientgoscheme.AddToScheme(scheme))

 //+kubebuilder:scaffold:scheme
}
```

每一组控制器都需要一个Scheme，它提供Kinds和它们对应的Go类型之间的映射。

修改以下结构：

```go
var namespaces []string // list of namespaces

mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
  Scheme:                 scheme,
  NewCache:               cache.MultiNamespacedCacheBuilder(namespaces),
  MetricsBindAddress:     metricsAddr,
  Port:                   9443,
  HealthProbeBindAddress: probeAddr,
  LeaderElection:         enableLeaderElection,
  LeaderElectionID:       "3ee42630.realjf.io",
  // LeaderElectionReleaseOnCancel defines if the leader should step down voluntarily
  // when the Manager ends. This requires the binary to immediately end when the
  // Manager is stopped, otherwise, this setting is unsafe. Setting this significantly
  // speeds up voluntary leader transitions as the new leader don't have to wait
  // LeaseDuration time first.
  //
  // In the default scaffold provided, the program ends immediately after
  // the manager stops, so would be fine to enable this option. However,
  // if you are doing or is intended to do any operation such as perform cleanups
  // after the manager stops then its usage might be unsafe.
  // LeaderElectionReleaseOnCancel: true,
 })
```

### 创建api

这里以实现一个简单的CronJob控制器为例

```sh
kubebuilder create api --group api --version v1alpha1 --kind CronJob

Create Resource [y/n]
y
Create Controller [y/n]
y
Writing kustomize manifests for you to edit...
Writing scaffold for you to edit...
api/v1alpha1/cronjob_types.go
controllers/cronjob_controller.go
Update dependencies:
$ go mod tidy
Running make:
$ make generate
mkdir -p /home/realjf/go/src/k8s-operator/bin
test -s /home/realjf/go/src/k8s-operator/bin/controller-gen && /home/realjf/go/src/k8s-operator/bin/controller-gen --version | grep -q v0.11.1 || \
GOBIN=/home/realjf/go/src/k8s-operator/bin go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.11.1
go: downloading sigs.k8s.io/controller-tools v0.11.1
go: downloading github.com/spf13/cobra v1.6.1
go: downloading golang.org/x/tools v0.4.0
go: downloading github.com/fatih/color v1.13.0
go: downloading github.com/gobuffalo/flect v0.3.0
go: downloading k8s.io/utils v0.0.0-20221107191617-1a15be271d1d
go: downloading golang.org/x/net v0.4.0
go: downloading github.com/mattn/go-colorable v0.1.9
go: downloading golang.org/x/mod v0.7.0
/home/realjf/go/src/k8s-operator/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
Next: implement your new API and generate the manifests (e.g. CRDs,CRs) with:
$ make manifests
```

创建成功，可以看下api/v1alpha1/cronjob_types.go文件，里面是我们以后的类型定义文件都会放这里

kubernetes中，设计API的规则需要遵循：

- 所有序列化的字段都必须是驼峰式
- 还可以使用omitempty标识省略
- 字段可以使用大多数原始类型
- 数字例外：出于兼容api目的，只接受三种数字：int32、int64和resource.Quantity标识小数

首先，让我们看一下我们的规范。正如我们之前讨论的那样，spec 保存了所需的状态，因此我们控制器的任何“输入”都在这里

CronJob需要以下部分：

- 一个时间表
- 要运行的作业的目标
- 开始工作的截止日期
- 如果同时运行多个作业怎么办
- 一个暂停CronJob运行的方法
- 对旧工作历史的限制

我们将使用多个标记（// +comment）来指定额外的元数据。这些将在生成我们的 CRD 清单时由控制器工具使用。正如我们稍后将看到的，控制器工具也将使用 GoDoc 来形成字段的描述。

> 那个小小的 +kubebuilder:object:root 注释被称为标记。稍后我们会看到更多，但要知道它们充当额外的元数据，告诉控制器工具（我们的代码和 YAML 生成器）额外信息。这个特定的类型告诉对象生成器这个类型代表一个种类。然后，对象生成器为我们生成runtime.Object接口的实现，这是所有表示Kinds的类型必须实现的标准接口。

```go
//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
```

### 设计api

打开api/v1alpha1/cronjob_types.go文件，做以下修改

```go

import (
 apiv1alpha1 "k8s.io/api/batch/v1"
 corev1 "k8s.io/api/core/v1"
 metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

```

然后修改CronJobSpec和CronJobStatus

```go
// CronJobSpec defines the desired state of CronJob
type CronJobSpec struct {
 //+kubebuilder:validation:MinLength=0

 // The schedule in Cron format
 Schedule string `json:"schedule"`

 //+kubebuilder:validation:Minimum=0

 // Optional deadline in seconds for starting the job if it misses scheduled
 // time for any reason
 // +optional
 StartingDeadlineSeconds *int64 `json:"startingDeadlineSeconds,omitempty"`

 // Specifies how to treat concurrent executions of a Job
 // Valid values are:
 // - "Allow" (default): allows CronJobs to run concurrently
 // - "Forbid": forbids concurrent runs, skipping next run if previous run hasn't finished yes
 // - "Replace": cancels currently running job and replaces it with a new one
 // +optional
 ConcurrencyPolicy ConcurrencyPolicy `json:"concurrencyPolicy,omitempty"`

 // This flag tells the controller to suspend subsequent executions, it does
 // not apply to already started executions. Defaults to false.
 // +optional
 Suspend *bool `json:"suspend,omitempty"`

 // Specifies the job that will be created when executing a CronJob
 JobTemplate apiv1alpha1.JobTemplateSpec `json:"jobTemplate"`

 //+kubebuilder:validation:Minimum=0

 // The number of successful finished jobs to retain.
 // This is a pointer to distinguish between explicit zero and not specified.
 // +optional
 SuccessfulJobsHistoryLimit *int32 `json:"successfulJobsHistoryLimit,omitempty"`

 //+kubebuilder:validation:Minimum=0

 // The number of failed finished jobs to retain.
 // This is a pointer to distinguish between explicit zero and not specified.
 // +optional
 FailedJobsHistoryLimit *int32 `json:"failedJobsHistoryLimit,omitempty"`
}
```

自定义了一个类型保存并发策略

```go
type ConcurrencyPolicy string

const (
 // AllowConcurrent allows CronJobs to run concurrently.
 AllowConcurrent ConcurrencyPolicy = "Allow"

 // ForbidConcurrent forbids concurrent runs, skipping next run if previous
 // hasn't finished yet.
 ForbidConcurrent ConcurrencyPolicy = "Forbid"

 // ReplaceConcurrent cancels currently running job and replaces it with a new one.
 ReplaceConcurrent ConcurrencyPolicy = "Replace"
)
```

接下来，是处理状态，它包含我们希望用户或其他控制者能够轻松获取到任何信息。

```go
// CronJobStatus defines the observed state of CronJob
type CronJobStatus struct {
 // INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
 // Important: Run "make" to regenerate code after modifying this file

 // A list of pointers to currently running jobs
 // +optional
 Active []corev1.ObjectReference `json:"active,omitempty"`

 // Information when was the last time the job was successfully scheduled.
 // +optional
 LastScheduleTime *metav1.Time `json:"lastScheduleTime,omitempty"`
}
```

现在api设计完毕，接下来需要编写一个控制器来实际实现该功能。

题外话：
api目录下有其他两个文件：groupversion_info.go和zz_generated.deepcopy.go

- groupversion_info.go: 包含有关组版本的公共元数据
  - 首先，我们有一些包级别的标记，表示这个包中有 Kubernetes 对象，并且这个包代表组 batch.api.realjf.io。对象生成器使用前者，而 CRD 生成器使用后者为它从该包创建的 CRD 生成正确的元数据。
  - 然后，我们有一些常用的变量来帮助我们设置我们的方案。因为我们需要在我们的控制器中使用这个包中的所有类型，所以有一个方便的方法将所有类型添加到其他一些 Scheme 是有帮助的（和约定）。 SchemeBuilder 使我们很容易做到这一点。
- zz_generated.deepcopy.go: 包含上述 runtime.Object 接口的自动生成实现，它将我们所有的根类型标记为代表 Kinds
  - runtime.Object 接口的核心是一个深拷贝方法，DeepCopyObject。 controller-tools 中的对象生成器还为每个根类型及其所有子类型生成另外两个方便的方法：DeepCopy 和 DeepCopyInto

### 了解控制器

控制器是kubernetes和任何operator的核心。
控制器的工作是确保对于任何给定对象，世界的实际状态（包括集群状态，以及潜在的外部状态，例如为 Kubelet 运行容器或为云提供商运行负载均衡器）与对象中的所需状态相匹配。每个控制器专注于一个根 Kind，但可能与其他 Kind 交互。

在控制器运行时，实现特定种类协调的逻辑称为协调器。协调器采用对象的名称，并返回我们是否需要重试（例如，在出现错误或周期性控制器的情况下，如 Horizo​​ntalPodAutoscaler）

大多数控制器最终都在集群上运行，因此它们需要 RBAC 权限，我们使用 controller-tools RBAC 标记指定这些权限。这些是运行所需的最低权限。随着我们添加更多功能，我们需要重新审视这些。

```go
//+kubebuilder:rbac:groups=api.realjf.io,resources=cronjobs,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=api.realjf.io,resources=cronjobs/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=api.realjf.io,resources=cronjobs/finalizers,verbs=update
```

config/rbac/role.yaml 中的 ClusterRole 清单是通过 controller-gen 使用以下命令从上述标记生成的：

```sh
make manifests
```

Reconcile 实际上为单个命名对象执行协调。我们的请求只有一个名称，但我们可以使用客户端从缓存中获取该对象。
我们返回一个空结果并且没有错误，这向控制器运行时表明我们已经成功地协调了这个对象并且在有一些变化之前不需要重试。
大多数控制器需要一个日志句柄和一个上下文，所以我们在这里设置它们。
上下文用于允许取消请求，以及可能的跟踪之类的事情。它是所有客户端方法的第一个参数。后台上下文只是一个基本上下文，没有任何额外的数据或时间限制。

日志句柄让我们记录。 controller-runtime 通过名为 logr 的库使用结构化日志记录。正如我们很快就会看到的，日志记录通过将键值对附加到静态消息来工作。我们可以在协调方法的顶部预先分配一些对，以将它们附加到此协调器中的所有日志行。

```go
func (r *CronJobReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
 _ = log.FromContext(ctx)

 // TODO(user): your logic here

 return ctrl.Result{}, nil
}
```

最后，我们将这个协调器添加到管理器中，以便在管理器启动时启动它。 现在，我们只注意到这个调节器在 CronJobs 上运行。稍后，我们将使用它来标记我们也关心相关对象。

```go
func (r *CronJobReconciler) SetupWithManager(mgr ctrl.Manager) error {
 return ctrl.NewControllerManagedBy(mgr).
  For(&apiv1alpha1.CronJob{}).
  Complete(r)
}
```

现在可以开始填写CronJobs的逻辑

### 实现控制器

CronJob 控制器的基本逻辑是这样的：

- 加载命名的 CronJob
- 列出所有活跃的工作，并更新状态
- 根据历史限制清理旧作业
- 检查我们是否被暂停（如果是，不要做任何其他事情）
- 获取下一次预定运行
- 如果按计划运行新作业，没有超过截止日期，并且没有被我们的并发策略阻止
- 当我们看到正在运行的作业（自动完成）或下一次计划运行的时间时重新排队。

实现如下：

```go
import (
    "context"
    "fmt"
    "sort"
    "time"

    "github.com/robfig/cron"
    kbatch "k8s.io/api/batch/v1"
    corev1 "k8s.io/api/core/v1"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/apimachinery/pkg/runtime"
    ref "k8s.io/client-go/tools/reference"
    ctrl "sigs.k8s.io/controller-runtime"
    "sigs.k8s.io/controller-runtime/pkg/client"
    "sigs.k8s.io/controller-runtime/pkg/log"

    apiv1alpha1 "github.com/realjf/k8s-operator/api/v1alpha1"
)
```

接下来，我们需要一个时钟，它允许我们在测试中伪造计时

```go
// CronJobReconciler reconciles a CronJob object
type CronJobReconciler struct {
    client.Client
    Scheme *runtime.Scheme
    Clock
}
```

我们将模拟时钟，以便在测试时更容易及时跳转，“真实”时钟只是调用 time.Now。

```go
type realClock struct{}

func (_ realClock) Now() time.Time { return time.Now() }

// clock knows how to get the current time.
// It can be used to fake out timing for testing.
type Clock interface {
    Now() time.Time
}
```

这里需要更多的 RBAC 权限——因为我们现在正在创建和管理作业，所以我们需要这些权限，这意味着要添加更多的标记。

```go
//+kubebuilder:rbac:groups=api.realjf.io,resources=cronjobs,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=api.realjf.io,resources=cronjobs/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=api.realjf.io,resources=cronjobs/finalizers,verbs=update
//+kubebuilder:rbac:groups=api,resources=jobs,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=api,resources=jobs/status,verbs=get
```

现在，开始实现控制器核心逻辑——协调器逻辑

```go
var (
 scheduledTimeAnnotation = "api.realjf.io/scheduled-at"
)

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// TODO(user): Modify the Reconcile function to compare the state specified by
// the CronJob object against the actual cluster state, and then
// perform operations to make the cluster state reflect the state specified by
// the user.
//
// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.14.1/pkg/reconcile
func (r *CronJobReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
 log := log.FromContext(ctx)


```

#### 1. 按名称加载CronJob

我们将使用我们的客户端获取 CronJob。所有客户端方法都将上下文（以允许取消）作为它们的第一个参数，并将所讨论的对象作为它们的最后一个。 Get 有点特殊，因为它采用 NamespacedName 作为中间参数（大多数没有中间参数，我们将在下面看到）。
许多客户端方法最后也采用可变参数选项。

```go
    var cronJob apiv1alpha1.CronJob
    if err := r.Get(ctx, req.NamespacedName, &cronJob); err != nil {
        log.Error(err, "unable to fetch CronJob")
        // we'll ignore not-found errors, since they can't be fixed by an immediate
        // requeue (we'll need to wait for a new notification), and we can get them
        // on deleted requests.
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }
```

#### 2. 列出所有活跃的工作，并更新状态

为了完全更新状态，需要列出这个命名空间中属于这个 CronJob 的所有子作业。与 Get 类似，可以使用 List 方法列出子作业。请注意，使用可变选项来设置命名空间和字段匹配（这实际上是在下面设置的索引查找）

```go
var childJobs kbatch.JobList
    if err := r.List(ctx, &childJobs, client.InNamespace(req.Namespace), client.MatchingFields{jobOwnerKey: req.Name}); err != nil {
        log.Error(err, "unable to list child Jobs")
        return ctrl.Result{}, err
    }
```

一旦我们拥有我们拥有的所有job，我们将把它们分成活跃的、成功的和失败的作业，跟踪最近的运行，以便我们可以在状态中记录它。请记住，状态应该能够从世界状态中重构，因此从根对象的状态中读取通常不是一个好主意。相反，您应该在每次运行时重建它。这就是我们在这里要做的。

我们可以使用状态条件检查作业是否“完成”以及它是成功还是失败。我们将把这个逻辑放在一个帮助程序中，以使我们的代码更清晰。

```go
// find the active list of jobs
 var activeJobs []*kbatch.Job
 var successfulJobs []*kbatch.Job
 var failedJobs []*kbatch.Job
 var mostRecentTime *time.Time // find the last run so we can update the status

 isJobFinished := func(job *kbatch.Job) (bool, kbatch.JobConditionType) {
  for _, c := range job.Status.Conditions {
   if (c.Type == kbatch.JobComplete || c.Type == kbatch.JobFailed) && c.Status == corev1.ConditionTrue {
    return true, c.Type
   }
  }

  return false, ""
 }

 getScheduledTimeForJob := func(job *kbatch.Job) (*time.Time, error) {
  timeRaw := job.Annotations[scheduledTimeAnnotation]
  if len(timeRaw) == 0 {
   return nil, nil
  }

  timeParsed, err := time.Parse(time.RFC3339, timeRaw)
  if err != nil {
   return nil, err
  }
  return &timeParsed, nil
 }
 for i, job := range childJobs.Items {
  _, finishedType := isJobFinished(&job)
  switch finishedType {
  case "": // ongoing
   activeJobs = append(activeJobs, &childJobs.Items[i])
  case kbatch.JobFailed:
   failedJobs = append(failedJobs, &childJobs.Items[i])
  case kbatch.JobComplete:
   successfulJobs = append(successfulJobs, &childJobs.Items[i])
  }

  // We'll store the launch time in an annotation, so we'll reconstitute that from
  // the active jobs themselves.
  scheduledTimeForJob, err := getScheduledTimeForJob(&job)
  if err != nil {
   log.Error(err, "unable to parse schedule time for child job", "job", &job)
   continue
  }
  if scheduledTimeForJob != nil {
   if mostRecentTime == nil {
    mostRecentTime = scheduledTimeForJob
   } else if mostRecentTime.Before(*scheduledTimeForJob) {
    mostRecentTime = scheduledTimeForJob
   }
  }
 }

 if mostRecentTime != nil {
  cronJob.Status.LastScheduleTime = &metav1.Time{Time: *mostRecentTime}
 } else {
  cronJob.Status.LastScheduleTime = nil
 }
 cronJob.Status.Active = nil
 for _, activeJob := range activeJobs {
  jobRef, err := ref.GetReference(r.Scheme, activeJob)
  if err != nil {
   log.Error(err, "unable to make reference to active job", "job", activeJob)
   continue
  }
  cronJob.Status.Active = append(cronJob.Status.Active, *jobRef)
 }

log.V(1).Info("job count", "active jobs", len(activeJobs), "successful jobs", len(successfulJobs), "failed jobs", len(failedJobs))

```

使用我们收集的数据，我们将更新我们的 CRD 的状态。就像以前一样，我们使用我们的客户端。为了专门更新状态子资源，我们将使用客户端的 Status 部分和 Update 方法。 status 子资源忽略了对 spec 的更改，因此它不太可能与任何其他更新发生冲突，并且可以具有单独的权限。

```go
if err := r.Status().Update(ctx, &cronJob); err != nil {
        log.Error(err, "unable to update CronJob status")
        return ctrl.Result{}, err
    }
```

一旦我们更新了我们的状态，我们就可以继续确保世界的状态与我们在规范中想要的相匹配

#### 3. 根据历史限制清理旧作业

首先，我们将尝试清理旧工作，这样我们就不会遗留太多工作。

```go
// NB: deleting these are "best effort" -- if we fail on a particular one,
    // we won't requeue just to finish the deleting.
    if cronJob.Spec.FailedJobsHistoryLimit != nil {
        sort.Slice(failedJobs, func(i, j int) bool {
            if failedJobs[i].Status.StartTime == nil {
                return failedJobs[j].Status.StartTime != nil
            }
            return failedJobs[i].Status.StartTime.Before(failedJobs[j].Status.StartTime)
        })
        for i, job := range failedJobs {
            if int32(i) >= int32(len(failedJobs))-*cronJob.Spec.FailedJobsHistoryLimit {
                break
            }
            if err := r.Delete(ctx, job, client.PropagationPolicy(metav1.DeletePropagationBackground)); client.IgnoreNotFound(err) != nil {
                log.Error(err, "unable to delete old failed job", "job", job)
            } else {
                log.V(0).Info("deleted old failed job", "job", job)
            }
        }
    }

    if cronJob.Spec.SuccessfulJobsHistoryLimit != nil {
        sort.Slice(successfulJobs, func(i, j int) bool {
            if successfulJobs[i].Status.StartTime == nil {
                return successfulJobs[j].Status.StartTime != nil
            }
            return successfulJobs[i].Status.StartTime.Before(successfulJobs[j].Status.StartTime)
        })
        for i, job := range successfulJobs {
            if int32(i) >= int32(len(successfulJobs))-*cronJob.Spec.SuccessfulJobsHistoryLimit {
                break
            }
            if err := r.Delete(ctx, job, client.PropagationPolicy(metav1.DeletePropagationBackground)); (err) != nil {
                log.Error(err, "unable to delete old successful job", "job", job)
            } else {
                log.V(0).Info("deleted old successful job", "job", job)
            }
        }
    }
```

#### 4. 检查我们是否被暂停

如果这个对象被挂起，我们不想运行任何作业，所以我们现在就停止。如果我们正在运行的作业出现问题并且我们想暂停运行以调查或使用集群而不删除对象，这将很有用。

```go

if cronJob.Spec.Suspend != nil && *cronJob.Spec.Suspend {
        log.V(1).Info("cronjob suspended, skipping")
        return ctrl.Result{}, nil
    }
```

#### 5. 获取下一次预定运行

如果我们没有暂停，我们将需要计算下一次预定的运行，以及我们是否有尚未处理的运行。

我们将使用我们有用的 cron 库计算下一个预定时间。我们将从上次运行开始计算适当的时间，或者如果找不到上次运行则创建 CronJob。

如果有太多错过的运行并且我们没有设置任何截止日期，我们会保释，这样我们就不会导致控制器重启或楔子出现问题。

否则，我们将只返回错过的运行（其中我们将只使用最新的运行）和下一次运行，这样我们就可以知道什么时候再次协调。

```go
getNextSchedule := func(cronJob *apiv1alpha1.CronJob, now time.Time) (lastMissed time.Time, next time.Time, err error) {
        sched, err := cron.ParseStandard(cronJob.Spec.Schedule)
        if err != nil {
            return time.Time{}, time.Time{}, fmt.Errorf("Unparseable schedule %q: %v", cronJob.Spec.Schedule, err)
        }

        // for optimization purposes, cheat a bit and start from our last observed run time
        // we could reconstitute this here, but there's not much point, since we've
        // just updated it.
        var earliestTime time.Time
        if cronJob.Status.LastScheduleTime != nil {
            earliestTime = cronJob.Status.LastScheduleTime.Time
        } else {
            earliestTime = cronJob.ObjectMeta.CreationTimestamp.Time
        }
        if cronJob.Spec.StartingDeadlineSeconds != nil {
            // controller is not going to schedule anything below this point
            schedulingDeadline := now.Add(-time.Second * time.Duration(*cronJob.Spec.StartingDeadlineSeconds))

            if schedulingDeadline.After(earliestTime) {
                earliestTime = schedulingDeadline
            }
        }
        if earliestTime.After(now) {
            return time.Time{}, sched.Next(now), nil
        }

        starts := 0
        for t := sched.Next(earliestTime); !t.After(now); t = sched.Next(t) {
            lastMissed = t
            // An object might miss several starts. For example, if
            // controller gets wedged on Friday at 5:01pm when everyone has
            // gone home, and someone comes in on Tuesday AM and discovers
            // the problem and restarts the controller, then all the hourly
            // jobs, more than 80 of them for one hourly scheduledJob, should
            // all start running with no further intervention (if the scheduledJob
            // allows concurrency and late starts).
            //
            // However, if there is a bug somewhere, or incorrect clock
            // on controller's server or apiservers (for setting creationTimestamp)
            // then there could be so many missed start times (it could be off
            // by decades or more), that it would eat up all the CPU and memory
            // of this controller. In that case, we want to not try to list
            // all the missed start times.
            starts++
            if starts > 100 {
                // We can't get the most recent times so just return an empty slice
                return time.Time{}, time.Time{}, fmt.Errorf("Too many missed start times (> 100). Set or decrease .spec.startingDeadlineSeconds or check clock skew.")
            }
        }
        return lastMissed, sched.Next(now), nil
    }

    // figure out the next times that we need to create
    // jobs at (or anything we missed).
    missedRun, nextRun, err := getNextSchedule(&cronJob, r.Now())
    if err != nil {
        log.Error(err, "unable to figure out CronJob schedule")
        // we don't really care about requeuing until we get an update that
        // fixes the schedule, so don't return an error
        return ctrl.Result{}, nil
    }
```

我们将准备我们最终的请求以重新排队直到下一个作业，然后确定我们是否真的需要运行

```go
scheduledResult := ctrl.Result{RequeueAfter: nextRun.Sub(r.Now())} // save this so we can re-use it elsewhere
log = log.WithValues("now", r.Now(), "next run", nextRun)
```

#### 6. 如果按计划运行新作业，没有超过截止日期，并且没有被我们的并发策略阻止

如果我们错过了一次运行，而我们仍在截止日期之内开始运行，我们就需要运行一个作业

```go
if missedRun.IsZero() {
        log.V(1).Info("no upcoming scheduled times, sleeping until next")
        return scheduledResult, nil
    }

    // make sure we're not too late to start the run
    log = log.WithValues("current run", missedRun)
    tooLate := false
    if cronJob.Spec.StartingDeadlineSeconds != nil {
        tooLate = missedRun.Add(time.Duration(*cronJob.Spec.StartingDeadlineSeconds) * time.Second).Before(r.Now())
    }
    if tooLate {
        log.V(1).Info("missed starting deadline for last run, sleeping till next")
        // TODO(directxman12): events
        return scheduledResult, nil
    }
```

如果我们真的必须运行一个作业，我们需要等到现有的完成，替换现有的，或者只是添加新的。如果我们的信息由于缓存延迟而过时，我们将在获取最新信息时重新排队。

```go
// figure out how to run this job -- concurrency policy might forbid us from running
    // multiple at the same time...
    if cronJob.Spec.ConcurrencyPolicy == apiv1alpha1.ForbidConcurrent && len(activeJobs) > 0 {
        log.V(1).Info("concurrency policy blocks concurrent runs, skipping", "num active", len(activeJobs))
        return scheduledResult, nil
    }

    // ...or instruct us to replace existing ones...
    if cronJob.Spec.ConcurrencyPolicy == apiv1alpha1.ReplaceConcurrent {
        for _, activeJob := range activeJobs {
            // we don't care if the job was already deleted
            if err := r.Delete(ctx, activeJob, client.PropagationPolicy(metav1.DeletePropagationBackground)); client.IgnoreNotFound(err) != nil {
                log.Error(err, "unable to delete active job", "job", activeJob)
                return ctrl.Result{}, err
            }
        }
    }
```

一旦我们弄清楚如何处理现有的工作，我们实际上就会创造我们想要的工作

我们需要根据我们的 CronJob 模板构建一个作业。我们将从模板中复制规范并复制一些基本的对象元数据。
然后，我们将设置“计划时间”注释，以便我们可以在每次协调时重建我们的 LastScheduleTime 字段。
最后，我们需要设置所有者引用。这允许 Kubernetes 垃圾收集器在我们删除 CronJob 时清理作业，并允许 controller-runtime 在给定作业更改（添加、删除、完成等）时确定需要协调哪个 cronjob。

```go
constructJobForCronJob := func(cronJob *apiv1alpha1.CronJob, scheduledTime time.Time) (*kbatch.Job, error) {
        // We want job names for a given nominal start time to have a deterministic name to avoid the same job being created twice
        name := fmt.Sprintf("%s-%d", cronJob.Name, scheduledTime.Unix())

        job := &kbatch.Job{
            ObjectMeta: metav1.ObjectMeta{
                Labels:      make(map[string]string),
                Annotations: make(map[string]string),
                Name:        name,
                Namespace:   cronJob.Namespace,
            },
            Spec: *cronJob.Spec.JobTemplate.Spec.DeepCopy(),
        }
        for k, v := range cronJob.Spec.JobTemplate.Annotations {
            job.Annotations[k] = v
        }
        job.Annotations[scheduledTimeAnnotation] = scheduledTime.Format(time.RFC3339)
        for k, v := range cronJob.Spec.JobTemplate.Labels {
            job.Labels[k] = v
        }
        if err := ctrl.SetControllerReference(cronJob, job, r.Scheme); err != nil {
            return nil, err
        }

        return job, nil
    }

    // actually make the job...
    job, err := constructJobForCronJob(&cronJob, missedRun)
    if err != nil {
        log.Error(err, "unable to construct job from template")
        // don't bother requeuing until we get a change to the spec
        return scheduledResult, nil
    }

    // ...and create it on the cluster
    if err := r.Create(ctx, job); err != nil {
        log.Error(err, "unable to create Job for CronJob", "job", job)
        return ctrl.Result{}, err
    }

    log.V(1).Info("created Job for CronJob run", "job", job)

```

#### 7. 当我们看到正在运行的作业或下一次计划运行的时间时重新排队

最后，我们将返回我们在上面准备的结果，即我们希望在下一次运行需要发生时重新排队。这被视为最大截止日期——如果中间发生了其他变化，比如我们的工作开始或完成、我们被修改等，我们可能会更快地再次协调。

```go
// we'll requeue once we see the running job, and update our status
    return scheduledResult, nil
}
```

### 编写启动代码

最后，我们将更新我们的设置。为了让我们的核对器能够快速查找其所有者的工作，我们需要一个索引。我们声明一个索引键，稍后我们可以将其作为伪字段名称用于客户端，然后描述如何从 Job 对象中提取索引值。索引器会自动为我们处理命名空间，因此如果作业有 CronJob 所有者，我们只需提取所有者名称。

此外，我们将通知管理器该控制器拥有一些作业，以便它会在作业更改、删除等时自动调用底层 CronJob 上的 Reconcile。

```go
var (
    jobOwnerKey = ".metadata.controller"
    apiGVStr    = apiv1alpha1.GroupVersion.String()
)

func (r *CronJobReconciler) SetupWithManager(mgr ctrl.Manager) error {
    // set up a real clock, since we're not in a test
    if r.Clock == nil {
        r.Clock = realClock{}
    }

    if err := mgr.GetFieldIndexer().IndexField(context.Background(), &kbatch.Job{}, jobOwnerKey, func(rawObj client.Object) []string {
        // grab the job object, extract the owner...
        job := rawObj.(*kbatch.Job)
        owner := metav1.GetControllerOf(job)
        if owner == nil {
            return nil
        }
        // ...make sure it's a CronJob...
        if owner.APIVersion != apiGVStr || owner.Kind != "CronJob" {
            return nil
        }

        // ...and if so, return it
        return []string{owner.Name}
    }); err != nil {
        return err
    }

    return ctrl.NewControllerManagedBy(mgr).
        For(&apiv1alpha1.CronJob{}).
        Owns(&kbatch.Job{}).
        Complete(r)
}
```

现在我们有了一个可以工作的控制器。让我们针对集群进行测试，然后，如果我们没有任何问题，请部署它！

### 实现默认验证webhook

首先在main.go文件中添加如下内容：

```go

if os.Getenv("ENABLE_WEBHOOKS") != "false" {
        if err = (&batchv1.CronJob{}).SetupWebhookWithManager(mgr); err != nil {
            setupLog.Error(err, "unable to create webhook", "webhook", "CronJob")
            os.Exit(1)
        }
    }
    //+kubebuilder:scaffold:builder

    if err := mgr.AddHealthzCheck("healthz", healthz.Ping); err != nil {
  setupLog.Error(err, "unable to set up health check")
  os.Exit(1)
 }
 if err := mgr.AddReadyzCheck("readyz", healthz.Ping); err != nil {
  setupLog.Error(err, "unable to set up ready check")
  os.Exit(1)
 }

 setupLog.Info("starting manager")
 if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
  setupLog.Error(err, "problem running manager")
  os.Exit(1)
 }
```

现在我们可以实现我们的控制器了

### 实施默认/验证 webhook

如果你想为你的 CRD 实现 admission webhooks，你唯一需要做的就是实现 Defaulter 和（或）Validator 接口。

首先，让我们为 CRD (CronJob) 搭建 webhooks 的脚手架。我们需要使用 --defaulting 和 --programmatic-validation 标志运行以下命令（因为我们的测试项目将使用默认和验证 webhooks）：

```sh
kubebuilder create webhook --group api --version v1alpha1 --kind CronJob --defaulting --programmatic-validation

Writing kustomize manifests for you to edit...
Writing scaffold for you to edit...
api/v1alpha1/cronjob_webhook.go
Update dependencies:
$ go mod tidy
Running make:
$ make generate
test -s /home/realjf/go/src/k8s-operator/bin/controller-gen && /home/realjf/go/src/k8s-operator/bin/controller-gen --version | grep -q v0.11.1 || \
GOBIN=/home/realjf/go/src/k8s-operator/bin go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.11.1
/home/realjf/go/src/k8s-operator/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
Next: implement your new Webhook and generate the manifests with:
$ make manifests
```

编辑api/v1alpha1/cronjob_webhook.go文件

```go
import (
    "github.com/robfig/cron"
    apierrors "k8s.io/apimachinery/pkg/api/errors"
    "k8s.io/apimachinery/pkg/runtime"
    "k8s.io/apimachinery/pkg/runtime/schema"
    validationutils "k8s.io/apimachinery/pkg/util/validation"
    "k8s.io/apimachinery/pkg/util/validation/field"
    ctrl "sigs.k8s.io/controller-runtime"
    logf "sigs.k8s.io/controller-runtime/pkg/log"
    "sigs.k8s.io/controller-runtime/pkg/webhook"
)
```

我们将为 webhook 设置一个记录器

```go
var cronjoblog = logf.Log.WithName("cronjob-resource")
```

我们用管理器设置 webhook

```go
func (r *CronJob) SetupWebhookWithManager(mgr ctrl.Manager) error {
 return ctrl.NewWebhookManagedBy(mgr).
  For(r).
  Complete()
}
```

请注意，我们使用 kubebuilder 标记来生成 webhook 清单。这个标记负责生成一个可变的 webhook 清单。 可以在此处找到每个标记的含义。

```go
//+kubebuilder:webhook:path=/mutate-api-realjf-io-v1alpha1-cronjob,mutating=true,failurePolicy=fail,sideEffects=None,groups=api.realjf.io,resources=cronjobs,verbs=create;update,versions=v1alpha1,name=mcronjob.kb.io,admissionReviewVersions=v1

```

我们使用 webhook.Defaulter 接口为我们的 CRD 设置默认值。将自动提供调用此默认设置的 webhook。

 Default 方法预计会改变接收器，设置默认值。

```go
var _ webhook.Defaulter = &CronJob{}

// Default implements webhook.Defaulter so a webhook will be registered for the type
func (r *CronJob) Default() {
    cronjoblog.Info("default", "name", r.Name)

    if r.Spec.ConcurrencyPolicy == "" {
        r.Spec.ConcurrencyPolicy = AllowConcurrent
    }
    if r.Spec.Suspend == nil {
        r.Spec.Suspend = new(bool)
    }
    if r.Spec.SuccessfulJobsHistoryLimit == nil {
        r.Spec.SuccessfulJobsHistoryLimit = new(int32)
        *r.Spec.SuccessfulJobsHistoryLimit = 3
    }
    if r.Spec.FailedJobsHistoryLimit == nil {
        r.Spec.FailedJobsHistoryLimit = new(int32)
        *r.Spec.FailedJobsHistoryLimit = 1
    }
}
```

此标记负责生成验证 webhook 清单

新增了`verbs=create;update;delete,`

```go
//+kubebuilder:webhook:verbs=create;update;delete,path=/validate-api-realjf-io-v1alpha1-cronjob,mutating=false,failurePolicy=fail,sideEffects=None,groups=api.realjf.io,resources=cronjobs,verbs=create;update,versions=v1alpha1,name=vcronjob.kb.io,admissionReviewVersions=v1

```

我们可以在声明式验证之外验证我们的 CRD。通常，声明式验证就足够了，但有时更高级的用例需要复杂的验证。

例如，我们将在下面看到我们使用它来验证格式良好的 cron 计划，而无需组成长正则表达式。

如果实现了 webhook.Validator 接口，将自动提供调用验证的 webhook。 ValidateCreate、ValidateUpdate 和 ValidateDelete 方法应分别在创建、更新和删除时验证其接收者。我们将 ValidateCreate 与 ValidateUpdate 分开，以允许诸如使某些字段不可变的行为，以便它们只能在创建时设置。

ValidateDelete 也与 ValidateUpdate 分开，以允许不同的删除验证行为。然而，在这里，我们只对 ValidateCreate 和 ValidateUpdate 使用相同的共享验证。我们在 ValidateDelete 中什么也不做，因为我们不需要在删除时验证任何内容。

```go
var _ webhook.Validator = &CronJob{}

// ValidateCreate implements webhook.Validator so a webhook will be registered for the type
func (r *CronJob) ValidateCreate() error {
    cronjoblog.Info("validate create", "name", r.Name)

    return r.validateCronJob()
}

// ValidateUpdate implements webhook.Validator so a webhook will be registered for the type
func (r *CronJob) ValidateUpdate(old runtime.Object) error {
    cronjoblog.Info("validate update", "name", r.Name)

    return r.validateCronJob()
}

// ValidateDelete implements webhook.Validator so a webhook will be registered for the type
func (r *CronJob) ValidateDelete() error {
    cronjoblog.Info("validate delete", "name", r.Name)

    // TODO(user): fill in your validation logic upon object deletion.
    return nil
}

```

验证了 CronJob 的名称和规格

```go
func (r *CronJob) validateCronJob() error {
    var allErrs field.ErrorList
    if err := r.validateCronJobName(); err != nil {
        allErrs = append(allErrs, err)
    }
    if err := r.validateCronJobSpec(); err != nil {
        allErrs = append(allErrs, err)
    }
    if len(allErrs) == 0 {
        return nil
    }

    return apierrors.NewInvalid(
        schema.GroupKind{Group: "batch.tutorial.kubebuilder.io", Kind: "CronJob"},
        r.Name, allErrs)
}
```

某些字段由 OpenAPI 架构以声明方式验证。您可以在设计 API 部分找到 kubebuilder 验证标记（以 // +kubebuilder:validation 为前缀）。您可以通过运行 controller-gen crd -w 或在此处找到所有 kubebuilder 支持的用于声明验证的标记

```go
func (r *CronJob) validateCronJobSpec() *field.Error {
    // The field helpers from the kubernetes API machinery help us return nicely
    // structured validation errors.
    return validateScheduleFormat(
        r.Spec.Schedule,
        field.NewPath("spec").Child("schedule"))
}
```

需要验证 cron 计划的格式是否正确。

```go
func validateScheduleFormat(schedule string, fldPath *field.Path) *field.Error {
    if _, err := cron.ParseStandard(schedule); err != nil {
        return field.Invalid(fldPath, schedule, err.Error())
    }
    return nil
}
```

验证字符串字段的长度可以通过验证模式以声明方式完成。 但是 ObjectMeta.Name 字段是在 apimachinery 存储库下的共享包中定义的，因此我们无法使用验证模式以声明方式验证它。

```go
func (r *CronJob) validateCronJobName() *field.Error {
    if len(r.ObjectMeta.Name) > validationutils.DNS1035LabelMaxLength-11 {
        // The job name length is 63 character like all Kubernetes objects
        // (which must fit in a DNS subdomain). The cronjob controller appends
        // a 11-character suffix to the cronjob (`-$TIMESTAMP`) when creating
        // a job. The job name length limit is 63 characters. Therefore cronjob
        // names must have length <= 63-11=52. If we don't validate this here,
        // then job creation will fail later.
        return field.Invalid(field.NewPath("metadata").Child("name"), r.Name, "must be no more than 52 characters")
    }
    return nil
}
```

### 运行和部署控制器

如果选择对 API 定义进行任何更改，则在继续之前，生成 CR 或 CRD 等清单

```sh
make manifests
```

为了测试控制器，我们可以在集群本地运行它。不过，在我们这样做之前，我们需要按照快速入门安装我们的 CRD。如果需要，这将使用控制器工具自动更新 YAML 清单：

```sh
make install
```

在单独的终端中，运行

```sh
export ENABLE_WEBHOOKS=false
make run
```

您应该从控制器中看到有关启动的日志，但它目前还不会执行任何操作。

此时，我们需要一个 CronJob 来进行测试。让我们将示例写入 config/samples/api_v1alpha1_cronjob.yaml，并使用它：

```yaml
apiVersion: api.realjf.io/v1
kind: CronJob
metadata:
  labels:
    app.kubernetes.io/name: cronjob
    app.kubernetes.io/instance: cronjob-sample
    app.kubernetes.io/part-of: project
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/created-by: project
  name: cronjob-sample
spec:
  schedule: "*/1 * * * *"
  startingDeadlineSeconds: 60
  concurrencyPolicy: Allow # explicitly specify, but Allow is also default.
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure

```

```sh
kubectl create -f config/samples/api_v1alpha1_cronjob.yaml

```

此时，您应该会看到一连串的活动。如果你观察变化，你应该看到你的 cronjob 正在运行，并更新状态：

```sh
kubectl get cronjob.api.realjf.io -o yaml
kubectl get job

```

现在我们知道它正在工作，我们可以在集群中运行它。停止 make run 调用，然后运行

```sh
make docker-build docker-push IMG=<some-registry>/<project-name>:tag
make deploy IMG=<some-registry>/<project-name>:tag

```

如果我们像以前一样再次列出 cronjobs，我们应该会看到控制器再次运行！

---
title: "kubesphere devops流水线go项目使用示例 Kubesphere Devops Pipeline"
date: 2022-04-23T21:24:13+08:00
keywords: ["kubesphere"]
categories: ["kubesphere"]
tags: ["kubesphere"]
series: [""]
draft: false
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

### 准备
- 一个已经开启devops插件的kubesphere系统
- 一个go项目代码（在这里项目代码放在码云上）
- 一个阿里云容器镜像仓库账号
  

### 开始
#### 创建devops项目
![create-project.png](/image/kubesphere-devops-create-project.png)

输入项目名称，然后进入项目
![project-dashboard.png](/image/kubesphere-devops-project-dashboard.png)

#### 创建凭证
要让流水线正常运行，需要几个凭证，一个是代码拉取凭证（这里使用码云的访问令牌），一个阿里云容器镜像仓库空间，用于存放镜像，
然后需要一个可以操作kubectl的凭证

##### 创建码云凭证
需要开启几个权限，projects、hook、emails，然后输入描述，提交后会得到token字符串，需要妥善保管好这个字符串，因为只会显示一次，等会创建凭证需要用到这个字符串
![gitee-token](/image/kubesphere-devops-gitee-token.png)

创建码云的凭证
![gitee-voucher](/image/kubesphere-devops-create-gitee-voucher.png)

##### 创建阿里云容器镜像仓库凭证
首先创建命名空间
![namespace](/image/kubesphere-devops-aliyun-namespace.png)

然后创建镜像仓库，仓库名称即项目的名称即可，这里会有一个设置镜像仓库访问密码，密码等会创建凭证的时候要用
![image-registry](/image/kubesphere-devops-aliyun-image-registry.png)

镜像仓库创建完毕，进入镜像仓库，可以看到镜像仓库的基本信息，这公网地址、阿里云账号名称，空间名称，仓库名称后面会用到

现在开始创建凭证
![aliyun-voucher](/image/kubesphere-devops-aliyun-voucher.png)

这里的用户名填写阿里云账号名称，密码填写镜像仓库访问密码

##### 最后再创建当前账号的kubeconfig凭证
![kubeconfig](/image/kubesphere-devops-kubeconfig.png)


#### 创建流水线
凭证创建完毕，可以开始创建流水线了

![create-pipeline-1](/image/kubesphere-devops-create-pipeline-1.png)

这里代码仓库选择git，然后填写项目代码仓库地址，凭证选择码云的凭证
![git-repo](/image/kubesphere-devops-add-git-repo.png)

高级设置基本默认就可以，这里扫描触发器可以选择定时扫描，时间自定就可以
![create-pipeline-2](/image/kubesphere-devops-create-pipeline-2.png)

这里需要注意一下脚本路径这项，路径默认是Jenkinsfile，即在项目代码仓库的根目录下需要有个Jenkinsfile文件

#### 设置jenkins脚本
流水线创建成功后，开始在项目代码根目录下新增一个文件，名字叫Jenkinsfile，内容如下：

```sh
pipeline {  
  agent {
    label 'go'
  }
   
  environment {
    // 镜像仓库的地址
    REGISTRY = ''
    // 镜像仓库空间名
    NAMESPACE = ''
    // 镜像仓库用户名
    DOCKERHUB_CREDENTIAL_USR = ''
    // Docker 镜像名称
    APP_NAME = ''
    // 'dockerhubid' 是您在 KubeSphere 用 Docker Hub 访问令牌创建的凭证 ID
    DOCKERHUB_CREDENTIAL = credentials('')
    // 您在 KubeSphere 创建的 kubeconfig 凭证 ID
    KUBECONFIG_CREDENTIAL_ID = ''
    // 您在 KubeSphere 创建的项目名称，不是 DevOps 项目名称
    PROJECT_NAME = ''
    // gitee 访问令牌 id
    GITEE_CREDENTIAL = credentials('')
    // gitee 用户名
    GITEE_USERNAME = ''
    // 镜像版本
    IMAGE_VERSION = ''
    // git clone 后的目录
    GITCLONE_DIR = ''
    // gitee地址
    GITEE_ADDRESS = 'gitee.com/xxx/xxx.git'
  }
   
  stages {
    stage('docker login') {
      steps{
        container ('go') {
          sh 'echo $DOCKERHUB_CREDENTIAL_PSW | docker login --username=$DOCKERHUB_CREDENTIAL_USR $REGISTRY --password-stdin'
        }
      }
    }
   
    stage('build & push') {
      steps {
        container ('go') {
            // git仓库地址
          sh 'git clone https://$GITEE_USERNAME:$GITEE_CREDENTIAL_PSW@$GITEE_ADDRESS $GITCLONE_DIR'
          sh 'cd bin && docker build -t $REGISTRY/$NAMESPACE/$APP_NAME:$IMAGE_VERSION .'
          sh 'docker push $REGISTRY/$NAMESPACE/$APP_NAME:$IMAGE_VERSION'
        }
      }
    }

    stage ('deploy app') {
      steps {
         container ('go') {
            withCredentials([
              kubeconfigFile(
                credentialsId: env.KUBECONFIG_CREDENTIAL_ID,
                variable: 'KUBECONFIG')
              ]) {
                  // 部署文件目录
              sh 'envsubst < $GITCLONE_DIR/manifest/deploy.yaml | kubectl apply -f -'
            }
         }
      }
    }
  }
}

```

这上面即脚本内容，里面的environment相关变量值需要替换成你自己的

#### 设置阿里云容器镜像仓库保密字典
需要在kubesphere企业项目里的配置中，找到保密字典，创建一个阿里云容器镜像仓库的保密字典
![secret](/image/kubesphere-devops-secret.png)
这里的仓库地址填写你的容器仓库的公网地址加上空间名称，即【公网地址/空间名称】，用户名是阿里云账号名称，密码填写容器仓库访问密码即可，点击验证，验证成功即可创建

#### 设置kubernetes部署文件deploy.yaml
jenkinsfile脚本设置好后，还需要一个deploy.yaml文件，放在项目代码的/manifest/目录下，即/manifest/deploy.yaml，其内容是k8s的deployment的部署文件，用于更新部署您的应用，下面给出deployment的配置项

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: 应用名称
  namespace: kubesphere的项目名称
  labels:
    app: 应用名称
  annotations:
    deployment.kubernetes.io/revision: '3'
    kubesphere.io/creator: cjf
spec:
  replicas: 1
  selector:
    matchLabels:
      app: 应用名称
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: 应用名称
      annotations:
        kubesphere.io/restartedAt: ''
        logging.kubesphere.io/logsidecar-config: '{}'
    spec:
      volumes:
        - name: 挂载卷名称
          configMap:
            name: 配置字典名称
            defaultMode: 420
      containers:
        - name: 容器名称
          image: '阿里云容器镜像完整访问地址，即【公网地址/空间名称/镜像仓库名称:版本】'
          ports:
            - name: http-6666
              containerPort: 6666
              protocol: TCP
          resources: {}
          volumeMounts:
            - name: 挂载卷名称
              readOnly: true
              mountPath: 挂载路径
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: IfNotPresent
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
      serviceAccountName: default
      serviceAccount: default
      securityContext: {}
      imagePullSecrets:
        - name: 这里填写你在kubesphere的项目配置中的保密字典里配置的拉取阿里云容器镜像仓库的镜像的配置名称
      schedulerName: default-scheduler
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600

```

#### 开始运行流水线
创建好这些后，即可回到devops项目里的流水线中

点击更多操作里的扫描仓库，等待几分钟就可以看到流水线开始构建了，因为之前设置了扫描器为定时扫描，所以有项目代码仓库有更新的时候，流水线会自动运行构建并部署应用


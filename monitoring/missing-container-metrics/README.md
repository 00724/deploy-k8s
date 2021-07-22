# prometheus使用missing-container-metrics监控pod

## 1、简介

Kubernetes 默认情况下使用 cAdvisor 来收集容器的各项指标，足以满足大多数人的需求，但还是有所欠缺，比如缺少对以下几个指标的收集：

-   OOM kill
-   容器重启的次数
-   容器的退出码

missing-container-metrics 这个项目弥补了 cAdvisor 的缺陷，新增了以上几个指标，集群管理员可以利用这些指标迅速定位某些故障。例如，假设某个容器有多个子进程，其中某个子进程被 OOM kill，但容器还在运行，如果不对 OOM kill 进行监控，管理员很难对故障进行定位。

## 2、安装

#### 2.1官方提供了helm chart方式来进行安装，我们先添加helm仓库

```shell
helm repo add missing-container-metrics https://draganm.github.io/missing-container-metrics
```

#### 2.2、把这个chart下载到本地，我们需要修改value.yaml文件

```shell
helm pull missing-container-metrics/missing-container-metrics
tar xf  missing-container-metrics-0.1.1.tgz 
```

#### 2.3、可配置项

| Parameter          | Description                                                  | Default                                                      |
| :----------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| image.repository   | 镜像名称                                                     | `dmilhdef/missing-container-metrics`                         |
| image.pullPolicy   | 镜像拉取策略                                                 | `IfNotPresent`                                               |
| image.tag          | 镜像tag                                                      | `v0.21.0`                                                    |
| imagePullSecrets   | 拉取镜像的secret                                             | `[]`                                                         |
| nameOverride       | 覆盖生成的图表名称。默认为 .Chart.Name。                     |                                                              |
| fullnameOverride   | 覆盖生成的版本名称。默认为 .Release.Name。                   |                                                              |
| podAnnotations     | Pod 的Annotations                                            | `{"prometheus.io/scrape": "true", "prometheus.io/port": "3001"}` |
| podSecurityContext | 为 pod 设置安全上下文                                        |                                                              |
| securityContext    | 为 pod 中的容器设置安全上下文                                |                                                              |
| resources          | PU/内存资源请求/限制                                         | `{}`                                                         |
| useDocker          | 从 Docker 获取容器信息,如果容器运行时为docker ,设置为true    | `false`                                                      |
| useContainerd      | 从 Containerd 获取容器信息,如果容器运行时为containers ,设置为true | `true`                                                       |

#### 2.4、我们这里修改`missing-container-metrics/values.yaml`中``useDocker`为`true`，然后安装

```shell
kubectl create namespace missing-container-metrics
helm install missing-container-metrics -n missing-container-metrics .
helm -n missing-container-metrics list
kubectl get pod -n missing-container-metrics 
```



#### 2.5、服务公开了如下的指标：

-   `container_restarts` ：容器的重启次数。
-   `container_ooms` ：容器的 OOM 杀死数。这涵盖了容器 cgroup 中任何进程的 OOM 终止。
-   `container_last_exit_code` ：容器的最后退出代码。

#### 2.6、每一个指标包含如下标签：

-   `docker_container_id`：容器的完整 ID。
-   `container_short_id`：Docker 容器 ID 的前 6 个字节。
-   `container_id`：容器 id 以与 kubernetes pod 指标相同的格式表示 - 以容器运行时为前缀`docker://`并`containerd://`取决于容器运行时。这使得 Prometheus 中的`kube_pod_container_info`指标可以轻松连接。
-   `name`：容器的名称。
-   `image_id`：图像 id 以与 k8s pod 的指标相同的格式表示。这使得 Prometheus 中的`kube_pod_container_info`指标可以轻松连接。
-   `pod`：如果`io.kubernetes.pod.name`在容器上设置了`pod`标签，则其值将设置为指标中的标签
-   `namespace`：如果`io.kubernetes.pod.namespace`容器上设置了`namespace`标签，则其值将设置为指标的标签。

### 3、添加PodMonitor 和 PrometheusRule（针对Prometheus Operator）

#### 3.1、在template目录下创建文件`podmonitor.yaml`

```yaml
{{ if .Values.prometheusOperator.podMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: {{ include "missing-container-metrics.fullname" . }}
  {{- with .Values.prometheusOperator.podMonitor.namespace }}
  namespace: {{ . }}
  {{- end }}
  labels:
    {{- include "missing-container-metrics.labels" . | nindent 4 }}
    {{- with .Values.prometheusOperator.podMonitor.selector }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  selector:
    matchLabels:
      {{- include "missing-container-metrics.selectorLabels" . | nindent 6 }}
  podMetricsEndpoints:
  - port: http
  namespaceSelector:
    matchNames:
      - {{ .Release.Namespace }}
{{ end }}
```

#### 3.2、在template目录下创建文件`prometheusrule.yaml`

```yaml
{{ if .Values.prometheusOperator.prometheusRule.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: {{ include "missing-container-metrics.fullname" . }}
  {{- with .Values.prometheusOperator.prometheusRule.namespace }}
  namespace: {{ . }}
  {{- end }}
  labels:
    {{- include "missing-container-metrics.labels" . | nindent 4 }}
    {{- with .Values.prometheusOperator.prometheusRule.selector }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  groups:
  - name: {{ include "missing-container-metrics.fullname" . }}
    rules:
      {{- toYaml .Values.prometheusOperator.prometheusRule.rules | nindent 6 }}
{{ end }}
```

#### 3.5、修改`value.yaml`,添加如下

```yaml
useDocker: true
useContainerd: false
###添加
prometheusOperator:
  podMonitor:
    # Create a Prometheus Operator PodMonitor resource
    enabled: true
    # Namespace defaults to the Release namespace but can be overridden
    namespace: ""
    # Additional labels to add to the PodMonitor so it matches the Operator's podMonitorSelector
    selector:
      app.kubernetes.io/name: missing-container-metrics

  prometheusRule:
    # Create a Prometheus Operator PrometheusRule resource
    enabled: true
    # Namespace defaults to the Release namespace but can be overridden
    namespace: ""
    # Additional labels to add to the PrometheusRule so it matches the Operator's ruleSelector
    selector:
      prometheus: k8s
      role: alert-rules
    # The rules can be set here. An example is defined here but can be overridden.
    rules:
    - alert: ContainerOOMObserved
      annotations:
        message: A process in this Pod has been OOMKilled due to exceeding the Kubernetes memory limit at least twice in the last 15 minutes. Look at the metrics to determine if a memory limit increase is required.
      expr: sum(increase(container_ooms[15m])) by (exported_namespace, exported_pod) > 2
      labels:
        severity: warning
    - alert: ContainerOOMObserved
      annotations:
        message: A process in this Pod has been OOMKilled due to exceeding the Kubernetes memory limit at least ten times in the last 15 minutes. Look at the metrics to determine if a memory limit increase is required.
      expr: sum(increase(container_ooms[15m])) by (exported_namespace, exported_pod) > 10
      labels:
        severity: critical
```

#### 3.6、使用下面命令更新

```shell
helm upgrade missing-container-metrics -n missing-container-metrics .
```

#### 3.7、更新后会创建podmonitor和prometeusrules

```shell
kubectl get prometheusrules.monitoring.coreos.com  -n monitoring
kubectl get podmonitors.monitoring.coreos.com  -n missing-container-metrics 
```
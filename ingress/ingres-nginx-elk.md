###  1、ingress-nginx挂载一个pv到/data/log持久化目录

#### 1.1 创建pv和pvc

```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    server: 10.4.7.78
    path: /data/volumes
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ingress-pvc
  namespace: ingress-nginx
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

#### 1.2 挂在到ingress-nginx

```yaml
#截取ingress-nginx的dp或ds的yaml中vlumes相关配置
   volumeMounts:
    - mountPath: /data/log/
      name: ingress-nfs

  volumes:
  - name: ingress-nfs
    persistentVolumeClaim:
      claimName: ingress-pvc
```

### 2、配置ingress-nginx的日志格式

```yaml
#将日志文件指定想/data/log中，并指定json格式
#kubectl edit cm -n ingress-nginx ingress-nginx-controller
apiVersion: v1
data:
  access-log-path: /data/log/access_$hostname.log
  error-log-path: /data/log/error.log
  log-format-upstream: '{"time": "$time_iso8601", "remote_addr": "$remote_addr", "x-forward-for":
    "$proxy_add_x_forwarded_for", "remote_user": "$remote_user", "bytes_sent": "$bytes_sent",
    "request_time": "$request_time","status": "$status", "vhost": "$host", "request_proto":
    "$server_protocol", "path": "$uri","request_query": "$args", "request_length":
    "$request_length", "duration": "$request_time","method": "$request_method", "http_referrer":
    "$http_referer", "http_user_agent": "$http_user_agent","upstream_addr": "$upstream_addr",
    "upstream_response_length": "$upstream_response_length","upstream_response_time":
    "$upstream_response_time", "upstream_status": "$upstream_status"}'
    
#在ingress-nginx-controller这个configmap中添加上边的信息即可
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/version: 0.47.0
    helm.sh/chart: ingress-nginx-3.33.0
```

3、配置logstash收集日志

```bash
#logstash的pipelines配置中指定手机nfs上的日志目录
cat /etc/logstash/conf.d/nginx.conf 
input{
    file {
        path => "/data/volumes/access*.log"
        codec => "json"
        type => "ingress-nginx-k8s"
    }
}
filter{
}
output{
    elasticsearch {
        hosts => ["10.4.7.78:9200"]
        index => "ingress-nginx-%{+YYYY.MM.dd}"
    }
}
```

4、kibana展示

![image-20210710152609753](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20210710152609753.png)

![image-20210710152632950](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20210710152632950.png)
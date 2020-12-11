

#ubuntu更换阿里云镜像源
deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse


#禁用防火墙
systemctl stop firewalld && systemctl disable firewalld
#禁用selinux
#临时修改
setenforce 0
#永久修改，重启服务器后生效
sed -i '7s/enforcing/disabled/' /etc/selinux/config

#节点解析
cat >> /etc/hosts <<EOF
10.4.7.71  master
10.4.7.72  node1
10.4.7.73  node2
EOF

#k8s相关优化
cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF
modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf


#安装ipset和ipvsadm(便于查看 ipvs 的代理规则)
apt install ipset ipvsadm -y


#开启内核lvs转发
for mod in `ls /sys/module | grep ip_vs`
do
  modprobe $mod
done

#手动关闭swap
swapoff -a


#安装docker
apt-get update
apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y update
apt-get -y install docker-ce=5:19.03.14~3-0~ubuntu-bionic

cat >>/etc/docker/daemon.json<<EOF
{
      "registry-mirrors": ["https://q2gr04ke.mirror.aliyuncs.com"],
      "exec-opts": ["native.cgroupdriver=systemd"],
      "live-restore": true,
      "log-driver":"json-file",
      "log-opts": {"max-size":"100m", "max-file":"3"}
}
EOF


```
#修改docker Cgroup Driver为systemd
#将/usr/lib/systemd/system/docker.service文件中的这一行 ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
#修改为 ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd
#如果不修改，在添加 worker 节点时可能会碰到如下错误
#[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". 
#Please follow the guide at https://kubernetes.io/docs/setup/cri/

#使用如下命令修改  
sed -i.bak "s#^ExecStart=/usr/bin/dockerd.*#ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd#g" /usr/lib/systemd/system/docker.service
#重启docker
systemctl daemon-reload && systemctl restart docker
```


#安装kubelet kubeadm kubectl
curl http://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
#curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
bash -c 'cat  << EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF'

apt-get install -y kubelet=1.18.6-00 kubeadm=1.18.6-00 kubectl=1.18.6-00


#命令行补全
echo "source <(kubectl completion bash)" >/etc/profile.d/k8s.sh
source /etc/profile.d/k8s.sh

#制作自签名证书
apt install golang-cfssl -y
mkdir /opt/certs -p
cat >/opt/certs/ca-csr.json <<EOF
{
    "CN": "openacl",
    "hosts":[
    ],
    "key": {
        "algo": "rsa",
        "size": 4096
    },
    "names": [
        {
            "C": "CN",
            "ST": "Beijing",
            "L": "Beijing",
            "O": "openacl",
            "OU": "itops"
        }
    ],
    "ca": {
        "expiry": "175200h"
    }
}
EOF


cd /opt/certs
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

mkdir /etc/kubernetes/pki -p
cp /opt/certs/ca.pem /etc/kubernetes/pki/ca.crt
cp /opt/certs/ca-key.pem /etc/kubernetes/pki/ca.key


#初始化配置
cd /root
cat <<EOF > ./kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.18.9      
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers

#master地址
controlPlaneEndpoint: "10.4.7.71:6443"      
networking:
  serviceSubnet: "192.168.0.0/16"        
#k8s容器组所在的网段
  podSubnet: "172.16.0.1/16"        
  dnsDomain: "cluster.local"
EOF


#初始化集群
kubeadm init --config=kubeadm-config.yaml --upload-certs
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config



#安装calico
wget https://docs.projectcalico.org/v3.8/manifests/calico.yaml
kubectl apply -f calico.yaml



#查看证书时间
cd /etc/kubernetes/pki/
openssl x509 -in apiserver.crt -text -noout | grep Not
打标签
kubectl label node ks-node1-72 node-role.kubernetes.io/node=
kubectl label node ks-node2-73 node-role.kubernetes.io/node=



#安装dashboard
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc3/aio/deploy/recommended.yaml
修改为nodeport模式


```
#下载文件  v2.0.0-rc3是中文版本，beta8是英文版本
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc3/aio/deploy/recommended.yaml
#修改Service为NodePort类型
#42行下增加一行
#nodePort: 30001
#44行下增加一行
#type: NodePort

#原先内容
spec:
  ports:
    - port: 443
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard

#修改后内容
spec:
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001   #增加，指定nodeport端口
  selector:
    k8s-app: kubernetes-dashboard
  type: NodePort        #增加，修改类型为nodeport

```

kubectl apply -f kubedashboard.yaml

#更改kube-proxy为ipvs模式
kubectl edit cm kube-proxy -n kube-system

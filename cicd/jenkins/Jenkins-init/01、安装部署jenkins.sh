#1、安装jdk
tar xf openjdk-11.0.2_linux-x64_bin.tar.gz -C /usr/local/src/
ln -s /usr/local/src/jdk-11.0.2/ /usr/local/src/jdk
source /etc/profile.d/jdk.sh
ln -s /usr/local/src/jdk/bin/* /usr/bin/

cat >/etc/profile.d/jdk.sh <<EOF
JAVA_HOME=/usr/local/src/jdk
CLASSPATH=\$JAVA_HOME/lib
PATH=\$JAVA_HOME/bin:\$PATH
export PATH JAVA_HOME CLASSPATH
EOF

source  /etc/profile.d/jdk.sh

#2、安装jenkins
yum install -y https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/jenkins-2.263.3-1.1.noarch.rpm

#3、变更jenkins配置文件(可选)
egrep -i "jenkins_port|jenkins_user" /etc/sysconfig/jenkins
JENKINS_USER="root"
JENKINS_PORT="80"

#4、启动jenkins
systemctl enable --now jenkins

#5、安装插件
https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
https://mirrors.tuna.tsinghua.edu.cn/jenkins/plugins
https://plugins.jenkins.io/

#6、更改清华源地址
cd /var/jenkins_home/updates
sed -i 's/http:\/\/updates.jenkins-ci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' default.json 
sed -i 's/http:\/\/www.google.com/https:\/\/www.baidu.com/g' default.json


#7、添加node节点
wget http://10.4.7.79/jnlpJars/agent.jar
echo c1dc12322cca956a77bc98df1d5d78c077e5e5559de5299b89bbc5e1977fd235 > secret-file
java -jar agent.jar -jnlpUrl http://10.4.7.79/computer/build01-78/jenkins-agent.jnlp -secret @secret-file -workDir "/opt/jenkins"


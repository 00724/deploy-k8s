#!groovy
@Library('jenkinslib') _

def tools = new org.devops.tools()

pipeline {
    agent {
        node {
            label "master"
        }
    }
    options {
        timestamps() //日志时间
        skipDefaultCheckout()  //删除隐式checkou scm语句
        disableConcurrentBuilds() //禁止并行
        timeout(time: 1,unit: 'HOURS')
    }
    stages {
        stage('env') {
            steps{
                timeout(time:20, unit:"MINUTES"){
                    script{
                        echo "Project ENV is ${params.project_env}"
                        tools.PrintMes("this is a sharelibrary!","green")
                    }
                }
            }
        }
        stage('ping') {
            steps{
                timeout(time:20,unit:"MINUTES"){
                    script{
                        sh "ping -c 3 jd.com"
                        tools.PrintMes("ping 京东","red")
                    }
                }
            }
        }
    }
    post {
        //执行后清理workspace
        always {
            echo "clear workspace......"
            deleteDir()
        }
        success {
            dingtalk (
                robot: 'd74b2e2b81b158610d5c5b',
                type: 'MARKDOWN',
                title: '项目构建成功啦',
                text: [
                    '## 构建完毕,请稍后检查业务状态...',
                    "[${JOB_NAME}](${JOB_URL})",
                    '',
                    '---',
                    '### 构建属性',
                    "- 任务日志：[#${BUILD_ID}](${BUILD_URL}console)",
                    "- 构建状态：${currentBuild.currentResult}",
                    "- commitID：${env.imageTag}",
                    "- 构建用户：${env.gitlabUserName}",
                    "- 部署环境：${env.DEPLOY_TO}",
                    "- 当前tag版本：${env.VERSION}"
                ]
            )
        }
        failure {
            dingtalk (
                robot: 'd74b2e2b81b158610d5c5b',
                type: 'MARKDOWN',
                title: '项目构建失败了',
                text: [
                    '## 项目构建失败了，请查看构建日志',
                    "[${JOB_NAME}](${JOB_URL})",
                    '',
                    '---',
                    '### 流水线属性',
                    "- 任务日志：[#${BUILD_ID}](${BUILD_URL}console)",
                    "- 状态：${currentBuild.currentResult}",
                    "- commitID：${env.imageTag}",
                    "- 构建用户：${env.gitlabUserName}",
                    "- 部署环境：${env.DEPLOY_TO}",
                    "- 当前tag版本：${env.VERSION}"
                ],
                at: [
                    '17601019539'
                ]
            )            
        }
    }
}
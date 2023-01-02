pipeline {
    agent {
        label 'jenkinsslave1'
    }
    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY')
        AWS_SECRETE_ACCESS_KEY = credentials('AWS_SECRETE_ACCESS_KEY')
        UROTAXI_DB_USER = 'root'
        UROTAXI_DB_PSW = credentials('UROTAXI_DB_PSW')
        ANSIBLE_HOST_KEY_CHECKING = "false"

    }
    options {
        buildDiscarder (logRotator(numToKeepStr: '3'))
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 1, unit: 'HOURS')
    }
    tools {
        maven '3.8.6'
        terraform '21207'
    }
    stages {
        stage('checkout') {
            steps {
                git(url: 'https://github.com/mankaripavan/urotaxiapplication.git', credentialsId: 'urotaxigitpat')
            }
        }
        stage('test') {
            steps {
                sh 'mvn --batch-mode clean test'
            }
        }
        stage('infra') {
            steps {
                sh '''
                    terraform -chdir=src/main/config/terraform init
                    terraform -chdir=src/main/config/terraform apply --auto-aprove
                    terraform -chdir=src/main/config/terraform otput --raw "urotaxiec2public_ip" > hosts
                    terraform -chdir=src/main/config/terraform output --raw "urotaxidbendpoint" ? dbhosts
                '''
            }
            post {
                failure {
                    sh '''
                    terraform -chdir=src/main/terraform destroy
                    '''
                }
            }
        } 
       stage('prepare') {
            steps {
                sh '''
                    sed -i "s|#dbusername#|$UROTAXI_DB_USER|g" src/main/resources/application.yml
                    sed -i "s|#dbpassword#|$UROTAXI_DB_PSW|g" src/main/resources/application.yml
                    dbHost = $(dbHosts)
                    sed -i "s|#dbhost#|$dbHost|g" src/mian/resources/application.yml
                '''
            }    
       }
       stage('package') {
        steps {
            sh 'mvn --batch-mode clean package -DskipTests=true'
        }
       }
       stage('deploy') {
        steps {
            sh 'sudo chmod u+x src/main/config/sh/getDBHost.sh'
            script {
                env.DB_HOST = sh(returnStdout: true, script: "src/main/config/sh/getDBHost.sh").trim()
                echo "env.DB_HOST is '${DB_HOST}'"
            }
            ansiblePlaybook(playbook:'src/main/config/ansible/urotaxi-playbook.yml', credentialsId: 'aws_key', inventory: 'hosts')
        }
       }
    }
}
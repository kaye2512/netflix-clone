pipeline {
    agent {
        docker {
            image 'kayeromuald/node-agent:v3'   // v2 avec bun
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    environment {
        ECR_REPO_BACKEND  = 'netflix-clone-backend'
        ECR_REPO_FRONTEND = 'netflix-clone-frontend'
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    stages {

        stage('Checkout') {
            steps {
                checkout scm
                sh '''
                    echo "Node: $(node --version)"
                '''
            }
        }

        stage('Build backend') {
            steps {
                dir('backend') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }

        stage('Build frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([
                    aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        credentialsId:     'jk-aws-credentials',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        ECR_REGISTRY=$(aws sts get-caller-identity \
                            --query Account --output text).dkr.ecr.eu-west-3.amazonaws.com

                        aws ecr get-login-password --region eu-west-3 \
                            | docker login --username AWS --password-stdin $ECR_REGISTRY

                        docker build -t ${ECR_REGISTRY}/${ECR_REPO_BACKEND}:${BUILD_NUMBER}  ./backend
                        docker build -t ${ECR_REGISTRY}/${ECR_REPO_FRONTEND}:${BUILD_NUMBER} ./frontend

                        docker tag ${ECR_REGISTRY}/${ECR_REPO_BACKEND}:${BUILD_NUMBER}  \
                                   ${ECR_REGISTRY}/${ECR_REPO_BACKEND}:latest
                        docker tag ${ECR_REGISTRY}/${ECR_REPO_FRONTEND}:${BUILD_NUMBER} \
                                   ${ECR_REGISTRY}/${ECR_REPO_FRONTEND}:latest

                        docker push ${ECR_REGISTRY}/${ECR_REPO_BACKEND}:${BUILD_NUMBER}
                        docker push ${ECR_REGISTRY}/${ECR_REPO_BACKEND}:latest
                        docker push ${ECR_REGISTRY}/${ECR_REPO_FRONTEND}:${BUILD_NUMBER}
                        docker push ${ECR_REGISTRY}/${ECR_REPO_FRONTEND}:latest
                    '''
                }
            }
        }
    }

    post {
        always  { sh 'docker logout || true' }
        success { echo "Build #${BUILD_NUMBER} — images pushees avec succes" }
        failure { echo "Build #${BUILD_NUMBER} — pipeline en echec" }
    }
}

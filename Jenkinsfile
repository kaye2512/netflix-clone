pipeline {
    agent {
        docker {
            image 'kayeromuald/bun-agent:v1'   // v2 avec bun
            args '--user root -v /var/run/docker.sock:/var/run/docker.sock -e HOME=/root'
        }
    }
    environment {
        ECR_REPO_BACKEND  = 'netflix-clone-backend'
        ECR_REPO_FRONTEND = 'netflix-clone-frontend'
        npm_config_cache  = '/tmp/.npm'
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
                    sh 'rm -rf node_modules'
                    sh 'bun install'
                    sh 'bun run build'
                }
            }
        }

        stage('Build frontend') {
            steps {
                dir('frontend') {
                    sh 'rm -rf node_modules'
                    sh 'bun install'
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

        stage('Deploy to VPS') {
            steps {
                withCredentials([
                    aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        credentialsId:     'jk-aws-credentials',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'),
                    sshUserPrivateKey(credentialsId: 'vps-ssh-key',
                                      keyFileVariable: 'SSH_KEY',
                                      usernameVariable: 'SSH_USER'),
                    string(credentialsId: 'vps-host', variable: 'VPS_HOST')
                ]) {
                    sh '''
                        ECR_REGISTRY=$(aws sts get-caller-identity \
                            --query Account --output text).dkr.ecr.eu-west-3.amazonaws.com

                        ssh -i $SSH_KEY -o StrictHostKeyChecking=no $SSH_USER@$VPS_HOST "
                            # Login ECR
                            aws ecr get-login-password --region eu-west-3 \
                                | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                            # Pull latest images
                            docker pull ${ECR_REGISTRY}/netflix-clone-backend:${BUILD_NUMBER}
                            docker pull ${ECR_REGISTRY}/netflix-clone-frontend:${BUILD_NUMBER}

                            # Update compose and restart
                            cd /opt/netflix-clone
                            export ECR_REGISTRY=${ECR_REGISTRY}
                            export IMAGE_TAG=${BUILD_NUMBER}
                            docker compose pull
                            docker compose up -d --remove-orphans

                            # Cleanup old images
                            docker image prune -f
                        "
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

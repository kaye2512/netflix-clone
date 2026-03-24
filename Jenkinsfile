pipeline {
    agent {
        docker {
            image 'kayeromuald/node-agent:v1'
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
                // Vérifier la structure du repo
                sh '''
                    echo "=== Structure du repo ==="
                    ls -la
                    echo "=== Contenu backend ==="
                    ls -la backend/
                    echo "=== Contenu frontend ==="
                    ls -la frontend/
                    echo "Node: $(node --version) | npm: $(npm --version)"
                '''
            }
        }

        stage('Build backend') {
            steps {
                dir('backend') {       // méthode Jenkins recommandée
                    sh 'npm ci'        // sans --silent pour voir les erreurs
                    sh 'npm run build'
                }
            }
        }

        stage('Build frontend') {
            steps {
                dir('frontend') {
                    sh 'npm ci'
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

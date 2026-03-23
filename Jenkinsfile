pipeline {
    agent {
        docker {
            image 'kayeromuald/node-agent:v1'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        AWS_REGION     = credentials('eu-west-3')
        ECR_REPO_BACKEND       = 'netflix-clone-backend'
        ECR_REPO_FRONTEND       = 'netflix-clone-frontend'
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
                sh 'echo "Branch: ${GIT_BRANCH} | Commit: ${GIT_COMMIT}"'
            }
        }

        stage('Build backend') {
            steps {
                sh '''
                    echo "=== Building backend ==="
                    cd backend
                    npm ci --silent
                    npm run build
                '''
            }
        }

        stage('Build frontend') {
            steps {
                sh '''
                    echo "=== Building frontend ==="
                    cd frontend
                    npm ci --silent
                    npm run build
                '''
            }
        }


        stage('push to ECR') {
            steps {
                withCredentials([
                    aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    credentialsId: 'jk-aws-credentials',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')
            ]) {
                sh '''
                    # Login ECR une seule fois
                    ECR_REGISTRY=$(aws sts get-caller-identity \
                    --query Account --output text).dkr.ecr.${AWS_REGION}.amazonaws.com

                    aws ecr get-login-password --region $AWS_REGION \
                    | docker login --username AWS --password-stdin $ECR_REGISTRY

                    # Build backend
                    docker build -t ${ECR_REGISTRY}/${ECR_REPO_BACKEND}:${BUILD_NUMBER}  ./backend
                    docker tag      ${ECR_REGISTRY}/${ECR_REPO_BACKEND}:${BUILD_NUMBER} \
                                    ${ECR_REGISTRY}/${ECR_REPO_BACKEND}:latest

                    # Build frontend
                    docker build -t ${ECR_REGISTRY}/${ECR_REPO_FRONTEND}:${BUILD_NUMBER} ./frontend
                    docker tag      ${ECR_REGISTRY}/${ECR_REPO_FRONTEND}:${BUILD_NUMBER} \
                                    ${ECR_REGISTRY}/${ECR_REPO_FRONTEND}:latest

                    # Push tout
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
        always {
            sh 'docker logout || true'
        }
        success {
            echo "Backend et frontend pushes avec succes — build #${BUILD_NUMBER}"
        }
        failure {
            echo "Pipeline echoue au build #${BUILD_NUMBER}"
        }
  }
}


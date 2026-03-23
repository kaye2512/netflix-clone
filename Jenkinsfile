pipeline {
    agent {
        docker {
            image 'kayeromuald/node-agent:v1'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        AWS_REGION     = credentials('eu-west-3')
        AWS_ACCOUNT_ID = credentials('jk-aws-credentials')
        ECR_REPO       = 'netflix-clone'
        ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG      = "${ECR_REGISTRY}/${ECR_REPO}:${BUILD_NUMBER}"
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

    }
}

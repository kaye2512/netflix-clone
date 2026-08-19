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

        

    post {
        always  { sh 'docker logout || true' }
        success { echo "Build #${BUILD_NUMBER} — images pushees avec succes" }
        failure { echo "Build #${BUILD_NUMBER} — pipeline en echec" }
    }
}

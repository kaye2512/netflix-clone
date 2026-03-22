pipeline {
    agent any

    // ─────────────────────────────────────────
    // Variables globales du pipeline
    // ─────────────────────────────────────────
    environment {
        // DockerHub: configurer dans Jenkins → Manage Credentials
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DOCKERHUB_REPO        = 'ton-username/netflix-clone'   // ← changer ici
        IMAGE_TAG             = "${BUILD_NUMBER}"
        IMAGE_LATEST          = "${DOCKERHUB_REPO}:latest"
        IMAGE_VERSIONED       = "${DOCKERHUB_REPO}:${IMAGE_TAG}"

        // SSH vers le serveur app (EC2 t3.micro)
        APP_SERVER_IP         = credentials('app-server-ip')   // IP stockée en secret
        APP_SERVER_SSH_KEY    = credentials('app-server-ssh-key')

        // Variables d'environnement app (stockées dans Jenkins Credentials)
        MONGO_URI             = credentials('mongo-uri')
        JWT_SECRET            = credentials('jwt-secret')
        TMDB_API_KEY          = credentials('tmdb-api-key')
        MAILTRAP_TOKEN        = credentials('mailtrap-token')
        MAILTRAP_ENDPOINT     = credentials('mailtrap-endpoint')
    }

    options {
        // Garde les 5 derniers builds seulement (économie disque Jenkins)
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {

        // ── 1. Checkout ──────────────────────────────
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "Branch: ${GIT_BRANCH} | Commit: ${GIT_COMMIT}"'
            }
        }

        // ── 2. Lint & Code Quality ───────────────────
        stage('Lint') {
            steps {
                sh '''
                    echo "=== Installing deps for lint ==="
                    npm ci --silent
                    cd frontend && npm ci --silent
                    cd ../backend && npm ci --silent
                    echo "=== Running ESLint ==="
                    cd ../frontend && npm run lint
                '''
            }
        }

        // ── 3. Build Docker Image ────────────────────
        stage('Build Docker Image') {
            steps {
                script {
                    sh '''
                        echo "=== Building Docker image ==="
                        docker build \
                            --tag ${IMAGE_VERSIONED} \
                            --tag ${IMAGE_LATEST} \
                            --file Dockerfile \
                            .
                        echo "=== Image size ==="
                        docker image inspect ${IMAGE_LATEST} --format='{{.Size}}' | \
                            awk '{printf "Image size: %.1f MB\\n", $1/1024/1024}'
                    '''
                }
            }
        }

        // ── 4. Security Scan (Trivy) ─────────────────
        // Trivy est installé sur le serveur Jenkins
        // Installation: https://aquasecurity.github.io/trivy
        stage('Security Scan') {
            steps {
                sh '''
                    echo "=== Security scan with Trivy ==="
                    trivy image \
                        --exit-code 0 \
                        --severity HIGH,CRITICAL \
                        --no-progress \
                        ${IMAGE_LATEST} | tee trivy-report.txt
                    echo "=== Scan terminé (exit-code 0 = rapport sans bloquer le build) ==="
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
                }
            }
        }

        // ── 5. Push vers DockerHub ───────────────────
        stage('Push to DockerHub') {
            steps {
                sh '''
                    echo "=== Login DockerHub ==="
                    echo ${DOCKERHUB_CREDENTIALS_PSW} | \
                        docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin

                    echo "=== Push images ==="
                    docker push ${IMAGE_VERSIONED}
                    docker push ${IMAGE_LATEST}

                    echo "=== Logout ==="
                    docker logout
                '''
            }
        }

        // ── 6. Deploy sur EC2 App Server ────────────
        stage('Deploy to Production') {
            when {
                // Déployer seulement depuis la branche main/master
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                script {
                    // Écrire le fichier .env sur le serveur app via SSH
                    // Les secrets viennent des Jenkins Credentials (jamais en clair dans le code)
                    sh '''
                        echo "=== Déploiement sur ${APP_SERVER_IP} ==="

                        # Créer le .env temporairement pour le transfert SSH
                        cat > /tmp/app.env << EOF
NODE_ENV=production
SERVER_PORT=8000
MONGO_URI=${MONGO_URI}
JWT_SECRET=${JWT_SECRET}
TMDB_API_KEY=${TMDB_API_KEY}
MAILTRAP_TOKEN=${MAILTRAP_TOKEN}
MAILTRAP_ENDPOINT=${MAILTRAP_ENDPOINT}
CLIENT_URL=http://${APP_SERVER_IP}:8000
EOF

                        # Copier le .env sur le serveur app
                        scp -o StrictHostKeyChecking=no \
                            -i ${APP_SERVER_SSH_KEY} \
                            /tmp/app.env \
                            ec2-user@${APP_SERVER_IP}:/home/ec2-user/netflix-clone/.env

                        # Déployer avec docker-compose via SSH
                        ssh -o StrictHostKeyChecking=no \
                            -i ${APP_SERVER_SSH_KEY} \
                            ec2-user@${APP_SERVER_IP} \
                            "
                            cd /home/ec2-user/netflix-clone && \
                            docker pull ${IMAGE_LATEST} && \
                            docker-compose down --remove-orphans && \
                            docker-compose up -d && \
                            docker-compose ps && \
                            echo '=== Deploy SUCCESS ==='
                            "

                        # Nettoyer le fichier .env temporaire
                        rm -f /tmp/app.env
                    '''
                }
            }
        }

        // ── 7. Health Check post-deploy ──────────────
        stage('Health Check') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                sh '''
                    echo "=== Vérification que l'app répond ==="
                    sleep 15   # attendre que le container démarre

                    # Retry 5 fois avec 10s d'intervalle
                    for i in $(seq 1 5); do
                        STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
                            http://${APP_SERVER_IP}:8000/api/v1/health || echo "000")
                        echo "Tentative $i: HTTP $STATUS"
                        if [ "$STATUS" = "200" ]; then
                            echo "✓ Application en ligne!"
                            exit 0
                        fi
                        sleep 10
                    done

                    echo "✗ Health check échoué après 5 tentatives"
                    exit 1
                '''
            }
        }
    }

    // ─────────────────────────────────────────
    // Post-actions (toujours exécutées)
    // ─────────────────────────────────────────
    post {
        always {
            // Nettoyer les images Docker locales sur Jenkins (économie disque)
            sh '''
                docker rmi ${IMAGE_VERSIONED} ${IMAGE_LATEST} 2>/dev/null || true
                docker image prune -f
            '''
        }
        success {
            echo "✓ Pipeline réussi — Build #${BUILD_NUMBER} déployé"
        }
        failure {
            echo "✗ Pipeline échoué — vérifier les logs"
        }
    }
}

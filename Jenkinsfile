pipeline {
    agent any

    environment {
        TAG = sh(script: 'git describe --abbrev=0',,returnStdout: true).trim()

        NEXUS_URL = 'http://192.168.56.3:8091/repository/npm-hosted/' 
        NPM_USER = 'teste' 
        NPM_PASS = 'teste' 
        NPM_EMAIL = 'teste@teste.com'
    }

    stages {

         stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install dependencies') {
            steps {
                script {
                    sh 'npm install'
                }
            }
        }

        stage('Publish to Nexus') {
            steps {
                script {
                    sh '''
                    npm config set registry $NEXUS_URL
                    npm config set //192.168.56.3:8091/repository/npm-hosted/:_authToken=$NEXUS_PASSWORD
                    '''

                    sh 'npm publish'
                }
            }
        }

        stage('build docker image'){
        steps{
            sh 'docker build -t react-hello/app:${TAG} .'
            }
        }
    
        stage ('deploy docker compose'){
        steps{
            sh 'docker compose up --build -d'
            }
        }

        stage('sleep for container deploy'){
        steps{
            sh 'sleep 10'
            }
        }

        stage('Sonarqube validation'){
            steps{
                script{
                    scannerHome = tool 'sonar-scanner';
                }
                withSonarQubeEnv('sonar-server'){
                    sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=react-hello -Dsonar.sources=. -Dsonar.host.url=${env.SONAR_HOST_URL} -Dsonar.token=${env.SONAR_AUTH_TOKEN} -X"
                }
                sh 'sleep 10'
            }
        }

        stage("Quality Gate"){
            steps{
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Shutdown docker containers') {
            steps{
                sh 'docker compose down'
            }
        }

        stage('Publish npm Package') { 
            steps { 
                sh 'npm publish'
                //script { 
                //    withCredentials([usernamePassword(credentialsId: 'nexus-user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) { 
                //        sh 'npm set registry http://192.168.56.3:8091/repository/npm-hosted/' 
                //        sh 'npm login -u teste -p teste -r http://192.168.56.3:8091/repository/npm-hosted/' 
                //        sh 'npm publish' 
                //    } 
                //}
            }
        }

        stage('Upload docker image'){
            steps{
                script {
                    withCredentials([usernamePassword(credentialsId: 'nexus-user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh 'docker login -u $USERNAME -p $PASSWORD ${NEXUS_URL}'
                        sh 'docker tag react-hello/app:${TAG} ${NEXUS_URL}/react-hello/app:${TAG}'
                        sh 'docker push ${NEXUS_URL}/react-hello/app:${TAG}'
                    }
                }
            }
        }

        stage("Apply kubernetes files"){
            steps{
                sh '/usr/local/bin/kubectl apply -f ./kubernetes/react-hello.yaml'
            }
        }
    }
}
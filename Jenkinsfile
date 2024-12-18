pipeline {
    agent any

    environment {
        TAG = sh(script: 'git describe --abbrev=0',,returnStdout: true).trim()
    }

    stages {

        stage('Update npm') { 
            steps { 
                sh 'npm config set registry https://registry.npmjs.org/' 
                sh 'npm install -g npm@latest' 
                sh 'npm config set registry http://192.168.56.3:8091/repository/npm-hosted/'
            } 
        } 
        
        stage('Install Dependencies') { 
            steps { 
                sh 'npm install' 
            } 
        } 
        
        stage('Build Project') { 
            steps { 
                sh 'npm run build' 
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
                script { 
                    withCredentials([usernamePassword(credentialsId: 'nexus-user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) { 
                        sh 'npm set registry http://192.168.56.3:8091/repository/npm-hosted/' 
                        sh 'npm login -u $USERNAME -p $PASSWORD -r http://192.168.56.3:8091/repository/npm-hosted/' 
                        sh 'npm publish' 
                    } 
                }
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
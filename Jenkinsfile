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

        stage('Setup .npmrc') { 
            steps {
                sh 'echo "registry=http://192.168.56.3:8091/repository/npm-hosted/" > ~/.npmrc' 
                //sh 'echo "//http://192.168.56.3:8091/repository/npm-hosted/:username=teste" >> ~/.npmrc' 
                //sh 'echo "//http://192.168.56.3:8091/repository/npm-hosted/:password=$(echo -n teste | openssl base64)" >> ~/.npmrc'
                //sh 'echo "//http://192.168.56.3:8091/repository/npm-hosted/:email=teste@teste.com" >> ~/.npmrc'
            } 
        }

        stage('npm adduser') { 
            steps { 
                script { 
                    //sh 'echo -e "teste\nteste\nteste@teste.com" | npm adduser --registry=http://192.168.56.3:8091/repository/npm-hosted/' 
                    sh 'echo -e "${NPM_USER}\n${NPM_PASS}\n${NPM_EMAIL}" | npm adduser --registry=${NEXUS_URL}'
                } 
            } 
        }

        stage('Update npm') { 
            steps {  
                sh 'sudo npm install -g npm@latest' 
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
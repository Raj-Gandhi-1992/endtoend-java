pipeline {
    agent {
        label 'pipe'
    }

    environment {
        SERVER_ID = 'Jfrog_spc_java' // Jenkins Artifactory config ID
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '777014042292.dkr.ecr.ap-south-1.amazonaws.com/java/spc'
        ARTIFACTORY_URL = 'https://trialtud4wx.jfrog.io/artifactory/javaspc-libs-release-local/com/myapp'
    }

    triggers {
        pollSCM('* * * * *')
    }

    stages {

        stage('GIT CHECKOUT') {
            steps {
                git url: 'https://github.com/spring-projects/spring-petclinic.git', branch: 'main'
            }
        }

        stage('BUILD & SONAR') {
            steps {
                withCredentials([string(credentialsId: 'sonar_new', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('SONARQUBE') {
                        sh '''
                            mvn package sonar:sonar \
                            -Dsonar.projectKey=Raj-Gandhi-1992_java-spc-pipeline \
                            -Dsonar.organization=raj-gandhi-1992 \
                            -Dsonar.host.url=https://sonarcloud.io \
                            -Dsonar.login=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Upload to JFrog Artifactory') {
            steps {
                script {
                    // Artifactory server connection
                    def server = Artifactory.server(SERVER_ID)
                    def buildInfo = Artifactory.newBuildInfo()

                    // Upload JAR
                    server.upload(
                        spec: """{
                            "files": [
                                {
                                    "pattern": "target/*.jar",
                                    "target": "javaspc-libs-release-local/com/myapp/${BUILD_NUMBER}/"
                                }
                            ]
                        }""",
                        buildInfo: buildInfo
                    )

                    // Publish build info
                    server.publishBuildInfo(buildInfo)
                }
            }
        }

        stage('Build & Push Docker Image to ECR') {
           steps {
            script {
            def imageTag = "${ECR_REPO}:${BUILD_NUMBER}"

            // Copy JAR from master to agent workspace
            copyArtifacts(projectName: 'java-spc', selector: lastSuccessful())

            // Login to AWS ECR
            sh """
                aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
            """

            // Build Docker image on agent
            sh "docker build -t ${imageTag} ."

            // Push Docker image to ECR
            sh "docker push ${imageTag}"
        }
    }
}

    }

    post {
        always {
            archiveArtifacts artifacts: '**/target/*.jar'
            junit '**/target/surefire-reports/*.xml'
        }

        success {
            echo 'Pipeline executed successfully.'
        }

        failure {
            echo 'Pipeline failed. Please check the logs for errors.'
        }
    }
}

pipeline {
    agent { label 'pipe' }

    environment {
        SERVER_ID = 'Jfrog_spc_java'
        AWS_REGION = 'ap-south-1'
        ECR_REPO = '777014042292.dkr.ecr.ap-south-1.amazonaws.com/java/spc'
        ARTIFACTORY_URL = 'https://trialtud4wx.jfrog.io/artifactory/javaspc-libs-release-local/com/myapp'
        MAVEN_OPTS = "--add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED"
    }

    triggers {
        pollSCM('* * * * *')
    }

    stages {

        stage('GIT CHECKOUT') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], 
                    userRemoteConfigs: [[url: 'https://github.com/Raj-Gandhi-1992/java-spc-pipeline.git']]]) // change the files in repo
            }
        }

        stage('BUILD & SONAR') {
            steps {
                withCredentials([string(credentialsId: 'sonar_new', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('SONARQUBE') {
                        sh '''
                            mvn clean package sonar:sonar \
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
                    def server = Artifactory.server(SERVER_ID)
                    def buildInfo = Artifactory.newBuildInfo()

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
                    server.publishBuildInfo(buildInfo)
                }
            }
        }

        stage('Build & Push Docker Image to ECR') {
    steps {
        script {
            def imageTag = "${ECR_REPO}:${BUILD_NUMBER}"

            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_id']]) {
                sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}"
                sh "docker build -f Dockerfile -t ${imageTag} ."
                sh "docker push ${imageTag}"
                }
            }
        }
    }

   stage('Install Trivy & Scan Image') {
    steps {
        script {
            // Ensure Trivy is installed locally in workspace
            sh '''
                if ! command -v trivy &> /dev/null; then
                    echo "Trivy not found. Installing..."
                    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
                    export PATH=$PATH:$(pwd)/bin
                fi
                trivy --version
            '''

            // Define the image tag
            def imageTag = "${ECR_REPO}:${BUILD_NUMBER}"

            // Run Trivy scan and output JUnit XML report
            sh '''
                export PATH=$PATH:$(pwd)/bin
                trivy image --format template --template "@contrib/junit.tpl" \
                    -o trivy-report-${BUILD_NUMBER}.xml ${imageTag}
            '''
        }
    }
    post {
        always {
            // Publish JUnit report and archive artifacts
            junit allowEmptyResults: true, testResults: "trivy-report-${BUILD_NUMBER}.xml"
            archiveArtifacts artifacts: "trivy-report-${BUILD_NUMBER}.xml"
        }
    }
}

    }

    post {
        always {
            archiveArtifacts allowEmptyArchive: true, artifacts: '**/target/*.jar'
            junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
        }
        success {
            echo 'Pipeline executed successfully.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for errors.'
        }
    }
}

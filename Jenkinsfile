pipeline {
    agent {
        label 'pipe'
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
        stage('BUILD') {
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
                    // Create an Artifactory server connection (must match your Jenkins Artifactory config ID)
                    def server = Artifactory.server('Jfrog_spc_java')

                    // Create build info object
                    def buildInfo = Artifactory.newBuildInfo()

                    // Upload artifacts using modern syntax
                    server.upload(
                        spec: '''{
                            "files": [
                                {
                                    "pattern": "target/*.jar",
                                    "target": "javaspc-libs-release-local/com/myapp/${BUILD_NUMBER}/"
                                }
                            ]
                        }''',
                        buildInfo: buildInfo
                    )

                    // Publish the build info to Artifactory
                    server.publishBuildInfo(buildInfo)
                }
            }
        }
    }
    post {
        always {
            // Archive the JAR files and test reports regardless of the pipeline result
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
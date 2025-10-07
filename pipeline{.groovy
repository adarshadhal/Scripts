pipeline{
    agent any
    stages{
        stage ("code Copile") {
            steps {
                git branch: 'main',
                    url: 'https://github.com/adarshadhal/myapp.git',
                    credentialsId: 'git_hub'
                sh '/opt/maven/bin/mvn compile'
            }
        }
        stage ("code Review"){
            steps {
                sh '/opt/maven/bin/mvn -P metrics pmd:pmd'
            }
            post{
                success{
                    recordIssues sourceCodeRetention: 'LAST_BUILD', tools: [pmdParser(pattern: '**/pmd.xml')]
                }
            }
        }
        stage("uni-test"){
            steps{
                sh '/opt/maven/bin/mvn test'
            }
        }
        stage("code-coverage"){
            
            steps{
                sh '/opt/maven/bin/mvn verify'
            }

            post{
                success{
                    jacoco buildOverBuild: true, changeBuildStatus: true, runAlways: true, skipCopyOfSrcFiles: true
                }
            }
        }
        stage("Code Package"){
            steps{
                sh '/opt/maven/bin/mvn package'
            }
        }
        
        stage("ducker image build and push"){
            steps{
                withDockerRegistry(credentialsId: 'docker_hub', url: 'https://index.docker.io/v1/') {
                sh script: 'cd  $WORKSPACE'
                    sh script: 'docker build --file Dockerfile --tag docker.io/adarshadhal/myapp:$BUILD_NUMBER .'
                    sh script: 'docker push docker.io/adarshadhal/myapp:$BUILD_NUMBER'
                }
            }
        }
        stage("deploye to qa"){
            steps{
                sh 'ansible-playbook -i /var/lib/jenkins/workspace/Ci-pipeline/deploy deploy-kube.yml --extra-vars "env=qa build=$BUILD_NUMBER"'
            }
        }

    }
}       
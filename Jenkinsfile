pipeline {
  agent any
  
  stages {

    stage('run_xsim') {
      steps {
        sh 'cd sim/xsim && ./test_runner.sh'
        // Command 2
        // Etc.
      }
    }


  }
  post {
    failure {
      emailext attachLog: true,
      body: '''Project name: $PROJECT_NAME
Build number: $BUILD_NUMBER
Build Status: $BUILD_STATUS
Build URL: $BUILD_URL''',
      recipientProviders: [culprits()],
      subject: 'Project \'$PROJECT_NAME\' is broken'
    }
  }
}

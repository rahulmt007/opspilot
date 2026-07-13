pipeline {
  agent any
  stages {
    stage('Test') { steps { sh 'python -m pip install -e ".[dev]" && ruff check . && pytest' } }
    stage('Build') { steps { sh 'docker build -t opspilot:${BUILD_NUMBER} .' } }
    stage('Scan') { steps { sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL opspilot:${BUILD_NUMBER}' } }
  }
}

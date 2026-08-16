def call(
    String projectKey,
    String sourceDir = ".",
    String credentialsId = "sonarqube-token"
) {
    echo "Running SonarQube Code Quality Analysis for ${projectKey}..."

    withCredentials([
        string(
            credentialsId: credentialsId,
            variable: "SONAR_TOKEN"
        )
    ]) {
        sh """
            sonar-scanner \
              -Dsonar.projectKey=${projectKey} \
              -Dsonar.sources=${sourceDir} \
              -Dsonar.host.url=http://localhost:9000 \
              -Dsonar.token="\${SONAR_TOKEN}" \
              -Dsonar.exclusions="**/node_modules/**,**/target/**,**/*.jar,**/*.war,**/*.png,**/*.jpg,**/*.jpeg,**/*.svg"
        """
    }
}

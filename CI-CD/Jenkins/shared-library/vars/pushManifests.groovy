def call(Map args = [:]) {

    def repoUrl = args.repoUrl
    def branch = args.get('branch', 'main')
    def commitMessage = args.get('commitMessage', 'Update Kubernetes image')
    def credentialsId = args.credentialsId
    def paths = args.get('paths', '.')

    withCredentials([usernamePassword(
        credentialsId: credentialsId,
        usernameVariable: 'GIT_USER',
        passwordVariable: 'GIT_TOKEN'
    )]) {
        def repoNoScheme = repoUrl.replaceFirst('https://', '').replaceFirst('\\.git$', '')

        sh """
            git config user.email "jenkins@ci.local"
            git config user.name "Jenkins CI"
            git add ${paths}
            git commit -m "${commitMessage}" || true
            git push https://\\\${GIT_USER}:\\\${GIT_TOKEN}@${repoNoScheme}.git HEAD:${branch}
        """
    }
}
def call(Map args = [:]) {

def repoUrl = args.repoUrl
def branch = args.get('branch', 'main')
def commitMessage = args.get('commitMessage', 'Update Kubernetes image')
def credentialsId = args.credentialsId
def paths = args.get('paths', '.')

def repoNoScheme = repoUrl
    .replaceFirst('https://', '')
    .replaceFirst('\\.git$', '')

withCredentials([
    usernamePassword(
        credentialsId: credentialsId,
        usernameVariable: 'GIT_USER',
        passwordVariable: 'GIT_TOKEN'
    )
]) {
    withEnv([
        "REPO_NO_SCHEME=${repoNoScheme}",
        "BRANCH=${branch}",
        "COMMIT_MESSAGE=${commitMessage}",
        "PUSH_PATHS=${paths}"
    ]) {
        sh '''
            git config user.email "jenkins@ci.local"
            git config user.name "Jenkins CI"

            git add "$PUSH_PATHS"
            git commit -m "$COMMIT_MESSAGE" || true

            git push "https://${GIT_USER}:${GIT_TOKEN}@${REPO_NO_SCHEME}.git" HEAD:${BRANCH}
        '''
    }
}

}

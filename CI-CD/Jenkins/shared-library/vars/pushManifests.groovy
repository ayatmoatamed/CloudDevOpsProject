def call(Map args = [:]) {

    def commitMessage = args.get(
        'commitMessage',
        'Update Kubernetes image'
    )

    sh """
        git add Kubernetes/
        git commit -m "${commitMessage}" || true
        git push origin HEAD
    """
}

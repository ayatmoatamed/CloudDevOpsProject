def call(Map args = [:]) {

    def manifestFile = args.manifestFile
    def imageUri = args.imageUri

    echo "Updating ${manifestFile}"
    echo "New image: ${imageUri}"

    sh """
        sed -i -E 's|^[[:space:]]*image:.*|          image: ${imageUri}|' '${manifestFile}'

        echo "Updated image:"
        grep 'image:' '${manifestFile}'
    """
}
#!/bin/bash
# assign the first argument passed to the script to a variable
version=$1
# use sed to replace the image version in the file
sed -i "s/landing-page.*/$version/g" .github/manifests/portfolio-app.yml
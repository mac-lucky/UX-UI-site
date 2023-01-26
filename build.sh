docker build -t maclucky/ux-ui-site .
docker tag maclucky/ux-ui-site:latest maclucky/ux-ui-site:1.0.0
docker push maclucky/ux-ui-site:1.0.0
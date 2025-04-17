update-ca-certificates --fresh
openssl s_client -showcerts -verify 5 -connect k8s.gcr.io:443 < /dev/null 2>/dev/null | openssl x509 -outform PEM | tee ~/.minikube/certs/k8s.gcr.io.crt
openssl s_client -showcerts -verify 5 -connect registry-1.docker.io:443 < /dev/null 2>/dev/null | openssl x509 -outform PEM | tee ~/.minikube/certs/registry-1.docker.io.crt
openssl s_client -showcerts -verify 5 -connect auth.docker.io:443 < /dev/null 2>/dev/null | openssl x509 -outform PEM | tee ~/.minikube/certs/auth.docker.io.crt
openssl s_client -showcerts -verify 5 -connect us-east4-docker.pkg.dev:443 < /dev/null 2>/dev/null | openssl x509 -outform PEM | tee ~/.minikube/certs/us-east4-docker.pkg.dev.crt

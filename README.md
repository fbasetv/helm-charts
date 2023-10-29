# Webservice helm template

helm package charts/webservice
helm repo index --url https://fbasetv.github.io/helm-charts/ --merge index.yaml .
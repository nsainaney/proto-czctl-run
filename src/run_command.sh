# echo "# this file is located in 'src/root_command.sh'"
# echo "# you can edit it freely and regenerate (it will not be overwritten)"
# inspect_args

yaml=$(cat ./k8s/template.yaml | sed "s/%%NAME%%/${args[--service]}/" | sed "s/%%PORT%%/${args[--port]}/" | sed "s/%%IMAGE%%/${args[image_name]}/" | sed "s/%%NAMESPACE%%/${args[--namespace]}/")

# echo "$yaml"

if [ ! -d "./ssl" ]; then
    mkdir ssl
    openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
    -keyout ssl/registry.key -out ssl/registry.crt -subj "/CN=registry.codezero.svc.cluster.local" \
    -addext "subjectAltName=DNS:registry.codezero.svc.cluster.local"

    kubectl create secret tls registry-tls --key ssl/registry.key --cert ssl/registry.crt --namespace codezero

    kubectl -n codezero apply -f ./k8s/registry.yaml
fi

echo "codezero/registry" | czctl consume apply -

docker tag ${args[image_name]} registry.codezero:5000/${args[image_name]}
DOCKER_OPTS="--insecure-registry registry.codezero:5000" docker push registry.codezero:5000/${args[image_name]}

kubectl create ns ${args[--namespace]} || true

# kubectl create secret docker-registry regcred \
#   --docker-server=registry.codezero \
#   --docker-username="" \
#   --docker-password="" \
#   --namespace=${args[--namespace]}


kubectl apply -f - <<EOF
$yaml
EOF

echo "${args[--namespace]}/${args[--service]}" | czctl consume apply -
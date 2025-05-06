# Create kind cluster
kind create cluster || exit 1

# Install Flux
flux install  || exit 1

# Install Kro
helm install kro oci://ghcr.io/kro-run/kro/kro --namespace kro --create-namespace --version=0.2.3  || exit 1

# Install ocm-controllers
kubectl apply -f setup/ocm-controllers.yaml
kubectl wait kustomization ocm-controllers --for=condition=Ready=true --timeout=5m  || exit 1
kubectl wait deployment -l app.kubernetes.io/name=ocm-k8s-toolkit --for condition=Available=true --timeout 5m  || exit 1

###

# Create component version
ocm add cv --create --file ./setup/ctf setup/component-constructor.yaml  || exit 1

# Transfer component version to registry (+ localization)
ocm transfer ctf --enforce --overwrite --copy-resources ./setup/ctf ghcr.io/frewilhelm  || exit 1
ocm get cv ghcr.io/frewilhelm//ocm.software/ocm-controller-demo-gitops -o yaml

###

# Apply FluxCD Kustomization
kubectl apply -f setup/gitops.yaml

# Wait for RGD to be active
kubectl wait rgd/demo-gitops-rgd --for "create"  --timeout=5m  || exit 1
kubectl wait rgd/demo-gitops-rgd --for "condition=CustomResourceDefinitionSynced=true"  --timeout=5m  || exit 1

# Apply instance of CRD created by ResourceGraphDefinition
kubectl apply -f setup/instance.yaml
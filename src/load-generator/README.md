# Retail Store Sample App - Load Generator

This is a utility component to generate synthetic load on the sample application, which is useful for scenarios such as autoscaling, observability and resiliency testing. It primarily consists of a set of scenarios for [Artillery](https://github.com/artilleryio/artillery), as well as scripts to help run it.

## Usage

### Local

A convenience script is provided to make it easier to run the load generator on your local machine.

Run the following command for usage instructions:

```bash
bash scripts/run-docker.sh --help
```

### Kubernetes

**One-liner (без init container):** образ Artillery має entrypoint `artillery`, тому потрібно явно задати команду `bash -c "..."` через `--command`:

```bash
# Видалити старий под, якщо залишився
kubectl delete pod load-gen --ignore-not-found

# Запуск (підставте URL вашого UI та namespace при потребі)
TARGET="http://ui.ui-staging.svc.cluster.local:80"
kubectl run load-gen --rm -it --restart=Never \
  --image=artilleryio/artillery:2.0.22 \
  --command -- bash -c "curl -sL https://raw.githubusercontent.com/aws-containers/retail-store-sample-app/main/src/load-generator/scenario.yml -o /tmp/s.yml && curl -sL https://raw.githubusercontent.com/aws-containers/retail-store-sample-app/main/src/load-generator/helpers.js -o /tmp/helpers.js && cd /tmp && artillery run -t $TARGET /tmp/s.yml"
```

Якщо под має бути в тому ж namespace, що й UI (наприклад `ui-staging`), додайте `-n ui-staging`. Сценарій очікує `helpers.js` у тій самій директорії, що й scenario.yml — при завантаженні з GitHub обидва файли потрапляють у `/tmp/`, але в scenario вказано `processor: "./helpers.js"`; при запуску з `/tmp/s.yml` Artillery шукає helpers поруч, тобто `/tmp/helpers.js` — це ок.

**З ConfigMap/volume (скопійовані сценарії):**

(Note: Update `http://ui.ui.svc` to reflect your namespace structure)

```bash
$ cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: load-generator
spec:
  containers:
  - name: artillery
    image: artilleryio/artillery:2.0.22
    args:
    - "run"
    - "-t"
    - "http://ui.ui.svc"
    - "/scripts/scenario.yml"
    volumeMounts:
    - name: scripts
      mountPath: /scripts
  initContainers:
  - name: setup
    image: public.ecr.aws/aws-containers/retail-store-sample-utils:load-gen.1.2.1 <!-- x-release-please-version -->
    command:
    - bash
    args:
    - -c
    - "cp /artillery/* /scripts"
    volumeMounts:
    - name: scripts
      mountPath: "/scripts"
  volumes:
  - name: scripts
    emptyDir: {}
EOF
```

Note: Ensure the image tag of `retail-store-sample-load-generator` matches the version of the application being targeted.

#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Please provide network name for deployment and service port (e.g. 30000)..."
    exit 1
fi 

VERSION_TAG="v0.13"

echo ""
echo "DEPLOY VERSION $VERSION_TAG OF BUILT DOCKER CONTAINERS..."
echo ""

network="$1"
servicePort="$2"

# SET THE K8S CONTEXT
if [[ "$kubecontext" == "" ]];then
  kubecontext="ihelp-cluster-aws"
fi
kubectl="kubectl --context=$kubecontext"

deploy_file="deploy-$network.yaml"

mkdir -p pgdata/main
mkdir -p pgdata/data

cat << EOF > $deploy_file
apiVersion: v1
kind: Namespace
metadata:
  name: ihelp-$network
---
apiVersion: v1
kind: Service
metadata:
    name: ihelp-router
    namespace: ihelp-$network
spec:
    type: LoadBalancer
    selector:
        app: router
    ports:
    - name: "main"
      nodePort: $servicePort
      port: $servicePort
      targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: ihelp-db
  namespace: ihelp-$network
spec:
  ports:
  - name: db-port
    protocol: "TCP"
    port: 5432
    targetPort: 5432
  selector:
    app: db
---
apiVersion: v1
kind: Service
metadata:
  name: ihelp-client
  namespace: ihelp-$network
spec:
  ports:
  - name: client-port
    protocol: "TCP"
    port: 3000
    targetPort: 3000
  selector:
    app: client
---
apiVersion: v1
kind: Service
metadata:
  name: ihelp-server
  namespace: ihelp-$network
spec:
  ports:
  - name: server-port
    protocol: "TCP"
    port: 3001
    targetPort: 3001
  selector:
    app: server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ihelp-router
  namespace: ihelp-$network
spec:
  replicas: 1
  selector:
      matchLabels:
        app: router
  template:
    metadata:
      labels:
        app: router
    spec:
      containers:
      - name: router
        image: turbinex/ihelp-router:$VERSION_TAG
        imagePullPolicy: Always
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ihelp-client
  namespace: ihelp-$network
spec:
  replicas: 1
  selector:
      matchLabels:
        app: client
  template:
    metadata:
      labels:
        app: client
    spec:
      containers:
      - name: client
        image: turbinex/ihelp-client:$VERSION_TAG
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
        env:
        - name: PORT
          value: "3000"
        - name: REACT_APP_VERSION_TAG
          value: "$VERSION_TAG"
        envFrom:
        - secretRef:
           name: ihelp-secrets
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ihelp-server
  namespace: ihelp-$network
spec:
  replicas: 1
  selector:
      matchLabels:
        app: server
  template:
    metadata:
      labels:
        app: server
    spec:
      containers:
      - name: server
        image: turbinex/ihelp-server:$VERSION_TAG
        imagePullPolicy: Always
        ports:
        - containerPort: 3001
        env:
        - name: PORT
          value: "3001"
        envFrom:
        - secretRef:
           name: ihelp-secrets
        volumeMounts:
        - mountPath: /build
          name: contract-files
      volumes:
      - name: contract-files
        hostPath:
          path: ${PWD}/ihelp-contracts/build
          type: DirectoryOrCreate
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ihelp-db
  namespace: ihelp-$network
spec:
  replicas: 1
  selector:
      matchLabels:
        app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: db
        image: turbinex/ihelp-db:$VERSION_TAG
        imagePullPolicy: Always
        env:
        - name: POSTGRES_DB
          value: "ihelp"
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          value: "gisp123"
        securityContext:
          runAsUser: 0
          runAsGroup: 0
        ports:
        - containerPort: 5432
        volumeMounts:
        - mountPath: /var/lib/postgresql/10/main
          name: main-files
        - mountPath: /var/lib/postgresql/data
          name: data-files
      volumes:
      - name: main-files
        hostPath:
          path: ${PWD}/pgdata/main
          type: DirectoryOrCreate
      - name: data-files
        hostPath:
          path: ${PWD}/pgdata/data
          type: DirectoryOrCreate
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ihelp-listener
  namespace: ihelp-$network
spec:
  replicas: 1
  selector:
      matchLabels:
        app: listener
  template:
    metadata:
      labels:
        app: listener
    spec:
      containers:
      - name: listener
        image: turbinex/ihelp-scripts:$VERSION_TAG
        imagePullPolicy: Always
        command: ["node"]
        args: ["eventListenerWrapper.js"]
        envFrom:
        - secretRef:
           name: ihelp-secrets
        volumeMounts:
          - mountPath: /core/ihelp-contracts/deployments
            name: deploy-files
          - mountPath: /core/ihelp-contracts/artifacts
            name: contract-files
      volumes:
      - name: deploy-files
        hostPath:
          path: ${PWD}/ihelp-contracts/deployments
          type: DirectoryOrCreate
      - name: contract-files
        hostPath:
          path: ${PWD}/ihelp-contracts/artifacts
          type: DirectoryOrCreate
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ihelp-upkeep
  namespace: ihelp-$network
spec:
  schedule: "0 3 */1 * *" # at 3am UTC (10pm CST) every 1 days
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 86400
      activeDeadlineSeconds: 120
      template:
        metadata:
          labels:
            app: upkeep
        spec:
          restartPolicy: OnFailure
          containers:
          - name: upkeep
            image: turbinex/ihelp-scripts:$VERSION_TAG
            imagePullPolicy: Always
            workingDir: /core/ihelp-contracts
            command: ["node"]
            args: ["scripts/UPKEEP.js"]
            envFrom:
            - secretRef:
               name: ihelp-secrets
            volumeMounts:
              - mountPath: /core/ihelp-contracts/deployments
                name: deploy-files
              - mountPath: /core/ihelp-contracts/artifacts
                name: contract-files
          volumes:
          - name: deploy-files
            hostPath:
              path: ${PWD}/ihelp-contracts/deployments
              type: DirectoryOrCreate
          - name: contract-files
            hostPath:
              path: ${PWD}/ihelp-contracts/artifacts
              type: DirectoryOrCreate
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ihelp-reward
  namespace: ihelp-$network
spec:
  schedule: "0 4 */1 * *" # at 4am UTC (11pm CST) every 1 days
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 86400
      activeDeadlineSeconds: 120
      template:
        metadata:
          labels:
            app: reward
        spec:
          restartPolicy: OnFailure
          containers:
          - name: reward
            image: turbinex/ihelp-scripts:$VERSION_TAG
            imagePullPolicy: Always
            command: ["node"]
            args: ["REWARD.js"]
            envFrom:
            - secretRef:
               name: ihelp-secrets
            volumeMounts:
              - mountPath: /core/ihelp-contracts/deployments
                name: deploy-files
              - mountPath: /core/ihelp-contracts/artifacts
                name: contract-files
          volumes:
          - name: deploy-files
            hostPath:
              path: ${PWD}/ihelp-contracts/deployments
              type: DirectoryOrCreate
          - name: contract-files
            hostPath:
              path: ${PWD}/ihelp-contracts/artifacts
              type: DirectoryOrCreate
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ihelp-leaderboard
  namespace: ihelp-$network
spec:
  schedule: "*/3 * * * *" # every 3 minute
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 180
      activeDeadlineSeconds: 120
      template:
        metadata:
          labels:
            app: leaderboard
        spec:
          restartPolicy: OnFailure
          containers:
          - name: leaderboard
            image: turbinex/ihelp-scripts:$VERSION_TAG
            imagePullPolicy: Always
            command: ["node"]
            args: ["leaderboard.js"]
            envFrom:
            - secretRef:
               name: ihelp-secrets
            volumeMounts:
              - mountPath: /core/ihelp-contracts/deployments
                name: deploy-files
              - mountPath: /core/ihelp-contracts/artifacts
                name: contract-files
          volumes:
          - name: deploy-files
            hostPath:
              path: ${PWD}/ihelp-contracts/deployments
              type: DirectoryOrCreate
          - name: contract-files
            hostPath:
              path: ${PWD}/ihelp-contracts/artifacts
              type: DirectoryOrCreate
EOF

#echo $kubectl delete secret ihelp-secrets --ignore-not-found
$kubectl delete secret ihelp-secrets --ignore-not-found -n ihelp-$network

#echo $kubectl create secret generic ihelp-secrets --from-env-file=env/.env
$kubectl create secret generic ihelp-secrets --from-env-file=env/.env -n ihelp-$network

echo
echo $kubectl apply -f $deploy_file
$kubectl apply -f $deploy_file

echo
echo "FORCE RESTART COMMAND IF NEEDED:"
echo $kubectl rollout restart deployment -n ihelp-$network
echo
#$kubectl rollout restart deployment -n ihelp-$network

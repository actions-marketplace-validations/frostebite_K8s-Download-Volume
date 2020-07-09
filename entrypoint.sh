#!/bin/sh -l
kubectl version
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ftpjob-$GITHUB_SHA
spec:
  template:
    spec:
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: $1
      restartPolicy: Never
      containers:
      - name: ftpserver
        image: nginx:latest
        volumeMounts:
        - name: data
          mountPath: /data
EOF
kubectl wait --for=condition=ready pod -l job-name=ftpjob-$GITHUB_SHA --timeout=60s
kubectl exec jobs/ftpjob-$GITHUB_SHA -- ls /data/repo
kubectl exec jobs/ftpjob-$GITHUB_SHA -- apt-get update
kubectl exec jobs/ftpjob-$GITHUB_SHA -- apt-get install zip unzip
kubectl exec jobs/ftpjob-$GITHUB_SHA -- zip -r /output.zip /data/$2
kubectl cp jobs/ftpjob-$GITHUB_SHA:/output.zip $pwd
ls
kubectl delete jobs/ftpjob-$GITHUB_SHA
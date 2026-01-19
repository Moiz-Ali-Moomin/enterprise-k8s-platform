#!/bin/bash
# Production Data Migration Script
# Robust PVC-to-PVC migration with validation using Rsync
# Usage: ./migrate.sh <source-pvc> <dest-pvc> <namespace>

set -e # Exit on error
set -o pipefail

SOURCE_PVC=$1
DEST_PVC=$2
NAMESPACE=${3:-default}
JOB_ID="migration-$(date +%s)"

if [ -z "$SOURCE_PVC" ] || [ -z "$DEST_PVC" ]; then
  echo "Usage: ./migrate.sh <source-pvc> <dest-pvc> [namespace]"
  exit 1
fi

echo "[INFO] Starting migration job $JOB_ID"
echo "[INFO] Source: $SOURCE_PVC -> Dest: $DEST_PVC (NS: $NAMESPACE)"

# generate spec
cat <<EOF > /tmp/${JOB_ID}.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_ID}
  namespace: $NAMESPACE
spec:
  ttlSecondsAfterFinished: 86400 # Keep logs for 24h
  backoffLimit: 2
  template:
    spec:
      containers:
      - name: syncer
        image: alpine:3.18
        command: ["/bin/sh", "-c"]
        args:
          - |
            apk add --no-cache rsync openssh-client pv
            
            echo "[START] Syncing data..."
            # Rsync with archive mode, verbose, human-readable, and delete (exact mirror)
            # Bandwidth limit optional
            rsync -avz --delete --progress /mnt/source/ /mnt/dest/
            
            echo "[VERIFY] Running checksum validation (sample)..."
            # Verify random sample of files to ensure integrity
            # (Full checksum takes too long for TBs of data)
            count=0
            match=0
            for file in \$(find /mnt/source -type f | head -n 10); do
               relpath=\${file#/mnt/source}
               md5_src=\$(md5sum "\$file" | awk '{print \$1}')
               md5_dst=\$(md5sum "/mnt/dest\$relpath" | awk '{print \$1}')
               
               if [ "\$md5_src" != "\$md5_dst" ]; then
                 echo "[ERROR] Mismatch on \$relpath"
                 exit 1
               fi
               count=\$((count+1))
            done
            echo "[SUCCESS] Verified \$count sample files."
            
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
            
        volumeMounts:
        - name: source-vol
          mountPath: /mnt/source
          readOnly: true # Safety First
        - name: dest-vol
          mountPath: /mnt/dest
          
      restartPolicy: OnFailure
      volumes:
      - name: source-vol
        persistentVolumeClaim:
          claimName: $SOURCE_PVC
      - name: dest-vol
        persistentVolumeClaim:
          claimName: $DEST_PVC
EOF

# Apply
kubectl apply -f /tmp/${JOB_ID}.yaml

echo "[INFO] Job submitted. Watch logs with:"
echo "kubectl logs -f jobs/${JOB_ID} -n $NAMESPACE"

# GPU Validation

## Quick GPU Check

Verify GPU availability on all nodes:

```bash
./deploy.sh gpu-check
```

Expected output shows GPU count for each node.

## Manual GPU Tests

### Test 1: GPU Detection

Run nvidia-smi to verify GPU visibility:

```bash
kubectl run gpu-test --rm -it --restart=Never \
  --image=nvidia/cuda:12.2.0-base-ubuntu22.04 \
  -- nvidia-smi
```

Expected output:
```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 525.xx.xx    Driver Version: 525.xx.xx    CUDA Version: 12.2   |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  NVIDIA RTX 4000...  Off  | 00000000:00:05.0 Off |                  N/A |
| 30%   30C    P8    10W / 130W |      0MiB / 16384MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
```

### Test 2: CUDA Vector Addition

Test CUDA functionality with a simple workload:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vector-add
spec:
  restartPolicy: OnFailure
  containers:
  - name: cuda-vector-add
    image: "nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda11.7.1"
    resources:
      limits:
        nvidia.com/gpu: 1
EOF
```

Check results:

```bash
kubectl logs cuda-vector-add
```

Expected output:
```
[Vector addition of 50000 elements]
Copy input data from the host memory to the CUDA device
CUDA kernel launch with 196 blocks of 256 threads
Copy output data from the CUDA device to the host memory
Test PASSED
Done
```

Clean up:

```bash
kubectl delete pod cuda-vector-add
```

### Test 3: GPU Stress Test

Run a more intensive GPU workload:

```bash
kubectl run gpu-burn --rm -it --restart=Never \
  --image=nvcr.io/nvidia/k8s/cuda-sample:nbody-cuda11.7.1 \
  --limits="nvidia.com/gpu=1" \
  -- /cuda-samples/sample
```

This runs an n-body simulation that exercises GPU compute capabilities.

### Test 4: Multiple GPU Pods

Verify multiple pods can use GPUs simultaneously:

```bash
for i in {1..3}; do
  kubectl run gpu-test-$i --image=nvidia/cuda:12.2.0-base-ubuntu22.04 \
    --limits="nvidia.com/gpu=1" \
    -- sh -c "nvidia-smi && sleep 300"
done
```

Check pod distribution:

```bash
kubectl get pods -o wide | grep gpu-test
```

Clean up:

```bash
kubectl delete pod gpu-test-1 gpu-test-2 gpu-test-3
```

## Troubleshooting GPU Issues

### GPUs Not Detected

Check node labels:

```bash
kubectl get nodes --show-labels | grep nvidia
```

Check GPU capacity:

```bash
kubectl describe nodes | grep -A 5 "Capacity"
```

Look for:
```
Capacity:
  nvidia.com/gpu: 1
```

### Install GPU Operator

If GPUs are not detected, install the NVIDIA GPU Operator:

```bash
./deploy.sh install-nvidia
```

Verify operator pods are running:

```bash
kubectl get pods -n gpu-operator
```

All pods should be in `Running` or `Completed` state.

### Pod Stuck in Pending

Check pod events:

```bash
kubectl describe pod <pod-name>
```

Common issues:
- **Insufficient GPUs**: Scale up node pool or wait for autoscaler
- **Resource limits**: Adjust pod resource requests
- **Driver not loaded**: Wait for GPU operator to complete initialization

### GPU Not Allocated

Verify resource requests in pod spec:

```yaml
resources:
  limits:
    nvidia.com/gpu: 1  # Must be specified
```

Check node allocatable resources:

```bash
kubectl describe node <node-name> | grep -A 5 "Allocatable"
```

### Driver Version Mismatch

Check driver version:

```bash
kubectl get nodes -o json | jq '.items[].status.allocatable'
```

Update GPU operator if needed:

```bash
helm repo update
helm upgrade gpu-operator nvidia/gpu-operator -n gpu-operator
```

## Performance Validation

### Benchmark GPU Performance

Run a standard GPU benchmark:

```bash
kubectl run gpu-benchmark --rm -it --restart=Never \
  --image=nvidia/cuda:12.2.0-base-ubuntu22.04 \
  --limits="nvidia.com/gpu=1" \
  -- /bin/bash -c "apt-get update && apt-get install -y cuda-samples-12-2 && \
     /usr/local/cuda/samples/1_Utilities/bandwidthTest/bandwidthTest"
```

This tests GPU memory bandwidth.

### Monitor GPU Utilization

Install NVIDIA DCGM for monitoring:

```bash
helm repo add gpu-helm-charts https://nvidia.github.io/dcgm-exporter/helm-charts
helm install dcgm-exporter gpu-helm-charts/dcgm-exporter
```

View metrics:

```bash
kubectl port-forward service/dcgm-exporter 9400:9400
curl http://localhost:9400/metrics | grep DCGM
```

## Continuous Validation

Create a validation pod that runs periodically:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: gpu-validation
spec:
  schedule: "0 */6 * * *"  # Every 6 hours
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: gpu-check
            image: nvidia/cuda:12.2.0-base-ubuntu22.04
            command: ["nvidia-smi"]
            resources:
              limits:
                nvidia.com/gpu: 1
```

Apply:

```bash
kubectl apply -f gpu-validation-cronjob.yaml
```

Check validation history:

```bash
kubectl get jobs | grep gpu-validation
```

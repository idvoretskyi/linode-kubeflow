# Troubleshooting

## Common Issues

### GPU Not Detected

**Symptoms:**
- `nvidia-smi` command fails in pods
- No `nvidia.com/gpu` resource in node capacity
- GPU pods stuck in pending state

**Solutions:**

1. Check node labels:
```bash
kubectl get nodes --show-labels | grep nvidia
```

2. Check GPU capacity:
```bash
kubectl describe nodes | grep -A 5 "Capacity"
```

3. Install NVIDIA GPU Operator:
```bash
./deploy.sh install-nvidia
```

4. Verify operator status:
```bash
kubectl get pods -n gpu-operator
kubectl logs -n gpu-operator -l app=nvidia-driver-daemonset
```

5. Check driver installation:
```bash
kubectl exec -n gpu-operator <driver-pod> -- nvidia-smi
```

### Cluster Access Issues

**Symptoms:**
- Unable to connect with kubectl
- Connection timeout errors
- Authentication failures

**Solutions:**

1. Verify kubeconfig:
```bash
echo $KUBECONFIG
cat $KUBECONFIG
ls -l $(cd tofu && tofu output -raw kubeconfig_path)
```

2. Test cluster connection:
```bash
kubectl cluster-info
kubectl get nodes
```

3. Check firewall rules:
```bash
linode-cli firewalls list
```

4. Verify your IP is allowed:
```bash
curl -s https://api.ipify.org  # Your current IP
# Compare with allowed_kubectl_ips in tofu/tofu.tfvars
```

5. Update firewall if needed:
```bash
# Edit tofu/tofu.tfvars
allowed_kubectl_ips = ["YOUR_IP/32"]

# Apply changes
./deploy.sh apply
```

### Node Not Ready

**Symptoms:**
- Nodes show `NotReady` status
- Pods not scheduling
- Cluster degraded

**Solutions:**

1. Check node status:
```bash
kubectl get nodes
kubectl describe node <node-name>
```

2. Check system pods:
```bash
kubectl get pods -n kube-system
kubectl logs -n kube-system <failing-pod>
```

3. Check node conditions:
```bash
kubectl get nodes -o json | jq '.items[].status.conditions'
```

4. Common causes:
   - Network issues: Check Calico pods
   - Disk pressure: Check node disk usage
   - Memory pressure: Check node memory
   - Kubelet issues: Check kubelet logs

### OpenTofu Issues

**Symptoms:**
- `tofu plan` or `tofu apply` fails
- State lock errors
- Provider initialization failures

**Solutions:**

1. Validate configuration:
```bash
./deploy.sh validate
```

2. Check OpenTofu state:
```bash
cd tofu
tofu state list
tofu state show <resource>
```

3. Handle state locks:
```bash
# List current locks
tofu force-unlock -force <lock-id>
```

4. Re-initialize if needed:
```bash
./deploy.sh clean
./deploy.sh init
```

5. Check provider versions:
```bash
cd tofu
tofu version
tofu providers
```

### Deployment Failures

**Symptoms:**
- Deployment hangs or times out
- Resources not created
- Partial deployment

**Solutions:**

1. Check Linode service status:
```bash
linode-cli events list --action lke_cluster_create
```

2. Verify GPU availability in region:
```bash
linode-cli linodes types --format "id,label,gpus,region_prices" | grep gpu
```

3. Check quota limits:
```bash
linode-cli account view
```

4. Review OpenTofu logs:
```bash
TF_LOG=DEBUG ./deploy.sh apply 2>&1 | tee deploy.log
```

5. Retry deployment:
```bash
./deploy.sh destroy
./deploy.sh apply
```

### Pod Scheduling Issues

**Symptoms:**
- Pods stuck in `Pending` state
- GPU pods not starting
- Insufficient resources errors

**Solutions:**

1. Describe pod:
```bash
kubectl describe pod <pod-name>
```

2. Check events:
```bash
kubectl get events --sort-by='.lastTimestamp'
```

3. Common causes:
   - **Insufficient GPUs**: Scale node pool or wait for autoscaler
   ```bash
   # Edit tofu/tofu.tfvars
   gpu_node_count = 3
   ./deploy.sh apply
   ```

   - **Resource limits too high**: Adjust pod spec
   ```yaml
   resources:
     limits:
       nvidia.com/gpu: 1
       memory: 8Gi
     requests:
       memory: 4Gi
   ```

   - **Node selector mismatch**: Check node labels
   ```bash
   kubectl get nodes --show-labels
   ```

### Authentication Issues

**Symptoms:**
- `linode-cli` commands fail
- API token errors
- Permission denied

**Solutions:**

1. Verify linode-cli configuration:
```bash
linode-cli configure get token
```

2. Reconfigure if needed:
```bash
linode-cli configure
```

3. Test API access:
```bash
linode-cli regions list
```

4. Check token permissions:
- Log in to Linode Cloud Manager
- Navigate to API Tokens
- Verify token has required scopes

5. Set token explicitly:
```bash
export LINODE_TOKEN="your-token-here"
./deploy.sh apply
```

### Network Issues

**Symptoms:**
- Pod-to-pod communication fails
- DNS resolution issues
- External connectivity problems

**Solutions:**

1. Check Calico pods:
```bash
kubectl get pods -n kube-system | grep calico
```

2. Test DNS:
```bash
kubectl run dns-test --rm -it --restart=Never \
  --image=busybox:1.28 \
  -- nslookup kubernetes.default
```

3. Check network policies:
```bash
kubectl get networkpolicies --all-namespaces
```

4. Verify CoreDNS:
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

5. Test external connectivity:
```bash
kubectl run curl-test --rm -it --restart=Never \
  --image=curlimages/curl \
  -- curl -I https://www.google.com
```

## Performance Issues

### Slow GPU Operations

1. Check GPU utilization:
```bash
kubectl exec <pod-name> -- nvidia-smi
```

2. Monitor GPU metrics:
```bash
kubectl top nodes
```

3. Check for throttling:
```bash
kubectl describe node <node-name> | grep -i throttle
```

### High Costs

1. Review running resources:
```bash
./deploy.sh status
```

2. Check node pool size:
```bash
kubectl get nodes
```

3. Scale down when not in use:
```bash
# Edit tofu/tofu.tfvars
gpu_node_count = 1

# Or destroy completely
./deploy.sh destroy
```

## Getting Help

If issues persist:

1. **Check logs**:
```bash
kubectl logs <pod-name>
kubectl describe <resource-type> <resource-name>
```

2. **Export cluster info**:
```bash
kubectl cluster-info dump > cluster-dump.txt
```

3. **Review OpenTofu state**:
```bash
cd tofu
tofu show > state-export.txt
```

4. **Consult documentation**:
- [Linode Kubernetes Engine Docs](https://www.linode.com/docs/products/compute/kubernetes/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)

5. **Community support**:
- Linode Community Questions
- Kubernetes Slack
- CNCF Slack #linode channel

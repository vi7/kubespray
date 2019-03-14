vdmitriev-sbx.local cluster notes
=================================

---
**WARNING**

Stuff located in [this](./) dir is under the active development. README might not always depict the reality.

---

### table of contents:

- [versions](#versions)
- [cluster topology](#cluster-topology)
- [prerequisites](#prerequisites)
- [bootstrap cluster](#bootstrap-cluster)
- [post-bootstrap steps](#post-bootstrap-steps)
- [use cluster](#use-cluster)
  * [configure kubectl](#configure-kubectl)
  * [cluster admin service account](#cluster-admin-service-account)
  * [monitoring](#monitoring)
  * [helm](#helm)
  * [glusterfs](#glusterfs)
  * [metallb](#metallb)
  * [ingress controller](#ingress-controller)
- [known issues](#known-issues)
  * [kubespray](#kubespray)
  * [heketi glusterfs](#heketi-glusterfs)
  * [metallb issues](#metallb-issues)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


### versions

- kubespray - latest `release-2.8` branch
- ansible - 2.7.5
- kubernetes - v1.12.5
- helm - v2.12.2


### cluster topology

check [hosts.yml](./hosts.yml) for the up-to-date cluster topology


### prerequisites

The following should be performed at the _control machine_ (host which you will use to manage your k8s cluster configs and eventually spin up cluster itself).

Cluster installation:

1. install ius repo: `yum -y install https://centos7.iuscommunity.org/ius-release.rpm`
2. install pip and python3: `yum -y install python-pip python36u`
3. install ansible: `pip install ansible==2.7.5`
4. create link for python3: `ln -s /usr/bin/python3.6 /usr/bin/python3`

> Python above has been installed from the IUS repo, you can install it from the EPEL as well, but the version may be slightly older.
> 
> Python 3 seems to be only needed by the ansible inv generation script (see [bootstrap cluster](#bootstrap-cluster) p.4), so if you will handle your [ansible inv](./hosts.yml) manually do not bother about Python 3

Cluster usage and management:

1. install [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
2. install [`Helm` client](https://github.com/helm/helm/releases)


### bootstrap cluster

1. clone https://github.com/kubernetes-sigs/kubespray and create branch for your cluster configs
    - `git checkout release-2.8`
    - `git checkout -b vdmitriev_sbx`

2. install python packages required by the Kubespray
    - `pip install -r requirements.txt`

3. create cluster config and inventory from sample
    
    ```sh
    cp -rfp inventory/sample inventory/vdmitriev-sbx.local
    ```

    The following has been overridden for _this specific sandbox cluster_ (that is vars not mentioned below left as is):

    - [inventory/vdmitriev-sbx.local/group_vars/k8s-cluster/k8s-cluster.yml](../../inventory/vdmitriev-sbx.local/group_vars/k8s-cluster/k8s-cluster.yml):

            kube_version: v1.12.5
            kube_network_plugin: weave
            cluster_name: vdmitriev-sbx.local
            kubeconfig_localhost: true
    
4. create Ansible inventory file using [inventory builder](../../contrib/inventory_builder/inventory.py)

    > NOTE: IPs below are subject to change.
    
    > Kubespray will change hostnames of all your hosts to `node[1..n]`. To avoid that see step 5.
    
    ! DO NOT RUN THAT IF YOU CHANGED INVENTORY FILE MANUALLY BECAUSE IT'LL SCREW UP ALL YOU CHANGES !

    ```sh
    declare -a CLUSTER_IPS=(172.22.4.217 172.22.4.58 172.22.4.50 172.22.4.59 172.22.4.60)
    CONFIG_FILE=inventory/vdmitriev-sbx.local/hosts.ini python3 contrib/inventory_builder/inventory.py ${CLUSTER_IPS[@]}
    ```

5. inventory hacks
    - migrate inventory to the yaml format
    - change hostnames for the inventory (node1 etc.) to much the original hostnames of the VMs
    - add ssh connection user so you won't need to each time pass it to the ansible commands: 
        ```yaml
        all:
          vars:
            ansible_user: vdmitriev
        ```

    It's also recommended to not use the same hosts for master and worker nodes at the same time. That is your inventory groups `[kube-master]` and `[kube-node]` should not intersect

6. launch cluster

    - add VMs ssh key to the ssh agent:
        ```sh
        eval `ssh-agent -s`
        ssh-add <path/to/your/ssh_key>
        ```

    - run the following ([cluster.yml](../../cluster.yml) playbook wrapper with some additional hacks - check the script for the details):
        ```sh
        inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh start_cluster
        ```


### post-bootstrap steps

There is a possibility to trigger separate steps of the Kubespray. This is achieved by passing specific tags to Ansible. Details on the available tags can be obtained [here](../../docs/ansible.md)


### use cluster

#### configure kubectl

Cluster kubeconfig with cluster admin access is generated as a part of bootstrap and placed to: [inventory/vdmitriev-sbx.local/artifacts/admin.conf](../../inventory/vdmitriev-sbx.local/artifacts/admin.conf)

Cluster management is performed via `kubectl` utility which should be installed at the control machine. See [prerequisites](#prerequisites) above.

Example:
```sh
export KUBECONFIG=<path-to-kubespray-repo>/inventory/<cluster-name>/artifacts/admin.conf
kubectl get nodes
kubectl cluster-info
```

`kubectl` is also preconfigured at all cluster nodes

> kubectl bash completion can be enabled by adding the following line to your .bashrc: `source <(kubectl completion bash)`

#### cluster admin service account

Subj service account is useful for sandboxing purposes (eg. accessing Kubernetes Dashboard). You should not normally create cluster admin service accounts for random purposes in production!

Create account:
```sh
inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh cluster_admin_create
```

Get account token:
```sh
inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh cluster_admin_token
```

#### monitoring

Cluster and services monitoring are performed by Prometheus.

Details can be found in the corresponding [README](custom_scripts/k8s/operators/prometheus/README.md)

#### helm

You should have Helm client installed at your control machine to proceed. See [prerequisites](#prerequisites) above.

> helm bash completion can be enabled by adding the following line to your .bashrc: `source <(helm completion bash)`

Tiller, the server portion of Helm, should be installed the following way:
```sh
inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh helm_init

```

To remove tiller from your cluster do the following:
```sh
inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh helm_kill

```

#### glusterfs

Usage options:

1. Standalone GlusterFS cluster (oVirt based `k8s` glusterfs volume for this PoC). Create endpoints and service (for endpoints persistence between k8s reboots)
    ```sh
    kubectl apply -f inventory/vdmitriev-sbx.local/custom_scripts/k8s/ovirt-glusterfs-endpoints.yml
    ```

    Container spec example:
    ```yaml
    ...
    spec:
      containers:
      - name: test-container
        image: alpine
        command: ['sh']
        stdin: true
        tty: true
        volumeMounts:
          - mountPath: /mnt/test_depl_data
            name: test-depl-vol
      volumes:
        - name: test-depl-vol
          glusterfs:
            endpoints: ovirt-glusterfs
            path: k8s
    ...
    ```

    **SUMMARY**

    Cons:

    - volumes should be managed by some mechanism outside of a K8S cluster which makes procedure of volume claiming complex (i.e. not fully controlled by the K8S cluster)
    - containers are writing to the volume directly which might end up with huge amount of files per volume and break GlusterFS sync mechanism


    TODO: try volume management with Heketi, thus allowing external GlusterFS being managed by K8S

2. GlusterFS deployed into the K8S cluster and managed by Heketi. Check here for the details: [contrib/network-storage/heketi/](../../contrib/network-storage/heketi/)

    **Deploy**

    - 3 nodes required

    - install jmespath at the control machine
        ```sh
        pip install jmespath
        ```

    - run heketi playbook
        ```sh
        export ANSIBLE_REMOTE_TMP="/tmp"
        ansible-playbook -i inventory/vdmitriev-sbx.local/hosts.yml contrib/network-storage/heketi/heketi.yml -b -vv
        ```

    **Tear down**

    - run tear down playbook
        ```sh
        export ANSIBLE_REMOTE_TMP="/tmp"
        ansible-playbook -i inventory/vdmitriev-sbx.local/hosts.yml contrib/network-storage/heketi/heketi-tear-down.yml -b -vv
        inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh gluster_cleanup
        ```

    **SUMMARY**

    Pros:

    - fully self-contained solution within K8S cluster

    Cons:

    - high complexity of the official GlusterFS docker image: https://hub.docker.com/r/gluster/gluster-centos/dockerfile, which requires full access to the host in a runtime including log writing to the host `/var/log`, meaning GlusterFS is not "container-ready" and has no big differences to the host GlusterFS deployment
    - containers are writing to the volume directly which might end up with huge amount of files per volume and break GlusterFS sync mechanism

#### metallb

MetalLB installation should be managed via Helm using official Helm chart. In spite of what is written in the official MetalLB docs, Helm chart installs the latest available MetalLB.

Custom MetalLB values are [here](../../inventory/vdmitriev-sbx.local/custom_scripts/k8s/helm_values/metallb/values.yaml)

MetalLB release installation:
```sh
inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh metallb_install
```

MetalLB release upgrade:
```sh
inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh metallb_upgrade
```

#### ingress controller

[haproxy-ingress](https://github.com/jcmoraisjr/haproxy-ingress) is used as an ingress controller

Ingress controller installation is managed via [Helm chart](https://github.com/helm/charts/tree/master/incubator/haproxy-ingress). You should enable Helm incubator repo in order to get access to this chart:
```sh
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
```

Custom values are [here](../../inventory/vdmitriev-sbx.local/custom_scripts/k8s/helm_values/haproxy-ingress/values.yaml)

haproxy-ingress release installation:
```sh
inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh haproxy_ing_install
```

haproxy-ingress release upgrade:
```sh
inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh haproxy_ing_upgrade
```

### known issues

#### kubespray

1. **BUG** - **FIXED** - "Disable swap" task is failing on CentOS 7 at [roles/kubernetes/preinstall/tasks/0010-swapoff.yml](../../roles/kubernetes/preinstall/tasks/0010-swapoff.yml) cause `swapoff` bin is in the `/usr/sbin` dir which is not a part of the default PATH for ansible.

    Role fixed by adding the `/sbin:/usr/sbin` to the environment of the swapoff task

    ------

    TODO: submit PR to the kubespray. Default ansible PATH for CentOS 7 which is not including "sbin" dirs:

    ```sh
    ansible all -i 10.0.2.15, --private-key private_key -u vagrant -a 'echo $PATH'
    
    10.0.2.15 | CHANGED | rc=0 >>
    /usr/local/bin:/usr/bin

    ansible all -i 10.0.2.15, --private-key private_key -u vagrant -m shell -a 'echo $PATH'
    
    10.0.2.15 | CHANGED | rc=0 >>
    /usr/local/bin:/usr/bin
    ```

    ------

2. **BUG** - **WORKAROUND** - coredns (or kube-dns) addon installation is failing at the task "Kubernetes Apps | Start Resources" inside [roles/kubernetes-apps/ansible/tasks/main.yml](../../roles/kubernetes-apps/ansible/tasks/main.yml)

    Reason:

    default value for the `result` var will never be assigned when parent var is not defined thus causing the task to fail:
    ```yaml
    with_items:
        - "{{ kubedns_manifests.results | default({}) }}"
        - "{{ coredns_manifests.results | default({}) }}"
        - "{{ coredns_secondary_manifests.results | default({}) }}"
    ```

    TODO: try setting `kubedns_manifests: {}` at the k8s-cluster.yml to fix the issue without code changes

#### heketi glusterfs

1. **BUG** - **FIXED** - tasks with LVM commands are failing on CentOS 7 at [contrib/network-storage/heketi/roles/tear-down-disks/tasks/main.yml](../../contrib/network-storage/heketi/roles/tear-down-disks/tasks/main.yml) cause LVM utils bins are in the `/usr/sbin` dir which is not a part of the default PATH for ansible.

Fixed by adding the `/sbin:/usr/sbin` to the environment of the tasks

2. **BUG** - **FIXED** - improper syntax of the assert tasks at [contrib/network-storage/heketi/roles/provision/tasks/secret.yml](../../contrib/network-storage/heketi/roles/provision/tasks/secret.yml)

3. **BUG** - **WORKAROUND** - `lvmetad.socket` issue. Supposed to happen after `heketi-tear-down.yml` execution

        /run/lvm/lvmetad.socket: connect failed: Connection refused                                                                                                                                                                        
        WARNING: Failed to connect to lvmetad. Falling back to device scanning.

    currently solved by manual restart of the lvmetad.socket on all the nodes:
    ```sh
    systemctl restart lvm2-lvmetad.socket
    ```

4. **BUG** - **FIXED** - `heketi-tear-down.yml` execution doesn't cleanup directories on the nodes

    examples of gluster/heketi pathes which should be cleaned up:
    - [contrib/network-storage/heketi/roles/provision/templates/glusterfs-daemonset.json.j2](../../contrib/network-storage/heketi/roles/provision/templates/glusterfs-daemonset.json.j2)

    Fixed by adding cleanup function to the cluster_operations script:
    ```sh
    inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh gluster_cleanup
    ```

#### metallb issues

1. **BUG** - **WORKAROUND** - MetalLB doesn't handle properly `loadBalancerSourceRanges` paramter of the k8s service spec, thus blocking external access to the service when:
    ```yaml
    loadBalancerSourceRanges:
    - 0.0.0.0/0
    ```

    To workaround the issue `loadBalancerSourceRanges` param value should be explicitly empty for all services of a LoadBalancer type. Example from Jenkins helm chart values:
    ```yaml
    LoadBalancerSourceRanges: []
    ```

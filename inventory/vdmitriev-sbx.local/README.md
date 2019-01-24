vdmitriev-sbx.local cluster notes
=================================

---
**WARNING**

Stuff located in [this](./) dir is under the active development. README might not always depict the reality.

---

### contents:

- [versions](#versions)
- [nodes](#nodes)
- [prerequisites](#prerequisites)
- [bootstrap cluster](#bootstrap-cluster)
- [post-bootstrap steps](#post-bootstrap-steps)
- [use cluster](#use-cluster)
    - [configure kubectl](#configure-kubectl)
    - [cluster admin service account](#cluster-admin-service-account)
    - [helm](#helm)

### versions

- kubespray - latest `release-2.8` branch
- ansible - 2.7.5
- kubernetes - v1.12.5
- helm - v2.12.2

### nodes

- k8s node1: inw-vm41.rfiserve.net (172.22.4.217)
- k8s node2: inw-vm43.rfiserve.net (172.22.4.58)
- k8s node3: inw-vm52.rfiserve.net (172.22.4.59)
- k8s node4: inw-vm60.rfiserve.net (172.22.4.60)

### prerequisites

Install `pip` and `python3` at the control machine

1. install ius repo: `yum -y install https://centos7.iuscommunity.org/ius-release.rpm`
2. `yum -y install python-pip python36u`
3. `ln -s /usr/bin/python3.6 /usr/bin/python3`

Python above has been installed from the IUS repo, you can install it from the EPEL as well, but the version may be slightly older.

Install [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

Install [`Helm` client](https://github.com/helm/helm/releases)

### bootstrap cluster

1. clone https://github.com/kubernetes-sigs/kubespray
    - `git checkout release-2.8`
    - `git checkout -b vdmitriev_sbx`
2. `pip install -r requirements.txt`
3. create cluster config and inventory from sample
    
    ```sh
    cp -rfp inventory/sample inventory/vdmitriev-sbx.local
    ```

    The following has been overridden (that is vars not mentioned below left as is):

    - [inventory/vdmitriev-sbx.local/group_vars/k8s-cluster/k8s-cluster.yml](../../inventory/vdmitriev-sbx.local/group_vars/k8s-cluster/k8s-cluster.yml):

            kube_version: v1.12.5
            kube_network_plugin: weave
            cluster_name: vdmitriev-sbx.local
            kubeconfig_localhost: true
    
4. create Ansible inventory file using [inventory builder](../../contrib/inventory_builder/inventory.py)

    > NOTE: IPs below are subject to change.
    
    > By default hostnames of the hosts will be changed to `node[1..n]`. See step 5.
    
    ! DO NOT RUN THAT IF YOU CHANGED INVENTORY FILE MANUALLY BECAUSE IT'LL SCREW UP ALL YOU CHANGES !

    ```sh
    declare -a CLUSTER_IPS=(172.22.4.217 172.22.4.58 172.22.4.59 172.22.4.60)
    CONFIG_FILE=inventory/vdmitriev-sbx.local/hosts.ini python3 contrib/inventory_builder/inventory.py ${CLUSTER_IPS[@]}
    ```

5. inventory hacks
    - change hostnames for the inventory (node1 etc.) to much the original hostnames of the VMs (see them above)
    - add connection user so you won't need to each time pass it to the ansible commands: 
        ```ini
        [all:vars]
        ansible_user=vdmitriev
        ```

6. **BUG** - **FIXED** - "Disable swap" task is failing on CentOS 7 at [roles/kubernetes/preinstall/tasks/0010-swapoff.yml](../../roles/kubernetes/preinstall/tasks/0010-swapoff.yml) cause `swapoff` bin is in the `/usr/sbin` dir which is not a part of the default PATH for ansible.

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

7. VMs hacks

    Run the following:
    ```sh
    inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh prepare_host
    ```

8. launch cluster

    - add VMs ssh key to the ssh agent:
        ```sh
        eval `ssh-agent -s`
        ssh-add /root/.ssh/vdmitriev
        ```

    - create /home/vdmitriev and chown vdmitriev:engineering at all nodes for ansible to create tmp dir properly OR:
        ```sh
        export ANSIBLE_REMOTE_TMP="/tmp"
        ```

    - run playbook:
        ```sh
        ansible-playbook -i inventory/vdmitriev-sbx.local/hosts.ini cluster.yml -b -v
        ```

### post-bootstrap steps

There is a possibility to trigger separate steps of the Kubespray. This is achieved by passing specific tags to Ansible. For example if you need:

- to run K8S dashboard installation:
    ```sh
    ansible-playbook -i inventory/vdmitriev-sbx.local/hosts.ini cluster.yml -b -v -t dashboard
    ```

- to run weave networking installation:
    ```sh
    ansible-playbook -i inventory/vdmitriev-sbx.local/hosts.ini cluster.yml -b -v -t weave
    ```

More details on the available tags can be obtained [here](../../docs/ansible.md)

### use cluster

#### configure kubectl

Cluster kubeconfig with cluster admin access is generated as a part of bootstrap and placed to: [inventory/vdmitriev-sbx.local/artifacts/admin.conf](../../inventory/vdmitriev-sbx.local/artifacts/admin.conf)

Cluster management is performed via `kubectl` utility which should be installed at the control machine. See [prerequisites](#prerequisites) above.

Example:
```sh
export KUBECONFIG=<path-to-kubespray-repo>/inventory/vdmitriev-sbx.local/artifacts/admin.conf
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

#### helm

You should have Helm client installed at your control machine to proceed. See [prerequisites](#prerequisites) above.

> helm bash completion can be enabled by adding the following line to your .bashrc: `source <(helm completion bash)`

Tiller, the server portion of Helm, should be installed the following way:
```sh
inventory/vdmitriev-sbx.local/custom_scripts/cluster_operations.sh helm_init

```


glusterfs-playground.local cluster notes
========================================

### table of contents

### cluster topology

check [hosts.yml](./hosts.yml) for the up-to-date cluster topology

### K8S bootstrap

**kubespray group_vars**

The following has been overridden for _this specific cluster_ (that is vars not mentioned below left as is):

    - [inventory/glusterfs-playground.local/group_vars/k8s-cluster/k8s-cluster.yml](../../inventory/glusterfs-playground.local/group_vars/k8s-cluster/k8s-cluster.yml):

            kube_version: v1.14.1
            hyperkube_checksums:
              v1.14.1: fb34b98da9325feca8daa09bb934dbe6a533aad69c2a5599bbed81b99bb9c267
            kubeadm_checksums:
              v1.14.1: c4fc478572b5623857f5d820e1c107ae02049ca02cf2993e512a091a0196957b
            kube_network_plugin: weave
            cluster_name: glusterfs-playground.local
            kubeconfig_localhost: true

### Baremetal GlusterFS

check [hosts.yml](./hosts.yml) inventory `glusterfs` group for the up-to-date cluster topology

#### Basic GlusterFS configuration for tests

**Configure the trusted pool**

from inw-918:
```sh
gluster peer probe inw-920.rfiserve.net
```

from inw-920:
```sh
gluster peer probe inw-918.rfiserve.net
gluster peer probe inw-921.rfiserve.net
```

**Set up GlusterFS volume**

Create dirs:
```sh
ansible glusterfs  -i inventory/glusterfs-playground.local/hosts.yml -b  -m shell -a 'mkdir /bricks/brick1/gv0'
```

From any single server:
```sh
gluster volume create gv0 replica 3 inw-918.rfiserve.net:/bricks/brick1/gv0 inw-920.rfiserve.net:/bricks/brick1/gv0 inw-921.rfiserve.net:/bricks/brick1/gv0
gluster volume start gv0
```


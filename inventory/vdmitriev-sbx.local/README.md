vdmitriev-sbx.local cluster notes
---------------------------------

**versions**

kubespray - v2.8.1 (fetched from this specific tag)

**nodes**

control machine: inw-vm41.rfiserve.net (172.22.4.217)

k8s node1: inw-vm41.rfiserve.net (172.22.4.217)
k8s node2: inw-vm43.rfiserve.net (172.22.4.58)
k8s node3: inw-vm52.rfiserve.net (172.22.4.59)
k8s node4: inw-vm60.rfiserve.net (172.22.4.60)

**prerequisites**

Install pip and python3

1. install ius repo: `yum -y install https://centos7.iuscommunity.org/ius-release.rpm`
2. `yum -y install python-pip python36u`
3. `ln -s /usr/bin/python3.6 /usr/bin/python3`

**bootstrap cluster**

1. clone https://github.com/kubernetes-sigs/kubespray
    - `git checkout v2.8.1`
    - `git checkout -b vdmitriev_sbx`
2. `pip install -r requirements.txt`
3. create cluster config and inventory
    
    ```sh
    cp -rfp inventory/sample inventory/vdmitriev-sbx.local
    ```
    
4. update Ansible inventory file with inventory builder.
    
    ! DO NOT RUN THAT IF YOU CHANGED INVENTORY MANUALLY BECAUSE IT'LL SCREW UP ALL YOU ADDITIONS !

    ```sh
    declare -a CLUSTER_IPS=(172.22.4.217 172.22.4.58 172.22.4.59 172.22.4.60)
    CONFIG_FILE=inventory/vdmitriev-sbx.local/hosts.ini python3 contrib/inventory_builder/inventory.py ${CLUSTER_IPS[@]}
    ```

5. Inventory hacks:
    - change hostnames for the inventory (node1 etc.) to much the original hostnames of the VMs (see them above)
    - add connection user: 
        ```ini
        [all:vars]
        ansible_user=vdmitriev
        ```

5. "Disable swap" task is failing on CentOS 7 at [roles/kubernetes/preinstall/tasks/0010-swapoff.yml](./roles/kubernetes/preinstall/tasks/0010-swapoff.yml) cause `swapoff` command is in the /usr/sbin which is not a part of default PATH for ansible.

    TODO: fix the role by adding the absolute path: `/usr/sbin/swapoff`

6. launch cluster

    ```sh
    eval `ssh-agent -s`
    ssh-add /root/.ssh/vdmitriev

    # create /home/vdmitriev and chown vdmitriev:engineering at all nodes for ansible to create tmp dir properly OR:
    export ANSIBLE_REMOTE_TMP="/tmp"

    ansible-playbook -i inventory/vdmitriev-sbx.local/hosts.ini cluster.yml -b -v
    ```

TODO: FAILED on:

    TASK [download : Download items] ************************************************************************************************************************************
    Friday 18 January 2019  16:32:40 +0000 (0:00:00.055)       0:05:37.275 ******** 
    fatal: [inw-vm41.rfiserve.net]: FAILED! => {"msg": "'dict object' has no attribute u'v1.13.2'"}
    fatal: [inw-vm43.rfiserve.net]: FAILED! => {"msg": "'dict object' has no attribute u'v1.13.2'"}
    fatal: [inw-vm52.rfiserve.net]: FAILED! => {"msg": "'dict object' has no attribute u'v1.13.2'"}
    fatal: [inw-vm60.rfiserve.net]: FAILED! => {"msg": "'dict object' has no attribute u'v1.13.2'"}


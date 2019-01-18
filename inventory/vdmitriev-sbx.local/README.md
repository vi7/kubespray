vdmitriev-sbx.local cluster notes
---------------------------------

**versions**

kubespray - v2.8.1

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

5. launch cluster

    ```sh
    eval `ssh-agent -s`
    ssh-add /root/.ssh/vdmitriev

    # create /home/vdmitriev and chown vdmitriev:engineering at all nodes for ansible to create tmp dir properly

    ansible-playbook -i inventory/vdmitriev-sbx.local/hosts.ini cluster.yml -u vdmitriev -b -v
    ```

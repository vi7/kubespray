TODO list
=========

1. HA masters (at least for the external API access)
2. Review the longest steps in cluster spin up and optimize them if possible. Cluster spinup timing report:

  from the local vagrant:

        Friday 01 February 2019  16:25:11 +0000 (0:00:00.078)       0:21:16.187 ******* 
        =============================================================================== 
        etcd : Gen_certs | Write etcd master certs --------------------------------------------------- 107.31s
        kubernetes/master : kubeadm | write out kubeadm certs ----------------------------------------- 71.88s
        kubernetes/master : kubeadm | Initialize first master ----------------------------------------- 54.32s
        kubernetes/master : kubeadm | Init other uninitialized masters -------------------------------- 52.68s
        kubernetes-apps/ansible : Kubernetes Apps | Lay Down CoreDNS Template ------------------------- 44.61s
        container-engine/docker : ensure docker packages are installed -------------------------------- 38.84s
        gather facts from all instances --------------------------------------------------------------- 26.11s
        etcd : etcd | reload systemd ------------------------------------------------------------------ 24.87s
        download : file_download | Download item ------------------------------------------------------ 23.38s
        kubernetes/preinstall : Update package management cache (YUM) --------------------------------- 17.20s
        etcd : Gen_certs | Gather etcd master certs --------------------------------------------------- 17.02s
        kubernetes/kubeadm : Restart all kube-proxy pods to ensure that they load the new configmap --- 13.65s
        container-engine/docker : Ensure old versions of Docker are not installed. | RedHat ----------- 12.20s
        kubernetes-apps/ansible : Kubernetes Apps | Start Resources ----------------------------------- 11.93s
        etcd : reload etcd ---------------------------------------------------------------------------- 11.51s
        download : file_download | Download item ------------------------------------------------------ 10.91s
        container-engine/docker : Docker | pause while Docker restarts -------------------------------- 10.15s
        kubernetes/master : slurp kubeadm certs -------------------------------------------------------- 8.95s
        kubernetes-apps/network_plugin/weave : Weave | Wait for Weave to become available -------------- 8.34s
        etcd : wait for etcd up ------------------------------------------------------------------------ 8.29s

  from the inw-vm21.rfiserve.net VM (2 masters, 2 nodes):

        Monday 04 February 2019  10:36:19 -0500 (0:00:00.111)       0:15:04.531 *******
        ===============================================================================
        kubernetes/master : kubeadm | Initialize first master ------------------------------------------------------ 48.92s
        kubernetes/master : kubeadm | Init other uninitialized masters --------------------------------------------- 47.60s 
        container-engine/docker : ensure docker packages are installed --------------------------------------------- 39.43s 
        gather facts from all instances ---------------------------------------------------------------------------- 22.65s
        download : file_download | Download item ------------------------------------------------------------------- 21.71s 
        kubernetes/preinstall : Update package management cache (YUM) ---------------------------------------------- 17.09s 
        etcd : Gen_certs | Write etcd master certs ----------------------------------------------------------------- 13.01s 
        etcd : reload etcd ----------------------------------------------------------------------------------------- 10.92s
        download : file_download | Download item ------------------------------------------------------------------- 10.57s 
        container-engine/docker : Docker | pause while Docker restarts --------------------------------------------- 10.14s
        container-engine/docker : Ensure old versions of Docker are not installed. | RedHat ------------------------- 9.08s
        download : container_download | Download containers if pull is required or told to always pull (all nodes) -- 8.90s 
        kubernetes/preinstall : Install packages requirements ------------------------------------------------------- 7.53s
        etcd : wait for etcd up ------------------------------------------------------------------------------------- 7.43s
        download : Download items ----------------------------------------------------------------------------------- 6.85s 
        kubernetes/master : kubeadm | write out kubeadm certs ------------------------------------------------------- 6.77s
        download : Sync container ----------------------------------------------------------------------------------- 6.61s
        download : container_download | Download containers if pull is required or told to always pull (all nodes) -- 6.27s 
        etcd : Gen_certs | Gather etcd master certs ----------------------------------------------------------------- 5.83s
        kubernetes-apps/network_plugin/weave : Weave | Wait for Weave to become available --------------------------- 5.73s

from the inw-vm21.rfiserve.net VM (3 masters, 2 nodes):

        Thursday 07 February 2019  09:51:50 -0500 (0:00:00.244)       0:20:06.401 ***** 
        =============================================================================== 
        kubernetes/master : kubeadm | Initialize first master ------------------------------------------------------ 58.41s
        kubernetes/master : kubeadm | Init other uninitialized masters --------------------------------------------- 47.24s
        container-engine/docker : ensure docker packages are installed --------------------------------------------- 41.05s
        kubernetes/master : Master | reload kubelet ---------------------------------------------------------------- 39.88s
        gather facts from all instances ---------------------------------------------------------------------------- 28.27s
        download : file_download | Download item ------------------------------------------------------------------- 18.12s
        kubernetes/preinstall : Update package management cache (YUM) ---------------------------------------------- 17.57s
        kubernetes/kubeadm : Restart all kube-proxy pods to ensure that they load the new configmap ---------------- 14.44s
        etcd : Gen_certs | Write etcd master certs ----------------------------------------------------------------- 13.98s
        download : file_download | Download item ------------------------------------------------------------------- 11.93s
        etcd : reload etcd ----------------------------------------------------------------------------------------- 11.27s
        container-engine/docker : Docker | pause while Docker restarts --------------------------------------------- 10.18s
        container-engine/docker : Ensure old versions of Docker are not installed. | RedHat ------------------------- 9.77s
        download : Download items ----------------------------------------------------------------------------------- 9.77s
        kubernetes/preinstall : Hosts | populate inventory into hosts file ------------------------------------------ 9.63s
        kubernetes/preinstall : Install packages requirements ------------------------------------------------------- 8.82s
        download : container_download | Download containers if pull is required or told to always pull (all nodes) -- 8.12s
        download : Sync container ----------------------------------------------------------------------------------- 7.63s
        etcd : wait for etcd up ------------------------------------------------------------------------------------- 7.31s
        etcd : Gen_certs | Gather etcd master certs ----------------------------------------------------------------- 7.26s

3. Automatically add permissions for jenkins volume (1000:1000)
4. Implement proper master scaling (up and down) and nodes replacement
5. Implement proper etcd scaling (up and down) and nodes replacement
6. Migrate [hosts.ini](./hosts.ini) inventory to yaml format
7. Migrate [custom_scripts/prepare_host.yml](./custom_scripts/prepare_host.yml) to a separate ansible role

# Installing Accumulo services (master and tserver) into existing HDInsight with ESP

This git repo contains the modified Ansible playbooks that install Apache Accumulo master & tserver services into a HDInsight cluster with ESP enabled. The master services will be installed in head nodes, while tserver services will be setup in worker nodes.   

## Prerequsites
* When you set up your HDInsight cluster with ESP (https://docs.microsoft.com/en-us/azure/hdinsight/domain-joined/apache-domain-joined-configure-using-azure-adds#create-an-hdinsight-cluster-with-esp), make sure to use ssh key based admin login. In this recipe, we are using modified Ansible accumulo role from Apache fluo-muchos (https://github.com/apache/fluo-muchos) and thus ssh-key based login is required.

* Add/Create one Ubuntu linux VM (16.04 LTS or above) in the same VNET and subnet, having the same admin login name and the same ssh key. This VM will play the proxy role in Apache fluo-muchos, downloading a custom accumulo tarfile, running the modified accumulo playbook. We call this VM 'proxy' from now on.

* Get the list of head nodes, worker nodes, and zookeeper nodes. You may get the list of hosts from /etc/hosts file once you login into your first head node. We will create an ansible host file with these list in the following step.

* You have built or patched your accumulo tarfile with the kerberos patch (https://github.com/apache/accumulo/pull/1727/commits/b6a9ad000d261f201b6322031d34c60fcbbb9d5a). The patched tarfile will be downloaded in Ansible `'proxy'` playbook. Note that JRE installed in HDInsight is JRE-8 (as of 2H 2020), thus your tarfile should be compiled with matching JRE used. 

## Setup 
Login to your proxy VM with ssh and install ansible

```
sudo apt-add-repository ppa:ansible/ansible
sudo apt get update
sudo apt install ansible
```

Download the modified accumulo ansible playbooks from `https://github.com/sjyang18/accumulo-on-hdi.git`.
```
git clone https://github.com/sjyang18/accumulo-on-hdi.git
```

Add ~/.ansible.cfg with `ln` or create yours by copying out from ~/accumulo-on-hdi/ansible/config.
```
ln -s ~/accumulo-on-hdi/ansible/config/ansible.cfg ~/.ansible.cfg
```

Create your inventory file, using ~/accumulo-on-hdi/ansible/config/hosts.tpl as a template. Update headnodes, workers, and zookeepers with the list of hostnames you collected from pre-requisites and update the ansible variables according to your environment. We are not creating a new cluster with `'muchos launch'` and thus we are creating this inventory file as a setup step.    

## Run Ansible playbooks
Given your inventory file (i.e. hosts) saved in ~/accumulo-on-hdi, you change to the directory and run ansible playbooks.

```
ansible-playbook -i hosts ansible/proxy.yml
ansible-playbook -i hosts ansible/accumulo.yml
ansible-playbook -i hosts ansible/accumulo-final.yml
```


## Test and Validate Kerbero Authentication and Authorization thru AAD DS domain services
SSH login to the first head node in HDInsight cluster. Then, kinit with your admin account and get the path to the default cache from klist. For example, in my case,
```
kinit -V accumulo@AGCECI.ONMICROSOFT.COM
klist
Ticket cache: FILE:/tmp/krb5cc_2019
Default principal: accumulo@AGCECI.ONMICROSOFT.COM

Valid starting       Expires              Service principal
11/30/2020 18:09:19  12/01/2020 04:09:19  krbtgt/AGCECI.ONMICROSOFT.COM@AGCECI.ONMICROSOFT.COM
        renew until 12/07/2020 18:09:14
```

Copy ${ACCUMULO_HOME}/conf/accumulo-client.properties to $HOME of your login. And, update the value of auth.principal and auth.token with your admin account and the default cache path.

Run accumulo shell with your config file and test accumulo table creation and deletion. For example,

```
azureuser@hn1-hdisey:~$ /usr/share/accumulo-2.0.0/bin/accumulo shell --config-file ~/accumulo-client.properties
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/usr/share/accumulo-2.0.0/lib/slf4j-log4j12-1.7.26.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/usr/hdp/2.6.5.3026-7/hadoop/lib/slf4j-log4j12-1.7.10.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Log4jLoggerFactory]

Shell - Apache Accumulo Interactive Shell
-
- version: 2.0.0
- instance name: accumulo
- instance id: 23107a38-71a3-44ca-9b4d-b737fd78823f
-
- type 'help' for a list of available commands
-
accumulo@AGCECI.ONMICROSOFT.COM@accumulo> createtable test1
accumulo@AGCECI.ONMICROSOFT.COM@accumulo test1> droptable test1
droptable { test1 } (yes|no)? yes
Table: [test1] has been deleted.
accumulo@AGCECI.ONMICROSOFT.COM@accumulo>
accumulo@AGCECI.ONMICROSOFT.COM@accumulo>
```

Destroy the current kerberos key cache and login with non-admin account.
```
kdestory
kinit -V seyan@AGCECI.ONMICROSOFT.COM
klist
Ticket cache: FILE:/tmp/krb5cc_2019
Default principal: seyan@AGCECI.ONMICROSOFT.COM

Valid starting       Expires              Service principal
11/30/2020 18:25:20  12/01/2020 04:25:20  krbtgt/AGCECI.ONMICROSOFT.COM@AGCECI.ONMICROSOFT.COM
        renew until 12/07/2020 18:25:15
```

Update ~/accumulo-client.properties by setting non-admin account to auth.principal. Run the same test. Should see the permission error.
```
azureuser@hn1-hdisey:~$ /usr/share/accumulo-2.0.0/bin/accumulo shell --config-file ~/accumulo-client.properties
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/usr/share/accumulo-2.0.0/lib/slf4j-log4j12-1.7.26.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/usr/hdp/2.6.5.3026-7/hadoop/lib/slf4j-log4j12-1.7.10.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Log4jLoggerFactory]

Shell - Apache Accumulo Interactive Shell
-
- version: 2.0.0
- instance name: accumulo
- instance id: 23107a38-71a3-44ca-9b4d-b737fd78823f
-
- type 'help' for a list of available commands
-
seyan@AGCECI.ONMICROSOFT.COM@accumulo> createtable test1
2020-11-30 18:26:18,034 [shell.Shell] ERROR: org.apache.accumulo.core.client.AccumuloSecurityException: Error PERMISSION_DENIED for user seyan@AGCECI.ONMICROSOFT.COM on table test1(?) - User does not have permission to perform this action
```


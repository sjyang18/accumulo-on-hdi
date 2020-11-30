[headnodes]
XXX

[workers]
YYY

[zookeepers]
ZZZ


[accumulomaster:children]
headnodes

[accumulo:children]
headnodes
workers

[all:vars]
ansible_python_interpreter=/usr/bin/python3
accumulo_tarfile_url="https://aadshdi2hdistorage.blob.core.windows.net/accumulo/accumulo-2.0.0-kerberos-fix.tar.gz?sp=r&st=2020-11-25T02:42:10Z&se=2023-06-01T09:42:10Z&spr=https&sv=2019-12-12&sr=b&sig=FnmyFqfGFJ8vcsgqyTBhR5R0uSywX3GbMOI3vpTYxgo%3D"
accumulo_tmpfolder=/tmp/accumulo
accumulo_tarball=accumulo.tar.gz
accumulo_version=2.0.0
install_dir=/usr/share
accumulo_home='{{ install_dir }}/accumulo-{{ accumulo_version }}'
domain_name=YOUR_DOMAIN_NAME.ONMICROSOFT.COM
accumulo_admin_account='accumulo@{{ domain_name }}'
accumulo_instance_name=accumulo
accumulo_instance_volumn='hdfs://mycluster/{{ accumulo_instance_name }}'
accumulo_service_principal_keytabfile=/etc/security/keytabs/hive.service.keytab
accumulo_service_principal_login=hive
accumulo_service_principal='{{ accumulo_service_principal_login }}/_HOST@{{ domain_name }}'
accumulo_password=Secret
accumulo_major_version='2'
use_systemd=True
java_home=/usr/lib/jvm/java-8-openjdk-amd64
cluster_user={{ accumulo_service_principal_login }}
num_tservers=1

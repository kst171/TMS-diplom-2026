[aws_zabbix_servers]
zabbix-server ansible_host=${zabbix_public_ip} zabbix_private_ip=${zabbix_private_ip} ansible_user=ubuntu

[app_databases]
app-database         ansible_host=${database_primary_ip} ansible_user=ubuntu pg_role=primary
app-database-replica ansible_host=${database_replica_ip} ansible_user=ubuntu pg_role=replica

[app_databases:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ForwardAgent=yes -o ProxyCommand="ssh -W %h:%p -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${zabbix_public_ip}"'

[all:vars]
ansible_ssh_private_key_file=""
ansible_python_interpreter=/usr/bin/python3
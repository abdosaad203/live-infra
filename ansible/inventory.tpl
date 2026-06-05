[github_runners]
%{ for ip in runner_ips ~}
${ip}
%{ endfor ~}

[github_runners:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/depi-key.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
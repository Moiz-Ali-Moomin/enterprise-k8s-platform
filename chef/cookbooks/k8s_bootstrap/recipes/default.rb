# Production Chef Recipe: Kubernetes Bootstrap
# Cookbook:: k8s_bootstrap
# Recipe:: default

# 1. Update Apt Cache
apt_update 'update' do
  action :update
end

# 2. Install Dependencies
%w(apt-transport-https ca-certificates curl gnupg lsb-release).each do |pkg|
  package pkg do
    action :install
  end
end

# 3. Kernel Modules
modules = %w(overlay br_netfilter)

modules.each do |mod|
  kernel_module mod do
    action :load
  end
  
  file "/etc/modules-load.d/#{mod}.conf" do
    content mod
    mode '0644'
  end
end

# 4. Sysctl Params
sysctl_param 'net.bridge.bridge-nf-call-iptables' do
  value 1
end

sysctl_param 'net.ipv4.ip_forward' do
  value 1
end

# 5. Disable Swap (Critical)
mount 'swap' do
  action :disable
end

execute 'turn_off_swap' do
  command 'swapoff -a'
  only_if 'swapon -s | grep -q /dev'
end

# 6. Containerd Installation (Example of package resource)
execute 'add_docker_gpg' do
  command 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg'
  creates '/usr/share/keyrings/docker-archive-keyring.gpg'
end

apt_repository 'docker' do
  uri 'https://download.docker.com/linux/ubuntu'
  arch 'amd64'
  components ['stable']
  key 'https://download.docker.com/linux/ubuntu/gpg'
end

package 'containerd.io'

# 7. Configure Containerd
file '/etc/containerd/config.toml' do
  content 'version = 2
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
      SystemdCgroup = true'
  notifies :restart, 'service[containerd]', :immediately
end

service 'containerd' do
  action [:enable, :start]
end

# 8. Security: Create Developer User
user 'k8s-dev' do
  comment 'Kubernetes Developer'
  uid '1234'
  gid 'users'
  home '/home/k8s-dev'
  shell '/bin/bash'
  password '$6$xyz$saltlesspasswordhash' # Should use data bag in prod
end

# Production Puppet Manifest: Kubernetes Node Hardening
# Defines a profile for a secure Kubernetes Worker Node

class profile::k8s_node_hardening {

  # 1. System Packages (Dependencies)
  $packages = [ 'curl', 'apt-transport-https', 'socat', 'conntrack' ]
  package { $packages:
    ensure => installed,
  }

  # 2. Kernel Modules (Overlay & Netfilter)
  kmod::load { 'overlay': }
  kmod::load { 'br_netfilter': }

  # 3. Sysctl Tuning (Critical for K8s Networking)
  sysctl { 'net.bridge.bridge-nf-call-iptables':
    ensure => present,
    value  => '1',
  }
  
  sysctl { 'net.ipv4.ip_forward':
    ensure => present,
    value  => '1',
  }

  sysctl { 'vm.swappiness':
    ensure => present,
    value  => '0',
  }

  # 4. Disable Swap (Kubernetes Requirement)
  exec { 'disable-swap-active':
    command => '/sbin/swapoff -a',
    onlyif  => '/bin/grep -q "\\sswap\\s" /proc/swaps',
  }

  file_line { 'remove-swap-fstab':
    path    => '/etc/fstab',
    line    => '# Swap disabled by Puppet',
    match   => '.*swap.*',
    multiple => true,
  }

  # 5. SSH Hardening
  file_line { 'sshd-no-root':
    path   => '/etc/ssh/sshd_config',
    line   => 'PermitRootLogin no',
    match  => '^PermitRootLogin',
    notify => Service['ssh'],
  }

  service { 'ssh':
    ensure => running,
    enable => true,
  }

  # 6. Firewall (UFW) - Allow Kubelet & NodePort ranges
  exec { 'ufw-allow-kubelet':
    command => '/usr/sbin/ufw allow 10250/tcp',
    unless  => '/usr/sbin/ufw status | grep 10250',
  }
}

include profile::k8s_node_hardening

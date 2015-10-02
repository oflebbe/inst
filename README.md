# Installation Instruction

Install a machine with Debian-8 and install lxc and libvirt-daemon-system

* Create a libvirt managed priavte network with hadoop-net.xml
  virsh net-create inst/hadoop-net.xml

* merge the bigtop.org nodes from the file inst/repo/hosts with /etc/hosts

* be sure to run as root

* cd inst/inst

  
* Create the containers
  ./script-setup-machines

* Deploy puppet to all of then
  ./script-setup-pupppet

That's it




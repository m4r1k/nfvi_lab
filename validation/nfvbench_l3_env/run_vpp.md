# Steps to run FD.io VPP
FD.io VPP is a fully featured router developed by Cisco.
VPP supports all of the typical routing featurs and lavarage DPDK for fast packet forwarding.
Additionally VPP embvrace a number of low-level optimization to deliver really high performance.
For the purpose of this test, we're going to use it to route back the traffic sent by NFVBench.
All documentation can be found [here](https://docs.fd.io/vpp/19.08/index.html) and [here](https://fd.io/docs/vpp/master/index.html).

Make sure to run the ```prepare_vpp.sh``` script, at the end this will reboot the VM. The script is meant to be used with an RHEL 7.7 VM. It can definitely work with CentOS 7. More adaptations are requited for Debian and derivated.
```
bash prepare_vpp.sh
```
Once the VM has been rebooted, VPP is also already ready.
- VPP configuration is good for the available virtual hardware
- RX and TX VirtIO File Descriptors have been increased to 1024
- The two VIRTIO NIC are up with an IP address (10.10.1.2, and 10.10.2.2)
- Static Routing is configured
  - 16.0.0.0/8 via 10.10.1.2
  - 48.0.0.0/8 via 10.10.2.2

## Sample Commands
To connect to VPP, one can simply run ```vppctl```
```
[root@vpp ~]# vppctl
    _______    _        _   _____  ___
 __/ __/ _ \  (_)__    | | / / _ \/ _ \
 _/ _// // / / / _ \   | |/ / ___/ ___/
 /_/ /____(_)_/\___/   |___/_/  /_/

```
To show the interfaces and their respective counters one can simply run ```show interface```
```
vpp# show interface
              Name               Idx    State  MTU (L3/IP4/IP6/MPLS)     Counter          Count
GigabitEthernet0/4/0              1      up          9000/0/0/0     rx packets              90779788
                                                                    rx bytes              5083853184
                                                                    tx packets              90766984
                                                                    tx bytes              5083132646
                                                                    drops                        946
                                                                    ip4                     90778951
                                                                    tx-error                 1685592
GigabitEthernet0/5/0              2      up          9000/0/0/0     rx packets              90767988
                                                                    rx bytes              5083192360
                                                                    tx packets              90778991
                                                                    tx bytes              5083805062
                                                                    drops                        869
                                                                    ip4                     90767127
                                                                    tx-error                 1685570
local0                            0     down          0/0/0/0
```
To show the global routing table one can simply run ```show ip fib```
```
vpp# show ip fib
<SNIP>
16.0.0.0/8
  unicast-ip4-chain
  [@0]: dpo-load-balance: [proto:ip4 index:18 buckets:1 uRPF:20 to:[0:0]]
    [0] [@12]: dpo-load-balance: [proto:ip4 index:17 buckets:1 uRPF:18 to:[0:0]]
          [0] [@3]: arp-ipv4: via 10.10.1.2 GigabitEthernet0/4/0
48.0.0.0/8
  unicast-ip4-chain
  [@0]: dpo-load-balance: [proto:ip4 index:20 buckets:1 uRPF:22 to:[0:0]]
    [0] [@12]: dpo-load-balance: [proto:ip4 index:19 buckets:1 uRPF:21 to:[0:0]]
          [0] [@3]: arp-ipv4: via 10.10.2.2 GigabitEthernet0/5/0
<SNIP>
```
To show the Interfaces IP Addresses
```
vpp# show interface address
GigabitEthernet0/4/0 (up):
  L3 10.10.1.1/24
GigabitEthernet0/5/0 (up):
  L3 10.10.2.1/24
local0 (dn):
```
To show global statss and error counters (including drops) one can simply run ```show errors```
```
vpp# show errors
   Count                    Node                  Reason
        52               dpdk-input               no error
         3                arp-input               ARP replies sent
       782                llc-input               unknown llc ssap/dsap
   1685570         GigabitEthernet0/5/0-tx        Tx packet drops (dpdk tx failure)
         3                arp-input               ARP replies sent
       782                llc-input               unknown llc ssap/dsap
   1685592         GigabitEthernet0/4/0-tx        Tx packet drops (dpdk tx failure)
```
To clear those statistics one can simply run ```clear interfaces``` and ```clear errors```

## CLI Commands
[CLI](https://docs.fd.io/vpp/19.08/clicmd.html)

## Tutorial
[Progressive Tutorial](https://wiki.fd.io/view/VPP/Progressive_VPP_Tutorial)
[Routing & Switching](https://wiki.fd.io/view/VPP/Tutorial_Routing_and_Switching)
[VPP and Trex](https://fd.io/docs/vpp/master/usecases/simpleperf/trex.html)

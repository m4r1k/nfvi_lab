# Steps to run Cisco TRex
TRex is an extremely powerful open-source traffic generator released by Cisco.
For the purpose of this test, we're going to use it only for L2 traffic (it can do MUCH more).
All documentation can be found [here](https://trex-tgn.cisco.com/trex/doc/trex_manual.html) and [here](https://trex-tgn.cisco.com/trex/doc/trex_stateless.html).

Make sure to run the ```prepare_trex.sh``` script, at the end this will reboot the VM. The script is meant to be used with an RHEL 7.7 VM. It can definitely work with CentOS 7. More adaptations are requited for Debian and derivated.
```
bash prepare_trex.sh
```
## Stateless mode
Once the VM has been rebooted, open an SSH session and run TRex in Stateless mode
```
cd /opt/trex/v2.71/
/opt/trex/v2.71/t-rex-64 -i
```
Then, open another SSH session (also possible to open a remote session) to use the TRex Console. At this point, you could even use a TRex client, not strictly the built-in TRex Console. To run the built-in console ```/opt/trex/v2.71/trex-console```
```
cd /opt/trex/v2.71/
/opt/trex/v2.71/trex-console

Using 'python' as Python interpeter
Connecting to RPC server on localhost:4501                   [SUCCESS]
Connecting to publisher server on localhost:4500             [SUCCESS]
Acquiring ports [0, 1]:                                      [SUCCESS]

Server Info:
Server version:   v2.67 @ STL
Server mode:      Stateless
Server CPU:       2 x Intel(R) Xeon(R) CPU E5-2678 v3 @ 2.50GHz
Ports count:      2 x 10.0Gbps @ 82599 Ethernet Controller Virtual Function

-=TRex Console v3.0=-

Type 'help' or '?' for supported actions
```
At this point, ona can run any type of traffic. TRex is pretty cool in Stateless mode, it can even retransmit a PCAP obtained somewhere else.

To see the port status and details one can run ```portattr```
```
trex>portattr
Port Status

     port       |          0           |          1
----------------+----------------------+---------------------
driver          |     net_ixgbe_vf     |     net_ixgbe_vf
description     |  82599 Ethernet Con  |  82599 Ethernet Con
link status     |          UP          |          UP
link speed      |       10 Gb/s        |       10 Gb/s
port status     |     TRANSMITTING     |     TRANSMITTING
promiscuous     |         off          |         off
multicast       |         off          |         off
flow ctrl       |         N/A          |         N/A
vxlan fs        |          -           |          -
--              |                      |
layer mode      |       Ethernet       |       Ethernet
src IPv4        |          -           |          -
IPv6            |         off          |         off
src MAC         |  00:00:00:00:00:21   |  00:00:00:00:00:22
---             |                      |
Destination     |  aa:aa:aa:aa:aa:21   |  aa:aa:aa:aa:aa:22
ARP Resolution  |          -           |          -
----            |                      |
VLAN            |          -           |          -
-----           |                      |
PCI Address     |     0000:00:06.0     |     0000:00:07.0
NUMA Node       |          0           |          0
RX Filter Mode  |    hardware match    |    hardware match
RX Queueing     |         off          |         off
Grat ARP        |         off          |         off
------          |                      |
```
To run traffic, ona can simply us the ```start``` command providing rate and duration. Of course, a traffic reflector needs to be up and running (see the testpmd document)
```
trex>start -f stl/udp_1pkt_pcap.py -d 2000 --force -m 5mpps
Removing all streams from port(s) [0._, 1._]:                [SUCCESS]
Attaching 1 streams to port(s) [0._]:                        [SUCCESS]
Attaching 1 streams to port(s) [1._]:                        [SUCCESS]
Starting traffic on port(s) [0._, 1._]:                      [SUCCESS]
42.42 [ms]
```To see the interactive traffic statistics ```tui``` is the way to go:
```
trex>tui
Global Statistics

connection   : localhost, Port 4501                  total_tx_L2  : 5.44 Gb/sec
version      : STL @ v2.67                           total_tx_L1  : 7.05 Gb/sec
cpu_util.    : 38.11% @ 2 cores (2 per dual port)    total_rx     : 5.44 Gb/sec
rx_cpu_util. : 0.0% / 0 pkt/sec                      total_pps    : 10.01 Mpkt/sec
async_util.  : 0.08% / 1.49 KB/sec                   drop_rate    : 0 b/sec
total_cps.   : 0 cps/sec                             queue_full   : 0 pkts

Port Statistics

   port    |         0         |         1         |       total
-----------+-------------------+-------------------+------------------
owner      |              root |              root |
link       |                UP |                UP |
state      |      TRANSMITTING |      TRANSMITTING |
speed      |           10 Gb/s |           10 Gb/s |
CPU util.  |            38.11% |            38.11% |
--         |                   |                   |
Tx bps L2  |         2.72 Gbps |         2.72 Gbps |         5.44 Gbps
Tx bps L1  |         3.52 Gbps |         3.52 Gbps |         7.05 Gbps
Tx pps     |            5 Mpps |            5 Mpps |        10.01 Mpps
Line Util. |           35.23 % |           35.23 % |
---        |                   |                   |
Rx bps     |         2.72 Gbps |         2.72 Gbps |         5.44 Gbps
Rx pps     |            5 Mpps |            5 Mpps |        10.01 Mpps
----       |                   |                   |
opackets   |         652191259 |         652191394 |        1304382653
ipackets   |         652187121 |         651976699 |        1304163820
obytes     |       44349005932 |       44349015048 |       88698020980
ibytes     |       44348723972 |       44334414764 |       88683138736
tx-pkts    |      652.19 Mpkts |      652.19 Mpkts |         1.3 Gpkts
rx-pkts    |      652.19 Mpkts |      651.98 Mpkts |         1.3 Gpkts
tx-bytes   |          44.35 GB |          44.35 GB |           88.7 GB
rx-bytes   |          44.35 GB |          44.33 GB |          88.68 GB
-----      |                   |                   |
oerrors    |                 0 |                 0 |                 0
ierrors    |                 0 |                 0 |                 0

status:  |
```

## Stateful mode
Stateful is a much more simple way of managing TRex and many features are missing.
Because of the fact that is simpler, I guess, many people may just want to give it a try.
Once the VM has been rebooted, open an SSH session and run TRex with the traffic one wants to run something like this:
```
cd /opt/trex/v2.71/
/opt/trex/v2.71/t-rex-64 -f cap2/dns.yaml -d 2000 -c 1 -m 1000000 -l 10 --active-flows 100000
```
This will run a simple UDP port 53 traffic profile (DNS) for 2000 seconds at 1Mpps rate enabling also the latency stats
```
-Per port stats table
      ports |               0 |               1
 -----------------------------------------------------------------------------------------
   opackets |        99302862 |        99252729
     obytes |      8043520844 |      9627487767
   ipackets |        99252826 |        99302961
     ibytes |      9627494363 |      8043527602
    ierrors |               0 |               0
    oerrors |               0 |               0
      Tx Bw |     647.00 Mbps |     774.87 Mbps

-Global stats enabled
 Cpu Utilization : 81.6  %  3.5 Gb/core
 Platform_factor : 1.0
 Total-Tx        :       1.42 Gbps
 Total-Rx        :       1.42 Gbps
 Total-PPS       :       2.00 Mpps
 Total-CPS       :     998.45 Kcps

 Expected-PPS    :       2.00 Mpps
 Expected-CPS    :    1000.00 Kcps
 Expected-BPS    :       1.36 Gbps

 Active-flows    :    50192  Clients :      511   Socket-util : 4.1629 %
 Open-flows      : 99301928  Servers :      255   Socket :  1339689 Socket/Clients :  2621.7
 drop-rate       :       0.00  bps
 current time    : 101.0 sec
 test duration   : 1899.0 sec

-Latency stats enabled
 Cpu Utilization : 1.8 %
 if|   tx_ok , rx_ok  , rx check ,error,       latency (usec) ,    Jitter          max window
   |         ,        ,          ,     ,   average   ,   max  ,    (usec)
 ----------------------------------------------------------------------------------------------------------------
 0 |      998,     998,         0,   97,         28  ,      63,       6      |  38  52  35  33  30  28  37  36  35  29  31  34  38
 1 |      998,     998,         0,   97,         25  ,      53,       5      |  35  28  38  26  38  34  35  37  37  33  37  40  31
```

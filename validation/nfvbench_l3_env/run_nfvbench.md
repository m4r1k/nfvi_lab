# Steps to run OPNFV NFVBench
NFVbench is a tool that provides an automated way to measure network performance.
Underneath NFVBench uses TRex but the simplicity makes it even better.
All documentation can be found [here](https://docs.opnfv.org/en/stable-fraser/submodules/nfvbench/docs/testing/user/userguide/index.html).

Make sure to run the ```prepare_nfvbench.sh``` script, at the end this will reboot the VM. The script is meant to be used with an RHEL 7.7 VM. It can definitely work with CentOS 7. More adaptations are requited for Debian and derivated.
```
bash prepare_nfvbench.sh
```
## Running Traffic
Once the VM has been rebooted, open an SSH session and copy the two NFVBench file included in this repo
- The [nfvbench.cfg](nfvbench/nfvbench.cfg) is NFVBench configuration file to be placed in the root folder. It works correctly assuming the environment has been generated using provided code
- The [run.sh](nfvbench/run.sh) is a wrapper around NFVBench with some nice verification before starting, performance report management, and packet rate as input (default 10kpps).

To start the traffic just run ```run.sh```
Be aware that during the packet generation you will see something you might define as dropped packets.
This, in reality, is the frame delay (very typical also on IXIA) aka the frames in the queue awaiting forwarding.
To really identify if packet drop has occourd, you need to check at the end right before the traffic generation has ended
<pre>
[root@nfvbench ~]# bash ~/run.sh 5Mpps
nfvbench
2019-12-14 12:10:50,674 INFO Loading configuration file: /tmp/nfvbench/nfvbench.cfg
2019-12-14 12:10:50,685 INFO -c /tmp/nfvbench/nfvbench.cfg --rate 5Mpps --json /tmp/nfvbench/results/result_12_14_19-07_10_49.json
2019-12-14 12:10:50,688 INFO Connecting to TRex (127.0.0.1)...
2019-12-14 12:10:53,780 INFO Starting TRex ...
2019-12-14 12:10:53,788 INFO nohup /bin/bash -c ./t-rex-64 -i -c 4 --iom 0 --no-scapy-server --unbind-unused-ports --close-at-end  --vlan --hdrh --mbuf-factor 0.2 --cfg /etc/trex_cfg.yaml &> /tmp/trex.log & disown
2019-12-14 12:10:53,796 INFO TRex server is running...
nohup: ignoring input and appending output to 'nohup.out'
2019-12-14 12:10:57,805 INFO Retrying connection to TRex (*** [RPC] - Failed to get server response from tcp://127.0.0.1:4501)...
2019-12-14 12:10:59,401 INFO Connected to TRex
2019-12-14 12:10:59,402 INFO    Port 0: 82599ES 10-Gigabit SFI/SFP+ Network Connection speed=10Gbps mac=90:e2:ba:7a:b2:b5 pci=0000:00:06.0 driver=net_ixgbe
2019-12-14 12:10:59,404 INFO    Port 1: 82599ES 10-Gigabit SFI/SFP+ Network Connection speed=10Gbps mac=90:e2:ba:7a:b2:b4 pci=0000:00:07.0 driver=net_ixgbe
2019-12-14 12:10:59,407 INFO Port 0: VLANs [2000]
2019-12-14 12:10:59,408 INFO Port 1: VLANs [2001]
2019-12-14 12:10:59,410 INFO ChainRunner initialized
2019-12-14 12:10:59,413 INFO Starting 1xEXT benchmark...
2019-12-14 12:10:59,436 INFO Polling ARP until successful...
2019-12-14 12:10:59,556 INFO    ARP: port=0 chain=0 src IP=10.10.1.2 dst IP=10.10.1.1 -> MAC=aa:aa:aa:aa:aa:21
2019-12-14 12:10:59,557 INFO ARP resolved successfully for port 0
2019-12-14 12:10:59,677 INFO    ARP: port=1 chain=0 src IP=10.10.2.2 dst IP=10.10.2.1 -> MAC=aa:aa:aa:aa:aa:22
2019-12-14 12:10:59,678 INFO ARP resolved successfully for port 1
2019-12-14 12:10:59,686 INFO Port 0: dst MAC ['aa:aa:aa:aa:aa:21']
2019-12-14 12:10:59,687 INFO Port 1: dst MAC ['aa:aa:aa:aa:aa:22']
2019-12-14 12:10:59,688 INFO Starting traffic generator to ensure end-to-end connectivity
2019-12-14 12:10:59,713 INFO Created 1 traffic streams for port 0.
2019-12-14 12:10:59,722 INFO Created 1 traffic streams for port 1.
2019-12-14 12:10:59,757 INFO Captured unique src mac 0/2, capturing return packets (retry 1/100)...
2019-12-14 12:11:01,780 INFO Received packet from mac: aa:aa:aa:aa:aa:22 (chain=0, port=1)
2019-12-14 12:11:01,784 INFO Received packet from mac: aa:aa:aa:aa:aa:21 (chain=0, port=0)
2019-12-14 12:11:01,785 INFO End-to-end connectivity established
2019-12-14 12:11:01,835 INFO Cleared all existing streams
2019-12-14 12:11:01,880 INFO Created 2 traffic streams for port 0.
2019-12-14 12:11:01,892 INFO Created 2 traffic streams for port 1.
2019-12-14 12:11:01,893 INFO Starting to generate traffic...
2019-12-14 12:11:01,894 INFO Running traffic generator
2019-12-14 12:11:01,921 INFO Service mode is disabled
2019-12-14 12:11:02,947 INFO TX: 5021352; RX: 5021185; Est. Dropped: 167; Est. Drop rate: 0.0033%
2019-12-14 12:11:03,963 INFO TX: 10096271; RX: 10096178; Est. Dropped: 93; Est. Drop rate: 0.0009%
2019-12-14 12:11:04,980 INFO TX: 15171864; RX: 15171683; Est. Dropped: 181; Est. Drop rate: 0.0012%
2019-12-14 12:11:05,995 INFO TX: 20247761; RX: 20247595; Est. Dropped: 166; Est. Drop rate: 0.0008%
2019-12-14 12:11:07,012 INFO TX: 25323146; RX: 25322925; Est. Dropped: 221; Est. Drop rate: 0.0009%
2019-12-14 12:11:08,028 INFO TX: 30397984; RX: 30397775; Est. Dropped: 209; Est. Drop rate: 0.0007%
2019-12-14 12:11:09,046 INFO TX: 35475838; RX: 35475731; Est. Dropped: 107; Est. Drop rate: 0.0003%
2019-12-14 12:11:10,062 INFO TX: 40559594; RX: 40559360; Est. Dropped: 234; Est. Drop rate: 0.0006%
2019-12-14 12:11:11,080 INFO TX: 45639304; RX: 45639166; Est. Dropped: 138; Est. Drop rate: 0.0003%

< SNIP >

2019-12-14 12:12:01,971 <b>INFO TX: 299761400; RX: 299761400; Est. Dropped: 0;</b> Est. Drop rate: 0.0000%
2019-12-14 12:12:01,972 INFO ...traffic generating ended.
2019-12-14 12:12:01,993 INFO Service chain 'EXT' run completed.
2019-12-14 12:12:01,994 INFO Cleaning up...
2019-12-14 12:12:02,081 INFO Saving results in json file: /tmp/nfvbench/results/result_12_14_19-07_10_49.json...
2019-12-14 12:12:02,098 INFO
========== NFVBench Summary ==========

< SNIP >
            Run Summary:

              +-----------------+-------------+----------------------+----------------------+----------------------+
              |   L2 Frame Size |  Drop Rate  |   Avg Latency (usec) |   Min Latency (usec) |   Max Latency (usec) |
              +=================+=============+======================+======================+======================+
              |              64 |   0.0000%   |                   35 |                   10 |                  967 |
              +-----------------+-------------+----------------------+----------------------+----------------------+


            L2 frame size: 64

            Run Config:

              +-------------+---------------------------+------------------------+-----------------+---------------------------+------------------------+-----------------+
              |  Direction  |  Requested TX Rate (bps)  |  Actual TX Rate (bps)  |  RX Rate (bps)  |  Requested TX Rate (pps)  |  Actual TX Rate (pps)  |  RX Rate (pps)  |
              +=============+===========================+========================+=================+===========================+========================+=================+
              |   Forward   |        1.6800 Gbps        |      1.6787 Gbps       |   1.6787 Gbps   |       2,500,000 pps       |     2,498,037 pps      |  2,498,037 pps  |
              +-------------+---------------------------+------------------------+-----------------+---------------------------+------------------------+-----------------+
              |   Reverse   |        1.6800 Gbps        |      1.6786 Gbps       |   1.6786 Gbps   |       2,500,000 pps       |     2,497,985 pps      |  2,497,985 pps  |
              +-------------+---------------------------+------------------------+-----------------+---------------------------+------------------------+-----------------+
              |    Total    |        3.3600 Gbps        |      3.3573 Gbps       |   3.3573 Gbps   |       5,000,000 pps       |     4,996,022 pps      |  4,996,022 pps  |
              +-------------+---------------------------+------------------------+-----------------+---------------------------+------------------------+-----------------+

            Forward Chain Packet Counters and Latency:

              +---------+--------------+--------------+------------+------------+------------+
              |   Chain |  TRex.TX.p0  |  TRex.RX.p1  |  Avg lat.  |  Min lat.  |  Max lat.  |
              +=========+==============+==============+============+============+============+
              |       0 | 149,882,251  | 149,882,251  |  38 usec   |  10 usec   |  967 usec  |
              +---------+--------------+--------------+------------+------------+------------+

            Reverse Chain Packet Counters and Latency:

              +---------+--------------+--------------+------------+------------+------------+
              |   Chain |  TRex.TX.p1  |  TRex.RX.p0  |  Avg lat.  |  Min lat.  |  Max lat.  |
              +=========+==============+==============+============+============+============+
              |       0 | 149,879,149  | 149,879,149  |  35 usec   |  10 usec   |  962 usec  |
              +---------+--------------+--------------+------------+------------+------------+

</pre>
In case of trouble, the most common thing to do is analyzing the TRex logs

```
docker exec -it nfvbench cat /tmp/trex.log
```

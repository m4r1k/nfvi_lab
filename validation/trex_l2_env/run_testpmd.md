# Steps to run TestPMD
TestPMD is one of the most simple DPDK sample application.
For the purpose of this test, we're going to use it to reflect back the traffic sent by TRex.
All documentation can be found [here](https://doc.dpdk.org/guides/testpmd_app_ug/).

Make sure to run the ```prepare_testpmd.sh``` script, at the end this will reboot the VM. The script is meant to be used with an RHEL 7.7 VM. It can definitely work with CentOS 7. More adaptations are requited for Debian and derivated.
```
bash prepare_testpmd.sh
```
Once the VM has been rebooted, open an SSH session and run TestPMD
```
testpmd -l 1,2,3,4,5,6 --socket-mem 1024 -n 4 \
	--proc-type auto --file-prefix pg -w 00:04.0 -w 00:05.0 \
	-- --forward-mode=mac --eth-peer=0,00:00:00:00:00:21 --eth-peer=1,00:00:00:00:00:22 \
	--nb-cores=2 --nb-ports=2 --portmask=3 --auto-start \
	--rxq=1 --txq=1 --rxd=1024 --txd=1024 -i

set promisc all off
port config mtu 0 9000
port config mtu 1 9000
```
In my case all the traffic going out of the first Ethernet interface is forwarded to the MAC ```00:00:00:00:00:21``` while from the second to ```00:00:00:00:00:22```
Also, RX and TX VirtIO File Descriptors have been increased to 1024.
One of the most useful command concerns showing the current statistics ```show port stats all```
```
testpmd> show port stats all

  ######################## NIC statistics for port 0  ########################
  RX-packets: 49546229   RX-missed: 0          RX-bytes:  2972775240
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 49053503   TX-errors: 0          TX-bytes:  2943210180

  Throughput (since last show)
  Rx-pps:      5987630
  Tx-pps:      5946553
  ############################################################################

  ######################## NIC statistics for port 1  ########################
  RX-packets: 49546520   RX-missed: 0          RX-bytes:  2972789700
  RX-errors: 0
  RX-nombuf:  0
  TX-packets: 47159531   TX-errors: 0          TX-bytes:  2829571860

  Throughput (since last show)
  Rx-pps:      5987653
  Tx-pps:      5686328
  ############################################################################
```
Also important, when the ports are stopped, summary about the dropped packets are available.

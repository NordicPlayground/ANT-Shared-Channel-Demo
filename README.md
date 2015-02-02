# ANT-Shared-Channel-Demo
The ANT Shared Channel Demo application demonstrates the capabilities of the experimental ANT Auto Shared Channels example from Nordic Semiconductor's nRF51 SDK 7.2+.

### Requirements

The demo application is compatible with all iDevices with iOS 8.0+. Additionally, at least four boards are required to utilize all features of the reference design: two for hubs and two (or more) for nodes. See the SDK documentation at http://developer.nordicsemi.com/nRF51_SDK/doc/7.2.0/s310/html/a00042.html for more information about the firmware.

### How to start

1. Compile and program the **ant_shared_channel_master_to_master** application to the two hub devices. Make sure that the S310 SoftDevice is programmed and that the S310 build configuration is selected in the build environment. 
2. Compile and program the **ant_shared_channel_slave** application to the peripheral devices. Make sure that the S210 SoftDevice is programmed.
3. Turn on the two hub devices and bring them close to each other (about 10 cm distance). This must happen within 20 seconds. This process uses relative proximity. 
4. When LED 2 turns on on both devices, separate them so that you can add peripherals (about 1 m distance).
5. Turn on a peripheral and bring it close to one of the hubs (about 10 cm distance). When the peripheral is connected to the hub, the peripheral's LED 2 will turn on. LED 1 should be off.
6. Repeat step 5 for all peripherals (nodes).
7. Compile the ANT Shared Channel Demo iOS application and run it on your device.
8. Press the CONNECT button to display both advertising hubs and connect with one of them. Optionally, use a second iDevice to connect with the second hub.
9. The iDevice will start receiving reports from the hubs. The hubs and nodes are displayed on the screen.
10. Click on a node to toggle it. Click on a hub to turn all child nodes off or on.

### Options

 - **Show IDs** - If this option is enabled, the application labels nodes and hubs with their IDs.
 - **Immediate response** - If this option is disabled, nodes will change states when a corresponding report message is received, which might take a few seconds. If the option is enabled, nodes change states immediately. However, it might happen that the immediate change is overwritten by a queued report message from one of the hubs. In that case, the state is set correctly after propagation of the current message is complete.

### Custom messages

Users can send custom messages to the hub. The following tables show the syntax of the command packet.

 Byte | Description
 -----|---------------------
 0    | Op Code (always 0)
 1    | Command:
      | 00 - Disable reporting
      | 01 - Enable reporting
      | 02 - Not supported
      | 03 - Node ON
      | 04 - Node OFF
      | 05 - Assign to group
 2    | Shared address of the peripheral to which the command is addressed (1-253)*
 3    | Group (0-15)
 4-5  | Device number of the hub to which the command is sent (little endian)*
 6-7  | Not used, 0s
 
 Byte | Description
 -----|--------------------
 0    | Op Code (always 0)
 1    | Command:
      | 06 - Group ON
      | 07 - Group OFF
 2    | Group (0-15)
 3-4  | Device number of the hub to which the command is sent (little endian)* 
 5-7  | Not used, 0s
 \* - 0 = all nodes or all hubs
 
 For example:
 - 000000 - Disable reporting on all nodes. After ~15 seconds, all nodes and hubs should disappear.
 - 000100 - Enable reporting on all nodes.
 - 00030200CDAB00 - Enable node with ID = 2 that belongs to a hub with ID = ABCD.

### Reports

When reports are enabled on a hub (default), the hub will periodically send update notifications to the connected Bluetooth Smart controller. 
Each notification contains the status of one of the nodes in the network, its shared channel address, and the ID of its master hub.

Byte | Description
-----|---------------------
0    | Op Code (always 3)
1    | Shared address of the node from which the update is coming
2    | Node state (0 - OFF, 1 - ON)
3-4  | Device number of the node's master hub (little endian)* 

The controller sends update packets periodically, even when the node state has not changed. 
It takes several seconds until the updated state of a node is reported to the controller. Hubs do not send new report packets about nodes that have been disconnected, but it might happen that one or more packets have been queued on one of the hubs.

### Screenshots

![Disconnected](/img/empty.png) ![Scanning](/img/scanning.png)

![Hub and two nodes connected](/img/1 hub.png) ![Two hubs connected](/img/2 hubs.png)

![Settings](/img/settings.png) ![Adding nodes to a group](/img/groups.png)

### Forum

[Nordic Developer Zone](http://devzone.nordicsemi.com/ "Go to the Nordic Developer Zone")

### Resources

 - [SDK documentation](http://developer.nordicsemi.com/nRF51_SDK/doc/7.2.0/s310/html/a00042.html "Experimental: Auto Shared Channels ")
 - [ANT Auto Shared Channel - Master Example](http://www.thisisant.com/resources/an07-auto-shared-channel-master-example/ "ANT Auto Shared Channel - Master example")
# Original runtime captures

Store direct screenshots and short recordings made from the user-supplied Android
build here. These files are research references for clean-room layout and behavior
comparison; they are not sources for copying or redistributing proprietary assets.

Implemented clean-room comparison states currently cover startup, default HUD,
compact HUD, character/inventory, death/respawn and System/settings. Original
pixels remain reference-only and are never loaded by the runtime.

Capture commands:

```sh
tools/treasure_hunter_device.sh status
tools/treasure_hunter_device.sh install
tools/treasure_hunter_device.sh launch
tools/treasure_hunter_device.sh shot gameplay-home
tools/treasure_hunter_device.sh record 30
```

Enable USB debugging and accept the RSA authorization prompt before running them.
For Wi-Fi after the initial USB connection:

```sh
tools/treasure_hunter_device.sh tcpip 5555
tools/treasure_hunter_device.sh connect PHONE_IP:5555
```

On Android 11 or newer, Wireless debugging can be used without USB. Choose
"Pair device with pairing code" on the phone, then run:

```sh
tools/treasure_hunter_device.sh pair PHONE_IP:PAIRING_PORT PAIRING_CODE
tools/treasure_hunter_device.sh connect PHONE_IP:ADB_PORT
```

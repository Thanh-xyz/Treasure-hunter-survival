# Treasure Hunter 4.3.6 XAPK analysis

The user-supplied XAPK was inspected statically before this correction pass.

- Package: `com.megacombat.treasurehunter`
- Version: `4.3.6` (`versionCode` 1387)
- Engine: Unity `6000.6.2f1`, IL2CPP, Addressables `4.0.1`
- Networking assemblies: Mirror, Telepathy, KCP and Simple Web Transport
- Content inventory: 70+ pet icons, 39+ horse families with four rarities,
  village buildings, clan/PvP/raid systems, bosses and seasonal event sets

The original first-pass tools could not decode all generation-23 shared type trees.
The owner later supplied a successful UnityPy export at
`/home/thanh/Documents/1.Projects/assets-ths`: 23,505 valid PNGs, including 5,086
Texture2D objects and 18,419 cropped sprites, plus IL2CPP metadata reports. Only a
small reviewed subset is copied into `assets/treasure_hunter/`; the 1.7 GB export
remains outside the project.

The asset-grounded visual pass replaces the remaining Emberfield field vegetation
with source-style trees/bushes/stumps and uses supplied Mosqui, Snailu and
Astromophy sprites. Runtime captures remain the source of truth for screen scale,
placement and behavioral parity.

## Device capture workflow

ADB is available as a lightweight user-local installation. The helper at
`tools/treasure_hunter_device.sh` installs both APK splits, launches the game and
writes screenshots or short recordings to `docs/original-captures/`.

The portable installation uses Google platform-tools 37.0.1 and supports both
USB authorization and Android 11+ Wireless debugging pairing.

The installer verifies that a device is authorized, warns when the ABI is not
ARM64 and refuses extraction when `/tmp` has less than 400 MB free. Its temporary
APK files are removed after each install attempt.

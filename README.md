# Mikrotik scripts repository

This repository contains a few scripts for automatically setting up basic routing/switching
configuration.
The end result is a configuration for home use. It contains PPP, VLAN, DHCP, DNS, System+Identity setup.

## Tested on Routerboard/hEX products

The version i'm personally running is RouterOS 6.46. These are scripts derived from my personal configuration, generalized to use global variables and updated to be idempotent in most situations.

WARN; These scripts require tweaking for older RouterOS versions and different hardware! Consult the
[Mikrotik WIKI](https://www.mikrotik.com/documentation) and/or user forum for specific help.

## Requirements

These scripts assume the default configuration has been preinstalled.

NOTE; There are two versions of default configuration;
 * The bare configuration; installed after erasing the configuration memory (hold down reset for ~20 secs)
 * The default configuration (defconf); installed after resetting the configuration through the UI.

## Usage

1. Copy `shard-settings.example.rsc` to `shard-settings.rsc` and fill in the empty values;
2. Check `init.rsc` to make sure the desired shards will run (you can comment/uncomment shard loads by prepending `#`);
3. FTP login into your device;
    * Use user: admin, password empty on clean installations;
    * Otherwise, use an enabled user which can access the filesystem.
4. Push all .rsc into the folder /flash/, it should always be there?;
5. Log into the UI (either through Winbox or WebFig);
6. Click on System > Reset Configuration;
7. Make sure to select `flash/init.rsc` to `Run After Reset`;
    * You can optionally enable/disable the other options.
8. Verify you can log in with your user credentials after the second reboot.

## Verify

The script is designed to run after the default configuration has been applied.
The configuration will be further updated and the system will reboot (once after reset, once after applying `init.rsc`).
You should be able to log in with the details provided for the `USER_1_NAME` and `USER_1_PASS` global variables.
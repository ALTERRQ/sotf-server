<p align="center">
  <img src="https://raw.githubusercontent.com/RouHim/sons-of-the-forest-container-image/main/.github/readme/logo.png" width="250">
</p>

<p align="center">
    <a href="https://github.com/RouHim/sons-of-the-forest-container-image/actions/workflows/pipeline.yml"><img src="https://github.com/RouHim/sons-of-the-forest-container-image/actions/workflows/pipeline.yml/badge.svg?branch=main" alt="Pipeline"></a>
    <a href="https://github.com/RouHim/sons-of-the-forest-container-image/actions/workflows/scheduled-security-audit.yaml"><img src="https://github.com/RouHim/sons-of-the-forest-container-image/actions/workflows/scheduled-security-audit.yaml/badge.svg?branch=main" alt="Pipeline"></a>
    <a href="https://hub.docker.com/r/rouhim/sons-of-the-forest-server"><img src="https://img.shields.io/docker/pulls/rouhim/sons-of-the-forest-server.svg" alt="Docker Hub pulls"></a>
    <a href="https://hub.docker.com/r/rouhim/sons-of-the-forest-server"><img src="https://img.shields.io/docker/image-size/rouhim/sons-of-the-forest-server" alt="Docker Hub size"></a>
    <a href="https://github.com/aquasecurity/trivy"><img src="https://img.shields.io/badge/trivy-protected-blue" alt="trivy"></a>
    <a href="https://hub.docker.com/r/rouhim/sons-of-the-forest-server/tags"><img src="https://img.shields.io/badge/ARCH-amd64-blueviolet" alt="os-arch"></a>
    <a href="https://buymeacoffee.com/rouhim"><img alt="Donate me" src="https://img.shields.io/badge/-buy_me_a%C2%A0coffee-gray?logo=buy-me-a-coffee"></a>
</p>

<p align="center">
    This repository provides a <a href="https://github.com/RouHim/sons-of-the-forest-container-image/actions/workflows/scheduled-security-audit.yaml">safe</a> container image for the <a href="https://sons-of-the-forest.com">Sons of the Forest</a> game server. 
  It is designed to be used with Docker Compose, making it easy to set up and manage your game server environment.
</p>

## Requirements

* [Docker](https://docs.docker.com/engine/install/)
* [Docker Compose](https://docs.docker.com/compose/install/standalone/)
* At least 8GB RAM

## Installation

Once _Docker_ and _Docker Compose_ are installed, clone this repository to your local machine:

```bash
git clone https://github.com/ALTERRQ/sotf-server.git
cd sotf-server
```

Before starting the server, create the required folder structure, and adjust the permissions:

```bash
mkdir config/ data/ 
chmod 777 config/ data/
```

> The `chmod` command is recommended to avoid permission issues.
> The main reason is, that the user in the container, most likely differs from the user on the host.

## Usage

To start the Sons of the Forest server, navigate to the cloned repository's directory and use Docker Compose:

```bash
docker compose build
docker compose up -d
```

This will build the latest image and start the server in detached mode.

When starting the server for the first time:

* The config files and folders will be automatically created in the `config/` folder.
* The server will download the latest version of the game from Steam to the `data/` folder.

> You have to restart after the first start.

To restart the server after making changes to the configuration, use the following command:

```bash
docker compose restart
```

To check the server logs, use the following command:

```bash
docker compose logs -f
```

## Update

To update the server, just restart the container.
The server checks for updates and validates on every boot per default.

> To skip update and validation of the server files on every boot,
> set the `FAST_BOOT` env variable to `true`.

## Log filtering

Although this dedicated server generates numerous unnecessary errors and debug logs, this does not indicate malfunction.
This project filters out these logs by default.

> To turn off log filtering,
> set the `FILTER_SHADER_AND_MESH_AND_WINE_DEBUG` env variable to `false`.

## Configuration

> The server configuration does not differ from the official server configuration.
> Just follow an existing server configuration guide
> like [this](https://steamcommunity.com/sharedfiles/filedetails/?id=2992700419&snr=1_2108_9__2107).

The `config` folder contains the configuration files for the game server:

* The server owners list, in a file called `ownerswhitelist.txt`
* The game server configuration, in a file called `dedicatedserver.cfg`
* The game saves, in a folder called `Saves`
* The game settings, in a file called `SonsGameSettings.cfg`

All files and folders in the `config` will be created automatically when the server is started for the first time.

> `SkipNetworkAccessibilityTest` is always forced to `true`,
> because the test method is not working in a container environment.


The `data/` folder contains the game server data.
Feel free to modify files in this folder,
but be aware that the game server must be restarted for changes to take effect.
The folder can be deleted to reset the game server to its default state.

## Troubleshooting

### Try:

* Try to change server type (far left at the join tab)
* Direct connect to the server: `Example: 192.168.1.100:27016` (the option bottom right at the join tab)
* Test via Steam server discovery: (Steam/View/Game Servers), test the LAN discovery or try to add server to favourites by the same syntax as the above suggestion
* If you can connect inside your LAN, but your friends can't from WAN, you need to setup your routers port forwarding, and firewall rules properly
* Try to change the ports (they can be used already, or your ISP is blocking them over the WAN) (you will need to change them at 3 places inside this project + your firewall)
* Use Google, forums, or some AI

If you think everything is set up properly, and you still can't connect to your server, then you could have this problem:

> Bad client side config files.
* They can prevent you from discovering, and connecting to any LAN server.
* Deleting them is the solution, but be carefull, because they hold all your settings and game saves
* You also should temporarely disable Steam Cloud for SOTF, otherwise Steam will just redownload the faulty files
* They are located at `C:\Users\$USERNAME\AppData\LocalLow\Endnight\SonsOfTheForest` on Windows

I recommend you to:

1. Disable Steam Cloud for SOTF
2. Turn off Steam compleately
3. Backup your Saves inside the `SonsOfTheForest` folder into a different location
4. Screenshot your important settings in the game (if you need them)
5. Delete the folder
6. Launch SOTF, check if you can see the server in the LAN section or can connect to it directly, then stop
7. Copy back your Saves folder
8. Dial back your important settings
9. Turn back Steam Cloud
10. Play

If you still can't connect, then you can try the: `CUSTOM_ACCESSIBILITY_TEST`
It checks if the server is accessible, to rule out bad networking configuration

Hier is how to do it:

1. Launch the server with `DO_CUSTOM_ACCESSIBILITY_TEST` set to `true` 
2. When the test appears launch: `./assessibility-test.sh $SERVER_IP` from a client computer and make sure it's not blocked by a firewall (Default inbound port: 18766 for client)

It will try to do a handshake with your server 3 times.
If it succeeds, then we ruled out bad network configuration.

 ### `If you still have problems try to get help on the UPSTREAM repo or other forums`

# Resources

- Inspired by: https://github.com/jammsen/docker-sons-of-the-forest-dedicated-server
- Built from: https://github.com/RouHim/sons-of-the-forest-container-image
- Built to: https://hub.docker.com/r/rouhim/sons-of-the-forest-server
- Based on: https://github.com/RouHim/steamcmd-wine-container-image
- SteamCMD Documentation: https://developer.valvesoftware.com/wiki/SteamCMD
- Dedicated server guide: https://steamcommunity.com/sharedfiles/filedetails/?id=2992700419&snr=1_2108_9__2107

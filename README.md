# OKR Best Desktop

[OKR Best](https://okrbest.com) is an open source platform for secure collaboration across the entire software development lifecycle. This repo is for the native desktop application that's built on [Electron](http://electron.atom.io/); it runs on Windows, Mac, and Linux.

Based on [Mattermost Desktop](https://github.com/mattermost/desktop), originally created as "electron-mattermost" by Yuya Ochiai.

[![nightly-builds](https://github.com/okrbest/okrbest-desktop/actions/workflows/nightly-builds.yaml/badge.svg)](https://github.com/okrbest/okrbest-desktop/actions/workflows/nightly-builds.yaml)

## Features

### Desktop integration
* Server dropdown for access to multiple servers
* Dedicated tabs for Channels, Boards and Playbooks
* Desktop Notifications
* Badges for unread channels and mentions
* Deep Linking to open OKR Best links directly in the app
* Runs in background to reduce number of open windows

## Usage

### Installation
Detailed guides are available at [docs.okrbest.com](https://docs.okrbest.com/install/desktop-app-install.html).

1. Download a file from the [downloads page](https://okrbest.com/download/) or from the [releases page](https://github.com/okrbest/okrbest-desktop/releases).
2. Run the installer or unzip the archive.
3. Launch OKR Best from your Applications folder, menu, or the unarchived folder.
3. On the first launch, please enter a name and URL for your OKR Best server. For example, `https://team.okrbest.com`.

### Configuration
You can show the dialog from menu bar.

Configuration will be saved into Electron's userData directory:

* `%APPDATA%\OKR Best` on Windows
* `~/Library/Application Support/OKR Best` on OS X
* `~/.config/OKR Best` on Linux

A custom data directory location can be specified with:

* `OKR Best.exe --args --data-dir C:\my-okrbest-data` on Windows
* `open /Applications/OKR\ Best.app/ --args --data-dir ~/my-okrbest-data/` on macOS 
* `./okrbest-desktop --args --data-dir ~/my-okrbest-data/` on Linux

## Custom App Deployments
Our [docs provide a guide](https://docs.okrbest.com/deployment/desktop-app-deployment.html) on how to customize and distribute your own OKR Best Desktop App, including how to distribute the official Windows Desktop App silently to end users, pre-configured with the server URL and other app settings.

## Development and Making Contributions
Our [developer guide](https://docs.okrbest.com/contribute/desktop/) has detailed information on how to set up your development environment, develop, and test changes to the Desktop App.

## License

This software is a derivative work based on Mattermost Desktop, originally developed by Mattermost, Inc. and contributors under the Apache License 2.0.

See [LICENSE.txt](LICENSE.txt) for license information.

ci.yaml 임시 테스트
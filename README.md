# linux-software-auto-install

Shell script to install some common software on a fresh linux installation

## Supported Operating Systems

- Fedora-like
  - Fedora, Nobara, CentOS
- Debian-like
  - Debian, Ubuntu, Lubuntu, Xubuntu, Kubuntu, Elementary, PopOS, Mint, Kali
- Arch-like
  - Arch, Manjaro, EndeavourOS, CachyOS, SteamOS

## Script Dependencies

Any dependencies and/or required repositories will be installed along with the software

- The following packages (and any dependencies) are required by the script and will be auto-installed if unavailable
  - flatpak, wget, curl, gpg, git
- The following install options will have these PPA repositories added (if no allowflat parameter):
  - fastfetch - <a href="https://launchpad.net/~zhangsongcui3371/+archive/ubuntu/fastfetch">launchpad Link</a>
  - retroarch - <a href="https://launchpad.net/~libretro/+archive/ubuntu/stable">launchpad Link</a>
- The following install options will have the non-free or free RPM repositories added on fedora-like distros (if no allowflat parameter):
  - steam
  - discord
  - handbrake
  - free
  - vlc
  - kodi
- The following install options will have these AUR packages installed if running an arch-like distro (if allowaur and no allowflat)
  - brave-bin - <a href="https://aur.archlinux.org/packages/brave-bin">AUR Link</a>
  - librewolf-bin - <a href="https://aur.archlinux.org/packages/librewolf-bin">AUR Link</a>
  - vscodium-bin - <a href="https://aur.archlinux.org/packages/vscodium-bin">AUR Link</a>
  - proton-mail-bin - <a href="https://aur.archlinux.org/packages/proton-mail-bin">AUR Link</a>
  - proton-pass - <a href="https://aur.archlinux.org/packages/proton-pass">AUR Link</a>
  - github-desktop-bin - <a href="https://aur.archlinux.org/packages/github-desktop-bin">AUR Link</a>
  - heroic-games-launcher - <a href="https://aur.archlinux.org/packages/heroic-games-launcher-bin">AUR Link</a>

## Basic Script Arguments

Add these arguments to the script call for modifications to script functionality

- help - Show available install options
- quiet - Show less output in the console
- allowflat - Prioritizes flatpaks, if available, over package manager packages
- allowaur - Allows for AUR package installs if on an arch-like distro

## Install Arguments

Add these arguments to the script call to install the respective software

### Web Browsers

- brave - Installs the Brave web browser
- librewolf - Installs the Librewolf web browser
- falkon - Installs the Falkon web browser

### Mail Clients

- protonmail - Installs the ProtonMail linux client
- thunderbird - Installs the Thunderbird mail client
- evolution - Installs the Evolution mail client

### Messaging

- discord - Installs the Discord client
- signal - Installs the Signal client
- telegram - Installs the Telegram client

### Media

- freetube - Installs the Freetube desktop app
- kodi - Installs the Kodi media server app
- vlc - Installs the VLC media player
- plex - Installs the Plex media server app
- spotify - Installs the Spotify client

### Productivity

- libreoffice - Installs the entire Libreoffice software suite
- gimp - Installs the photo editing software
- handbrake - Installs the video encoder software

### System

- flatseal - Installs Flatseal for managing Flatpak permissions
- disks - Installs Gnome Disks utility for managing partitions
- diskanalyzer - Installs Gnome Disk Analyzer utility for viewing system storage
- gthumb - Installs the image viewer software Gthumb
- neofetch - Installs the Neofetch command line tool
- fastfetch - Installs the Fastfetch command line tool
- mission - Installs the Mission Center resource monitoring tool

### Utility

- mangohud - Installs the MangoHud overlay software
- bottles - Installs the Windows compatibility software Bottles
- filezilla - Installs the ftp client
- timeshift - Installs the Timeshift app
- protonpass - Installs the ProtonPass linux client
- protonvpn - Installs the ProtonVPN linux client

### Developer Tools

- emacs - Installs the GNU Emacs text editor
- vim - Installs the terminal text editor Vim
- vscode - Installs the Visual Studio Code text editor
- vscodium - Installs the telemetry-free version of Visual Studio Code
- dbeaver - Installs the Dbeaver SQL editor
- github - Installs the linux port of the Github Desktop app

### Gaming Software

- steam - Installs the Steam client
- lutris - Installs the Lutris client
- heroic - Installs the Heroic client
- retroarch - Installs the Retroarch emulator frontend
- protonge - Installs the latest Glorious Eggroll Proton release from its repository

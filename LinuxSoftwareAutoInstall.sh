#!/bin/bash

#TODO
    # Add new install options:
        # neofetch
        # gThumb
        # libreoffice
    # Test new install options: 
        # N/A
    # Add in a launch option to prioritize flatpaks, if available   
        # Will need to update all functions with available flatpaks to install that instead if that flag is enabled
    # Change the way the ValidPrograms variable reads in the list of valid programs
        # Read in from a file? 
    # Create a function to determine if a program is already installed, either from flatpak or a regular package manager
        # Return values?
        # Flatpaks can be checked with 'flatpak info "${appid}" >/dev/null 2>&1 && do_what_you_want_here'

#Bugs
    # There seems to be a conflict of some files between proton-pass-debug and vscodium-bin-debug on arch
        # If one is installed, can't install the other 
        # Issue persists, even after an uninstall of the problem program
            # Caching issue?

InstallOptions=("$@")
CurrentUser=`echo $SUDO_USER`
CurrentOS=`grep '^NAME' /etc/os-release` 
CurrentOSReadable=`echo "$CurrentOS" | cut -d'"' -f 2`
DownloadDir="/home/"$CurrentUser"/Downloads"
Quiet=false

if (( EUID != 0 )); then                                                #Determine if the script was run with the required root permissions
    echo "'$(basename $0)' requires root permissions run" 1>&2
    exit 1
fi

if [[ $(echo "${InstallOptions[@]}" | grep -F -w "quiet") ]]; then      #Determine if the quiet option was passed, if it was, set the flag and remove it from the list
    Quiet=true 
    TempArray=()
    for Option in "${InstallOptions[@]}"; do 
        [[ $Option != "quiet" ]] && TempArray+=("$Option")
    done
    InstallOptions=("${TempArray[@]}")
    unset TempArray
fi 

case "$CurrentOSReadable" in                                            #Determine the user's package manager by distro name
    *Fedora*|*CentOS*|*Nobara*) 
        CurrentPackageManager="dnf" ;;
    *Ubuntu*|*Lubuntu*|*Xubuntu*|*Kubuntu*|*Elementary*|*Pop*|*Mint*|*Debian*)
        CurrentPackageManager="apt" ;; 
    *Arch*|*Endeavour*|*Manjaro*) 
        CurrentPackageManager="pacman" ;;
    *) 
        echo "Error - Unsupported OS:" $CurrentOSReadable
        exit 1
esac

function FuncDownloadAndExtractRepo() {         
    local DownloadLocation="/home/$CurrentUser/Downloads/$1"
    local RepoLocation="https://api.github.com/repos/$2/releases/latest"
    local Filetype=$3
    local URLStrings=`curl -s "${RepoLocation}" | grep "browser_download_url" | cut -d '"' -f 4`
    local URLArray=($URLStrings)
    local DesiredURL=''

    for t in "${URLArray[@]}"; do   
        if [ "${t: -${#Filetype}}" == $Filetype ]; then     #Find desired file(s) from releases
            DesiredURL=$t
        fi 
    done
    
    mkdir -p $DownloadLocation
    echo "Downloading file(s) from '$DesiredURL' ..."
    curl -sOL --output-dir $DownloadLocation ${DesiredURL}

    if [ $Filetype = ".tar.gz" ]; then                      #File is an archive, need to extract
        local TarFileName="$(find $DownloadLocation  -name "*$Filetype")"
        echo "Extracting file(s) from '$TarFileName' ... "
        tar xzf $TarFileName -C $DownloadLocation
        rm $TarFileName
    fi 
}

function FuncEnableArchMultiRepo() {
    mline=$(grep -n "\\[multilib\\]" /etc/pacman.conf | cut -d: -f1)
    rline=$(($mline + 1))
    sed -i ''$mline's|#\[multilib\]|\[multilib\]|g' /etc/pacman.conf
    sed -i ''$rline's|#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|g' /etc/pacman.conf
}

function FuncUpdateSystemAndInstallRequired() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf update -y
        dnf install flatpak curl wget gpg git -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get update -y && apt-get upgrade -y
        apt-get install flatpak curl wget gpg git -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -Syu --noconfirm
        pacman -S flatpak curl git --noconfirm --needed             #Pacman doesn't require wget or gpg
        if ! pacman -Q | grep -q 'yay'; then                        #Check for existing yay installation
            cd $DownloadDir    
            git clone https://aur.archlinux.org/yay-git.git         #Install yay for AUR packages
            cd yay-git
            chmod a+w $DownloadDir/yay-git/ 
            yes | runuser -u $CurrentUser -- makepkg -si
            cd ..
            rm -rf yay-git/
        fi
    fi 
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

function FuncInstallFlatseal() {
    flatpak install flathub com.github.tchx84.Flatseal -y
}

function FuncInstallBrave() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install dnf-plugins-core -y
        dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo -y
        rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 
        dnf install brave-browser -y    
    elif [ $CurrentPackageManager = "apt" ]; then 
        curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg 
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"| tee /etc/apt/sources.list.d/brave-browser-release.list
        apt-get update && apt-get install brave-browser -y 
    elif [ $CurrentPackageManager = "pacman" ]; then 
        yes | runuser -u $CurrentUser -- yay -S brave-bin
    fi 
}

function FuncInstallLibrewolf() {
    if [ $CurrentPackageManager = "dnf" ]; then
        curl -fsSL https://rpm.librewolf.net/librewolf-repo.repo | pkexec tee /etc/yum.repos.d/librewolf.repo 
        dnf install librewolf -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        distro=$(if echo " bullseye focal impish jammy uma una " \
            | grep -q " $(lsb_release -sc) "; then echo $(lsb_release -sc); else echo focal; fi)
        echo "deb [arch=amd64] http://deb.librewolf.net $distro main" \
            | tee /etc/apt/sources.list.d/librewolf.list
        wget https://deb.librewolf.net/keyring.gpg -O /etc/apt/trusted.gpg.d/librewolf.gpg
        apt-get update && apt-get install librewolf -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        yes | runuser -u $CurrentUser -- yay -S librewolf-bin
    fi 
}

function FuncInstallFalkon() {
    if [ $CurrentPackageManager = "dnf" ]; then
        dnf install falkon -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install falkon -y 
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S falkon --noconfirm --needed
    fi 
}

function FuncInstallThunderbird() { 
    if [ $CurrentPackageManager = "dnf" ]; then
        dnf install thunderbird -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install thunderbird -y 
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S thunderbird --noconfirm --needed
    fi 
}

function FuncInstallEvolution() {
    if [ $CurrentPackageManager = "dnf" ]; then
        dnf install evolution -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install evolution -y 
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S evolution --noconfirm --needed
    fi 
}

function FuncInstallTimeshift() {
    if [ $CurrentPackageManager = "dnf" ]; then
        dnf install timeshift -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install timeshift -y 
    elif [ $CurrentPackageManager = "pacman" ]; then 
        yes | runuser -u $CurrentUser -- yay -S timeshift
    fi 
}

function FuncInstallVscode() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        rpm --import https://packages.microsoft.com/keys/microsoft.asc 
        echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" \
            | tee /etc/yum.repos.d/vscode.repo > /dev/null
        dnf check-update && dnf install code -y
    elif [ $CurrentPackageManager = "apt" ]; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
            | gpg --dearmor > packages.microsoft.gpg 
        install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg 
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
            | tee /etc/apt/sources.list.d/vscode.list > /dev/null
        rm -f packages.microsoft.gpg
        apt-get update && apt-get install code -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S code --noconfirm --needed
    fi 
}

function FuncInstallVscodium() { 
    if [ $CurrentPackageManager = "dnf" ]; then 
        rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg 
        printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" \
            | tee -a /etc/yum.repos.d/vscodium.repo
        dnf install codium -y
    elif [ $CurrentPackageManager = "apt" ]; then
        wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
            | gpg --dearmor \
            | dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
        echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
            | tee /etc/apt/sources.list.d/vscodium.list
        apt-get update && apt-get install codium -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        yes | runuser -u $CurrentUser -- yay -S vscodium-bin
    fi 
}

function FuncInstallEmacs() { 
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install emacs -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install emacs -y
    elif [ $CurrentPackageManager = "pacman" ]; then    
        pacman -S emacs --noconfirm --needed
    fi 
}

function FuncInstallVim() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install vim -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install vim -y
    elif [ $CurrentPackageManager = "pacman" ]; then    
        pacman -S vim --noconfirm --needed
    fi 
}

function FuncInstallDbeaver() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        cd /home/$CurrentUser/Downloads
        wget -O dbeaver-desktop.rpm https://dbeaver.io/files/dbeaver-ce-latest-stable.x86_64.rpm
        rpm -i dbeaver-desktop.rpm 
        rm dbeaver-desktop.rpm 
    elif [ $CurrentPackageManager = "apt" ]; then 
        cd /home/$CurrentUser/Downloads
        wget -O dbeaver-desktop.deb https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
        dpkg -i dbeaver-desktop.deb 
        rm dbeaver-desktop.deb 
    elif [ $CurrentPackageManager = "pacman" ]; then    
        pacman -S dbeaver --noconfirm --needed
    fi 
}

function FuncInstallGithub() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        rpm --import https://rpm.packages.shiftkey.dev/gpg.key
        sh -c 'echo -e "[shiftkey-packages]\nname=GitHub Desktop\nbaseurl=https://rpm.packages.shiftkey.dev/rpm/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://rpm.packages.shiftkey.dev/gpg.key" > /etc/yum.repos.d/shiftkey-packages.repo'    
        dnf install github-desktop -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        wget -qO - https://mirror.mwt.me/shiftkey-desktop/gpgkey \
            | gpg --dearmor \
            | tee /usr/share/keyrings/mwt-desktop.gpg > /dev/null
        sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/mwt-desktop.gpg] https://mirror.mwt.me/shiftkey-desktop/deb/ any main" > /etc/apt/sources.list.d/mwt-desktop.list'    
        apt-get update && apt-get install github-desktop -y
    elif [ $CurrentPackageManager = "pacman" ]; then  
        yes | runuser -u $CurrentUser -- yay -S github-desktop-bin
    fi 
}

function FuncInstallBoxes() { 
    flatpak install flathub org.gnome.Boxes -y 
}

function FuncInstallDisks() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install gnome-disk-utility -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install gnome-disk-utility -y 
    elif [ $CurrentPackageManager = "pacman" ]; then    
        pacman -S gnome-disk-utility --noconfirm --needed
    fi 
}

function FuncInstallDiskanalyzer() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install baobab -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install baobab -y 
    elif [ $CurrentPackageManager = "pacman" ]; then    
        pacman -S baobab --noconfirm --needed
    fi 
}

function FuncInstallProtonvpn() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        cd /home/$CurrentUser/Downloads
        wget -O protonvpn-stable-release.rpm "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release \
            | cut -d\  -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.1-2.noarch.rpm"
        dnf install ./protonvpn-stable-release.rpm -y
        dnf check-update && dnf install proton-vpn-gnome-desktop -y 
        rm protonvpn-stable-release.rpm
    elif [ $CurrentPackageManager = "apt" ]; then 
        cd /home/$CurrentUser/Downloads
        wget -O protonvpn-stable-release.deb https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-3_all.deb 
        dpkg -i ./protonvpn-stable-release.deb
        apt-get update && apt-get install proton-vpn-gnome-desktop -y
        rm protonvpn-stable-release.deb
    elif [ $CurrentPackageManager = "pacman" ]; then 
        yes | runuser -u $CurrentUser -- yay -S python-proton-core python-proton-vpn-api-core python-proton-vpn-connection python-proton-keyring-linux python-proton-keyring-linux-secretservice python-proton-vpn-logger python-proton-vpn-network-manager python-proton-vpn-network-manager-openvpn python-proton-vpn-killswitch python-proton-vpn-killswitch-network-manager python-aiohttp python-bcrypt python-distro python-gnupg python-jinja python-requests python-pynacl python-pyopenssl python-sentry_sdk webkit2gtk dbus-python --noconfirm
        yes | runuser -u $CurrentUser -- yay -S proton-vpn-gtk-app
    fi 
}

function FuncInstallProtonmail() { 
    if [ $CurrentPackageManager = "dnf" ]; then 
        cd /home/$CurrentUser/Downloads
        wget -O ProtonMail-desktop.rpm https://proton.me/download/mail/linux/ProtonMail-desktop-beta.rpm
        rpm -i ProtonMail-desktop.rpm
        rm ProtonMail-desktop.rpm
    elif [ $CurrentPackageManager = "apt" ]; then 
        cd /home/$CurrentUser/Downloads
        wget -O ProtonMail-desktop.deb https://proton.me/download/mail/linux/ProtonMail-desktop-beta.deb
        dpkg -i ProtonMail-desktop.deb
        rm ProtonMail-desktop.deb
    elif [ $CurrentPackageManager = "pacman" ]; then 
        yes | runuser -u $CurrentUser -- yay -S protonmail-desktop
    fi 
}

function FuncInstallProtonpass() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        cd /home/$CurrentUser/Downloads
        wget -O ProtonPass-desktop.rpm https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm
        rpm -i ProtonPass-desktop.rpm
        rm ProtonPass-desktop.rpm
    elif [ $CurrentPackageManager = "apt" ]; then 
        cd /home/$CurrentUser/Downloads
        wget -O ProtonPass-desktop.deb https://proton.me/download/PassDesktop/linux/x64/ProtonPass.deb
        dpkg -i ProtonPass-desktop.deb
        rm ProtonPass-desktop.deb
    elif [ $CurrentPackageManager = "pacman" ]; then
        yes | runuser -u $CurrentUser -- yay -S proton-pass
    fi 
}

function FuncInstallSteam() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
        dnf install steam -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        cd /home/$CurrentUser/Downloads
        wget -O steam.deb https://cdn.akamai.steamstatic.com/client/installer/steam.deb
        apt install ./steam.deb -y
        rm steam.deb 
    elif [ $CurrentPackageManager = "pacman" ]; then 
        FuncEnableArchMultiRepo
        pacman -Sy steam --noconfirm --needed
    fi 
}

function FuncInstallHeroic() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        FuncDownloadAndExtractRepo "Heroic" "Heroic-Games-Launcher/HeroicGamesLauncher" ".rpm"
        local HeroicRpmFile=`basename "$(find $DownloadDir/Heroic -name "heroic-*.x86_64.rpm")"`
        cd $DownloadDir/Heroic
        dnf install ./$HeroicRpmFile -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        FuncDownloadAndExtractRepo "Heroic" "Heroic-Games-Launcher/HeroicGamesLauncher" ".deb"
        local HeroicDebFile=`basename "$(find $DownloadDir/Heroic -name "heroic_*_amd64.deb")"`
        cd $DownloadDir/Heroic
        dpkg -i $HeroicDebFile
    elif [ $CurrentPackageManager = "pacman" ]; then 
        yes | runuser -u $CurrentUser -- yay -S heroic-games-launcher
    fi 
}

function FuncInstallLutris() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install lutris -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install lutris -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S lutris --noconfirm --needed
    fi 
}

function FuncInstallRetroarch() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install retroarch -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        add-apt-repository ppa:libretro/stable -y 
        apt-get update && apt-get install retroarch -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S retroarch retroarch-assets-ozone retroarch-assets-xmb --noconfirm
    fi 
}

function FuncInstallDiscord() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
        dnf install discord -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
        dpkg -i ./discord.deb -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S discord --noconfirm --needed
    fi 
}

function FuncInstallTelegram() {
    if [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S telegram-desktop --noconfirm
    else    #Deb and RPM package rpos for telegram-desktop are abandonware apparently. Use the official website download
        wget -O- https://telegram.org/dl/desktop/linux | tar xJ -C /opt/
        ln -s /opt/Telegram/Telegram /usr/local/bin/telegram-desktop
    fi 
}

function FuncInstallSignal() {
    if [ $CurrentPackageManager = "apt" ]; then 
        wget -O- https://updates.signal.org/desktop/apt/keys.asc \
            | gpg --dearmor > signal-desktop-keyring.gpg
        cat signal-desktop-keyring.gpg \
            | tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' \
            | tee /etc/apt/sources.list.d/signal-xenial.list
        apt-get update && apt-get install signal-desktop
    else    #Signal only officially supported on apt package manager
        flatpak install flathub org.signal.Signal -y
    fi 
}

function FuncInstallSkype() {
    flatpak install flathub com.skype.Client -y 
}

function FuncInstallSpotify() {
    if [ $CurrentPackageManager = "apt" ]; then 
        curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg \
            | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
        echo "deb http://repository.spotify.com stable non-free" \
            | tee /etc/apt/sources.list.d/spotify.list
        apt-get update && apt-get install spotify-client -y
    else    #Spotify only officially supported on apt package manager
        flatpak install flathub com.spotify.Client -y
    fi 
}

function FuncInstallVlc() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y 
        dnf install vlc -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt install vlc -y 
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S vlc --noconfirm --needed
    fi 
}

function FuncInstallKodi() {
    flatpak install flathub tv.kodi.Kodi -y
}

function FuncInstallPlex() {
    flatpak install flathub tv.plex.PlexDesktop -y 
}

function FuncInstallFreetube() {
    flatpak install flathub io.freetubeapp.FreeTube -y
}

function FuncInstallBottles() {
    flatpak install flathub com.usebottles.bottles -y 
}

function FuncInstallProtonupqt() {
    flatpak install flathub net.davidotek.pupgui2 -y 
}

function FuncInstallProtonge() {            
    FuncDownloadAndExtractRepo "Proton" "GloriousEggroll/proton-ge-custom" ".tar.gz"
    local ProtonDownloadFolder="$(find "/home/$CurrentUser/Downloads/Proton/" -name "GE-Proton*")"
    local ProtonSteamFolder="/home/$CurrentUser/.steam/steam/compatibilitytools.d"
    mkdir -p $ProtonSteamFolder
    cp -r $ProtonDownloadFolder $ProtonSteamFolder
}

function FuncInstallMangohud() {       
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install mangohud -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt install mangohud -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        FuncEnableArchMultiRepo
        pacman -Sy mangohud --noconfirm --needed
    fi 
}

if [ "${#InstallOptions[@]}" -eq 0 ]; then 
    echo "No arguments supplied; Use 'help' for details"
elif [ "${InstallOptions[0]//-/}" = "help" ]; then 
    Output="
        $(basename $0)\n
        Permission requirements: root\n\n
        Supports:\n
        RPM:\t\t       Fedora, CentOS, Nobara\n
        DKPG:\t\t      Ubuntu, Lubuntu, Xubuntu, Kubuntu, Elementary, PopOS, Mint, Debian\n 
        Pacman:\t      Arch, EndeavourOS, Manjaro\n
        \n
        Options:\n
            quiet\t\t       Show less output in the console\n
            help\t\t        Show available install options\n\n
        Software:\n
            bottles\t       Installs the wine software Bottles\n
            boxes\t\t       Installs the Gnome-Boxes VM software\n
            brave\t\t       Installs the Brave web browser\n
            dbeaver\t       Installs the SQL editor\n
            discord\t       Installs the Discord client\n
            emacs\t\t       Installs the GNU Emacs text editor\n
            evolution\t     Installs the Evolution mail client\n
            falkon\t\t      Installs the Falkon web browser\n
            flatseal\t      Installs Flatseal for managing Flatpak permissions\n
            freetube\t      Installs the Freetube desktop app\n
            github\t\t      Installs the linux port of the Github Desktop app\n
            gnomedisks\t    Installs Gnome Disks utility for managing partitions\n
            diskanalyzer\t  Installs Gnome Disk Analyzer utility for viewing system storage\n
            heroic\t\t      Installs the Heroic client\n
            kodi\t\t        Installs the Kodi media server app\n
            librewolf\t     Installs the Librewolf web browser\n
            lutris\t\t      Installs the Lutris client\n
            mangohud\t      Installs the MangoHUD gaming overlay\n
            plex\t\t        Installs the Plex media server app\n
            protonge\t      Installs the latest Glorious Eggroll Proton release\n
            protonmail\t    Installs the ProtonMail linux client\n
            protonpass\t    Installs the ProtonPass linux client\n
            protonupqt\t    Installs the ProtonUp-Qt compatibility tool\n
            protonvpn\t     Installs the ProtonVPN linux client\n
            retroarch\t     Installs the Retroarch emulator frontend\n
            signal\t\t      Installs the Signal client\n
            skype\t\t       Installs the Skype messaging app\n
            spotify\t       Installs the Spotify client\n
            steam\t\t       Installs the Steam client\n
            telegram\t      Installs the Telegram messaging app\n
            thunderbird\t   Installs the Thunderbird mail client\n
            timeshift\t     Installs the Timeshift app\n
            vim\t\t         Installs the terminal text editor vim\n
            vlc\t\t         Installs the VLC media player\n
            vscode\t\t      Installs the Visual Studio Code text editor\n
            vscodium\t      Installs the telemetry-free version of Visual Studio Code\n
        "
    echo -e $Output
else 
    ParsedInstallOptions=() 
    for Options in "${InstallOptions[@]}"; do               #Sanitize all '-' values from all parameters
        ParsedInstallOptions+=("${Options//-/}")
    done

    ValidPrograms=("Steam","Lutris","Heroic","Discord","Signal","Spotify","Mangohud","Protonge","Vscode","Emacs","Protonvpn","Protonmail","Protonpass","Flatseal","Brave","Vscodium","Boxes","Github","Freetube","Kodi","Vlc","Bottles","Librewolf","Thunderbird","Timeshift","Plex","Protonupqt","Falkon","Evolution","Vim","Dbeaver","Telegram","Skype","Retroarch","Disks","Diskanalyzer")
    for Options in "${ParsedInstallOptions[@]}"; do         #Check that passed parameters are valid, so they can safetly be used for function calls
        if ! [[ $(echo "${ValidPrograms[@]}" | grep -F -w "${Options^}") ]]; then     
            echo "Parameter '$Options' is not a valid install option; See 'help' for details"
            exit 1
        fi 
    done

    echo "Updating system ... "
    if $Quiet; then 
        FuncUpdateSystemAndInstallRequired >/dev/null
    else 
        FuncUpdateSystemAndInstallRequired 
    fi 
    for Options in "${ParsedInstallOptions[@]}"; do         #If we made it here, all looks good. Run desired installations
        echo "Installing $Options ... "
        if $Quiet; then 
            FuncInstall${Options^} >/dev/null
        else 
            FuncInstall${Options^} 
        fi 
    done
fi

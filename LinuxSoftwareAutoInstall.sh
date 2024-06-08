#!/bin/bash

#TODO: 
    #Add options for Brave, VSCodium, VLC Media Player, Bottles, Freetube, Kodi, Gnome-Boxes, Proton Calandar, Proton Pass

InstallOptions=("$@")
CurrentUser=`echo $USER`
CurrentOS=`grep '^NAME' /etc/os-release` 
CurrentOSReadable=`echo "$CurrentOS" | cut -d'"' -f 2`
Quiet=false

if (( EUID != 0 )); then                                                #Determine if the script was run with the required root permissions
    echo "'$(basename $0)' requires root permissions run" 1>&2
    exit 1
fi

if [[ $(echo "${InstallOptions[@]}" | grep -F -w "quiet") ]]; then      #Determine if the verbose option was passed, if it was, set the flag and remove it from the list
    Quiet=true 
    TempArray=()
    for Option in "${InstallOptions[@]}"; do 
        [[ $Option != "quiet" ]] && TempArray+=("$Option")
    done
    InstallOptions=("${TempArray[@]}")
    unset TempArray
fi 

case "$CurrentOSReadable" in                                            #Determine the user's package manager by distro name
    *Fedora*|*SUSE*|*CentOS*|*Nobara*) 
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

function FuncUpdateSystemAndInstallRequired() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf update -y
        dnf install flatpak curl git -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get update -y && apt-get upgrade -y
        apt-get install flatpak curl git -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -Syu --noconfirm
        pacman -S flatpak curl git --noconfirm --needed
    fi 
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

function FuncInstallBrave() {
    echo "TODO"
}

function FuncInstallFlatseal() {
    flatpak install flathub com.github.tchx84.Flatseal -y
}

function FuncInstallVscode() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        rpm --import https://packages.microsoft.com/keys/microsoft.asc 
        echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null
        dnf check-update && dnf install code -y
    elif [ $CurrentPackageManager = "apt" ]; then
        apt-get install wget gpg
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg 
        install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg 
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null
        rm -f packages.microsoft.gpg
        apt-get update && apt-get install code -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        sudo pacman -S code --noconfirm
    fi 
}

function FuncInstallVscodium() { 
    echo "TODO"
}

function FuncInstallEmacs() { 
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install emacs -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install emacs -y
    elif [ $CurrentPackageManager = "pacman" ]; then    
        pacman -S emacs --noconfirm
    fi 
}

function FuncInstallBoxes() { 
    echo "TODO"
}

function FuncInstallBottles() {
    echo "TODO"
}

function FuncInstallProtonvpn() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        cd /home/$CurrentUser/Downloads
        wget -O protonvpn-stable-release.rpm "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release | cut -d\  -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.1-2.noarch.rpm"
        dnf install ./protonvpn-stable-release.rpm -y
        dnf check-update && dnf install proton-vpn-gnome-desktop -y 
        rm protonvpn-stable-release.rpm
    elif [ $CurrentPackageManager = "apt" ]; then 
        cd /home/$CurrentUser/Downloads
        wget wget -O protonvpn-stable-release.deb https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-3_all.deb 
        dpkg -i ./protonvpn-stable-release.deb
        apt-get update && apt-get install proton-vpn-gnome-desktop -y
        rm protonvpn-stable-release.deb
    elif [ $CurrentPackageManager = "pacman" ]; then 
        local DownloadDir="/home/"$CurrentUser"/Downloads/"
    
        #Install yay to find missing dependencies
        cd $DownloadDir
        git clone https://aur.archlinux.org/yay-git.git    
        cd yay-git
        chmod a+w $DownloadDir/yay-git/ 
        runuser -u $CurrentUser -- makepkg -si
        cd ..
        rm -rf yay-git/

        #Install dependencies
        runuser -u $CurrentUser -- yay -S python-proton-core python-proton-vpn-api-core python-proton-vpn-connection python-proton-keyring-linux python-proton-keyring-linux-secretservice python-proton-vpn-logger python-proton-vpn-network-manager python-proton-vpn-network-manager-openvpn python-proton-vpn-killswitch python-proton-vpn-killswitch-network-manager python-aiohttp python-bcrypt python-distro python-gnupg python-jinja python-requests python-pynacl python-pyopenssl python-sentry_sdk webkit2gtk dbus-python --noconfirm

        #Install VPN
        cd $DownloadDir
        git clone https://aur.archlinux.org/proton-vpn-gtk-app.git
        cd proton-vpn-gtk-app/
        chmod a+w $DownloadDir/proton-vpn-gtk-app/
        runuser -u $CurrentUser -- makepkg -si
        cd ..
        rm -rf proton-vpn-gtk-app/
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
        local DownloadDir="/home/"$CurrentUser"/Downloads/"
        cd $DownloadDir
        git clone https://aur.archlinux.org/protonmail-desktop.git 
        cd protonmail-desktop/
        chmod a+w $DownloadDir/protonmail-desktop/
        runuser -u $CurrentUser -- makepkg -si
        cd ..
        rm -rf protonmail-desktop/
    fi 
}

function FuncInstallProtoncalendar() {
    echo "TODO"
}

function FuncInstallProtonpass() {
    echo "TODO"
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
        flatpak install flathub com.valvesoftware.Steam -y
    fi 
}

function FuncInstallHeroic() {
    local HeroicDownloadDir="/home/$CurrentUser/Downloads/Heroic/"
    if [ $CurrentPackageManager = "dnf" ]; then 
        FuncDownloadAndExtractRepo "Heroic" "Heroic-Games-Launcher/HeroicGamesLauncher" ".rpm"
        local HeroicRpmFile=`basename "$(find $HeroicDownloadDir -name "heroic-*.x86_64.rpm")"`
        cd $HeroicDownloadDir
        dnf install ./$HeroicRpmFile -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        FuncDownloadAndExtractRepo "Heroic" "Heroic-Games-Launcher/HeroicGamesLauncher" ".deb"
        local HeroicDebFile=`basename "$(find $HeroicDownloadDir -name "heroic_*_amd64.deb")"`
        cd $HeroicDownloadDir
        dpkg -i $HeroicDebFile
    elif [ $CurrentPackageManager = "pacman" ]; then 
        local DownloadDir="/home/"$CurrentUser"/Downloads/"
        cd $DownloadDir
        git clone https://aur.archlinux.org/heroic-games-launcher.git
        cd heroic-games-launcher/
        chmod a+w $DownloadDir/heroic-games-launcher/
        runuser -u $CurrentUser -- makepkg -si --noconfirm
        cd ..
        rm -rf heroic-games-launcher/ 
    fi 
}

function FuncInstallLutris() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install lutris -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt-get install lutris -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S lutris --noconfirm
    fi 
}

function FuncInstallDiscord() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
        dnf install discord -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        wget "https://discord.com/api/download?platform=linux&format=deb" -O discord.deb
        apt-get install ./discord.deb -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S discord --noconfirm
    fi 
}

function FuncInstallSignal() {
    if [ $CurrentPackageManager = "apt" ]; then 
        wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
        cat signal-desktop-keyring.gpg | tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | tee /etc/apt/sources.list.d/signal-xenial.list
        apt-get update && apt-get install signal-desktop
    else    #Signal only officially supported on apt package manager, have to install the flatpak version otherwise
        flatpak install flathub org.signal.Signal -y
    fi 
}

function FuncInstallSpotify() {
    if [ $CurrentPackageManager = "apt" ]; then 
        curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
        echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
        apt-get update && apt-get install spotify-client -y
    else    #Spotify only officially supported on apt package manager, have to install the flatpak version otherwise
        flatpak install flathub com.spotify.Client -y
    fi 
}

function FuncInstallMangohud() {       
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install mangohud -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt install mangohud -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S discord --noconfirm
    fi 
}

function FuncInstallProtonge() {            #Download, Extract, and Install GE-Proton to the default (non-flatpak) compatibility folder in the steam directory
    FuncDownloadAndExtractRepo "Proton" "GloriousEggroll/proton-ge-custom" ".tar.gz"
    local ProtonDownloadFolder="$(find "/home/$CurrentUser/Downloads/Proton/" -name "GE-Proton*")"
    local ProtonSteamFolder="/home/$CurrentUser/.steam/steam/compatibilitytools.d"
    mkdir -p $ProtonSteamFolder
    cp -r $ProtonDownloadFolder $ProtonSteamFolder
}

function FuncInstallVlc() {
    echo "TODO"
}

function FuncInstallKodi() {
    echo "TODO"
}

function FuncInstallFreetube() {
    echo "TODO"
}

if [ "${#InstallOptions[@]}" -eq 0 ]; then 
    echo "No arguments supplied; Use 'help' for details"
elif [ "${InstallOptions[0]//-/}" = "help" ]; then 
    Output="
        Usage: $(basename $0) [OPTIONS]\n
        Permission requiremnts: root\n
        Supports:\n
        RPM:\t\t       Fedora, SUSE, CentOS, Nobara\n
        DKPG:\t\t      Ubuntu, Lubuntu, Xubuntu, Kubuntu, Elementary, PopOS, Mint, Debian\n 
        Pacman:\t      Arch, EndeavourOS, Manjaro\n
        \n
        Options:\n
            help\t\t        Show available install options\n
            quiet\t\t       Show less output in the console\n
            emacs\t\t       Installs the GNU Emacs text editor\n
            discord\t       Installs the Discord client\n
            flatseal\t      Installs Flatseal for managing Flatpak permissions\n
            heroic\t\t      Installs the Heroic client\n
            lutris\t\t      Installs the Lutris client\n
            mangohud\t      Installs the latest MangoHUD release via the repo install script\n
            protonge\t      Installs the latest Glorious Eggroll Proton release (Assuming existing steam install)\n
            protonmail\t    Installs the ProtonMail linux client\n
            protonvpn\t     Installs the ProtonVPN linux client\n
            signal\t\t      Installs the Signal client (Flatpak version if no apt)\n
            spotify\t       Installs the Spotify client (Flatpak version if no apt)\n
            steam\t\t       Installs the Steam client\n
            vscode\t\t      Installs the Visual Studio Code text editor\n        
        "
    echo -e $Output
else 
    ParsedInstallOptions=() 
    for Options in "${InstallOptions[@]}"; do               #Sanitize all '-' values from all parameters
        ParsedInstallOptions+=("${Options//-/}")
    done

    ValidPrograms=("Steam","Lutris","Heroic","Discord","Signal","Spotify","Mangohud","Protonge","Vscode","Emacs","Protonvpn","Protonmail","Flatseal")
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

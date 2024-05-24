#!/bin/sh

#Need to run with root permissions

#TODO: Write a function to install the heroic launcher
#TOOD: Write up a list of given changes and a confirmation prompt
#TODO: Write some validation code to ensure the user didn't add more than 7 parameters
#TODO: Write a for loop to loop through the InstallOptions and run the installation functions by inserting the name (Have to capitalize the first letter probably)

InstallOptions=($0,$1,$2,$3,$4,$5,$6)
CurrentUser=`echo $USER`
CurrentOS=`grep '^NAME' /etc/os-release` 
CurrentOSReadable=`echo "$CurrentOS" | cut -d'"' -f 2`

#TODO: Will need to add more options here. Which OS's use which package manager? Some documentation somewhere?
case $CurrentOSReadable in 
    "Fedora Linux") 
        CurrentPackageManager="dnf" ;;
    "Ubuntu")
        CurrentPackageManager="apt" ;; 
    "Arch Linux") 
        CurrentPackageManager="pacman" ;;
    *) 
        echo "Error - Unsupported OS:" $CurrentOSReadable
esac

#Download a given tar file from github and extract to a given directory
function FuncDownloadAndExtractTarball() {         
    local loc="/home/$CurrentUser/Downloads/$1"
    local repo="https://api.github.com/repos/$2/releases/latest"
    local URLStrings=`curl -s "${repo}" | grep "browser_download_url" | cut -d '"' -f 4`
    local URLArray=($URLStrings)
    local DesiredURL=''

    for t in "${URLArray[@]}"; do   
        if [ "${t: -7}" == ".tar.gz" ]; then #Find tarball from releases
            DesiredURL=$t
        fi 
    done
    
    mkdir -p $loc
    echo "Downloading files from '$DesiredURL' ..."
    curl -sOL --output-dir $loc ${DesiredURL}

    local TarFileName="$(find $loc  -name "*.tar.gz")"
    echo "Extracting files from '$TarFileName' ... "
    tar xzf $TarFileName -C $loc
    rm $TarFileName
}

#Update the system 
function FuncUpdateSystem() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf update -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt update -y && apt upgrade -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -Syu 
    fi 
}

#Install flatpak and add remote repos
function FuncInstallFlatpak() { 
    if [ $CurrentPackageManager = "apt" ]; then 
        dnf install flatpak -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt install flatpak -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S flatpak -y
    fi 
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

function FuncInstallSteam() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
        dnf install steam -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt install steam -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S steam -y 
    fi 
}

function FuncInstallLutris() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install lutris -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        add-apt-repository ppa:lutris-team/lutris
        apt install lutris -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S lutris
    fi 
}

function FuncInstallDiscord() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
        dnf install discord -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        wget "https://discord.com/api/download?platform=linux&format=deb" -O discord.deb -y
        apt install ./discord.deb -y
    elif [ $CurrentPackageManager="pacman" ]; then 
        pacman -S discord -y
    fi 
}

function FuncInstallSignal() {
    if [ $CurrentPackageManager = "apt" ]; then 
        wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
        cat signal-desktop-keyring.gpg | tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
        tee /etc/apt/sources.list.d/signal-xenial.list    
        sudo apt install signal-desktop -y
    else #Signal only officially supported on apt package manager, have to install the flatpak version for other pms
        InstallFlatpak
        flatpak install flathub org.signal.Signal -y
    fi 
}

function FuncInstallSpotify() {
    if [ $CurrentPackageManager = "apt" ]; then 
        curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
        tee /etc/apt/sources.list.d/spotify.list
        apt-get install spotify-client -y
    else  #Spotify only officially supported on apt package manager, have to install the flatpak version for other pms
        InstallFlatpak
        flatpak install flathub com.spotify.Client -y
    fi 
}

function FuncInstallMangoHUD() {            #Download, Extract, and Install MangoHud using the releases 'mangohud-setup.sh' set up script
    DownloadAndExtractTarball "MangoHud" "flightlessmango/MangoHud"
    MangoHudFolder="/home/$CurrentUser/Downloads/MangoHud/MangoHud/"
    cd $MangoHudFolder
    ./mangohud-setup.sh install
}

function FuncInstallGEProton() {            #Download, Extract, and Install GE-Proton to the default (non-flatpak) compatibility folder in the steam directory
    DownloadAndExtractTarball "Proton" "GloriousEggroll/proton-ge-custom"
    ProtonDownloadFolder="$(find "/home/$CurrentUser/Downloads/Proton/" -name "GE-Proton*")"
    ProtonSteamFolder="/home/$CurrentUser/.steam/steam/compatibilitytools.d"
    mkdir -p $ProtonSteamFolder
    cp -r $ProtonDownloadFolder $ProtonSteamFolder
}

#UpdateSystem
#InstallSteam
#InstallMangoHUD 
#InstallGEProton
#InstallLutris
#InstallDiscord
#InstallSignal
#InstallSpotify
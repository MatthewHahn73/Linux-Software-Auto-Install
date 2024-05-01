#!/bin/sh

#Need to run with root permissions

#TODO: Find a way to get around having to use fzf (Regex?)
#TODO: Check to see if its possible to install a newer version of feral gamemode

CurrentUser=`echo $USER`
CurrentOS=`grep '^NAME' /etc/os-release` 
CurrentOSReadable=`echo "$CurrentOS" | cut -d'"' -f 2`

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

function DownloadAndExtract() {         #Download a given tar file from github and extract to a given directory
    local loc="/home/$CurrentUser/Downloads/$1"
    local repo="https://api.github.com/repos/$2/releases/latest"
    local URL=`curl -s "${repo}" | grep "browser_download_url" | cut -d '"' -f 4 | fzf`
    
    mkdir -p $loc
    echo "Downloading files from '$URL' ..."
    curl -sOL --output-dir $loc ${URL}

    local TarFileName="$(find $loc  -name "*.tar.gz")"
    echo "Extracting files from '$TarFileName' ... "
    tar xzf $TarFileName -C $loc
    rm $TarFileName
}

function InstallMangoHUD() {            #Download, Extract, and Install MangoHud using the releases 'mangohud-setup.sh' set up script
    DownloadAndExtract "MangoHud" "flightlessmango/MangoHud"
    MangoHudFolder="/home/$CurrentUser/Downloads/MangoHud/MangoHud/"
    cd $MangoHudFolder
    ./mangohud-setup.sh install
}

function InstallGEProton() {            #Download, Extract, and Install GE-Proton to the default (non-flatpak) compatibility folder in the steam directory
    DownloadAndExtract "Proton" "GloriousEggroll/proton-ge-custom"
    ProtonDownloadFolder="$(find "/home/$CurrentUser/Downloads/Proton/" -name "GE-Proton*")"
    ProtonSteamFolder="/home/$CurrentUser/.steam/steam/compatibilitytools.d"
    mkdir -p $ProtonSteamFolder
    cp -r $ProtonDownloadFolder $ProtonSteamFolder
}

#Update the system and install steam through the determined package manager 
if [ $CurrentPackageManager="dnf" ]; then 
    dnf update -y
    dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
    dnf install steam -y
elif [ $CurrentPackageManager="apt" ]; then 
    apt update && apt upgrade
    apt install steam 
elif [ $CurrentPackageManager="pacman" ]; then 
    pacman -Syu 
    pacman -S steam
fi 

InstallMangoHUD 
#InstallGEProton


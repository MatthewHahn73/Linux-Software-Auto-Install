#!/bin/bash
#Need to run with root permissions
#BUGS:
    #Manoghud installation doesn't work properly even though it says so. Permission issue with the vm maybe?

InstallOptions=("$@")
CurrentUser=`echo $USER`
CurrentOS=`grep '^NAME' /etc/os-release` 
CurrentOSReadable=`echo "$CurrentOS" | cut -d'"' -f 2`

case $CurrentOSReadable in 
    "Fedora Linux") 
        CurrentPackageManager="dnf" ;;
    "Ubuntu"|"Linux Mint"|"Debian")
        CurrentPackageManager="apt" ;; 
    "Arch Linux") 
        CurrentPackageManager="pacman" ;;
    *) 
        echo "Error - Unsupported OS:" $CurrentOSReadable
esac

#Download a given tar file from github and extract to a given directory
function FuncDownloadAndExtractRepo() {         
    local DownloadLocation="/home/$CurrentUser/Downloads/$1"
    local RepoLocation="https://api.github.com/repos/$2/releases/latest"
    local Filetype=$3
    local URLStrings=`curl -s "${RepoLocation}" | grep "browser_download_url" | cut -d '"' -f 4`
    local URLArray=($URLStrings)
    local DesiredURL=''

    for t in "${URLArray[@]}"; do   
        if [ "${t: -${#Filetype}}" == $Filetype ]; then     #Find file(s) from releases
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

#Update the system 
function FuncUpdateSystem() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf update -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt update -y && apt upgrade -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -Syu --noconfirm
    fi 
}

#Install flatpak and add remote repos
function FuncInstallFlatpak() { 
    if [ $CurrentPackageManager = "apt" ]; then 
        dnf install flatpak -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt install flatpak -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S flatpak --noconfirm
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
        pacman -S steam --noconfirm
    fi 
}

function FuncInstallLutris() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install lutris -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        add-apt-repository ppa:lutris-team/lutris -y
        apt update && apt install lutris -y
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
        apt install ./discord.deb -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S discord --noconfirm
    fi 
}

function FuncInstallSignal() {
    if [ $CurrentPackageManager = "apt" ]; then 
        wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
        cat signal-desktop-keyring.gpg | tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | tee /etc/apt/sources.list.d/signal-xenial.list
        apt update && apt install signal-desktop
    else    #Signal only officially supported on apt package manager, have to install the flatpak version otherwise
        InstallFlatpak
        flatpak install flathub org.signal.Signal -y
    fi 
}

function FuncInstallSpotify() {
    if [ $CurrentPackageManager = "apt" ]; then 
        curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
        echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
        apt update && apt-get install spotify-client -y
    else    #Spotify only officially supported on apt package manager, have to install the flatpak version otherwise
        InstallFlatpak
        flatpak install flathub com.spotify.Client -y
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
        pacman -S heroic-games-launcher-bin --noconfirm
    fi 
}

function FuncInstallMangohud() {            #Download, Extract, and Install MangoHud using the releases 'mangohud-setup.sh' set up script
    FuncDownloadAndExtractRepo "MangoHud" "flightlessmango/MangoHud" ".tar.gz"
    local MangoHudFolder="/home/$CurrentUser/Downloads/MangoHud/MangoHud/"
    cd $MangoHudFolder
    ./mangohud-setup.sh install
}

function FuncInstallProtonge() {            #Download, Extract, and Install GE-Proton to the default (non-flatpak) compatibility folder in the steam directory
    FuncDownloadAndExtractRepo "Proton" "GloriousEggroll/proton-ge-custom" ".tar.gz"
    local ProtonDownloadFolder="$(find "/home/$CurrentUser/Downloads/Proton/" -name "GE-Proton*")"
    local ProtonSteamFolder="/home/$CurrentUser/.steam/steam/compatibilitytools.d"
    mkdir -p $ProtonSteamFolder
    cp -r $ProtonDownloadFolder $ProtonSteamFolder
}

if [ $# -eq 0 ]; then 
    echo "No arguments supplied; Use 'help' for details"
elif [ "${InstallOptions[0]//-/}" = "help" ]; then 
    Output="
        Usage: $(basename $0) [OPTIONS]\n
        Permission requiremnts: root\n
        Supports: Ubuntu, Fedora, Arch\n
        \n
        Options:\n
        help\t\t        Show available install options\n
        steam\t\t       Installs the Steam client\n
        lutris\t\t      Installs the Lutris client\n
        heroic\t\t      Installs the Heroic client\n
        discord\t       Installs the Discord client\n
        signal\t\t      Installs the Signal client (Flatpak version if no apt)\n
        spotify\t       Installs the Spotify client (Flatpak version if no apt)\n
        mangohud\t      Installs the latest MangoHUD release via the repo install script\n
        protonge\t      Installs the latest Glorious Eggroll Proton release and moves it to the steam compatibility folder (Assuming existing steam install)
        "
    echo -e $Output
else 
    ParsedInstallOptions=() 
    for Options in "${InstallOptions[@]}"; do               #Sanitize all '-' values from all parameters
        ParsedInstallOptions+=("${Options//-/}")
    done

    ValidPrograms=("Steam","Lutris","Heroic","Discord","Signal","Spotify","Mangohud","Protonge")
    for Options in "${ParsedInstallOptions[@]}"; do         #Check that passed parameters are valid, so they can safetly be used for function calls
        if ! [[ $(echo "${ValidPrograms[@]}" | grep -F -w "${Options^}") ]]; then     
            echo "Parameter '$Options' is not a valid install option; See 'help' for details"
            exit 1
        fi 
    done

    FuncUpdateSystem
    for Options in "${ParsedInstallOptions[@]}"; do         #If we made it here, all looks good. Run desired installations
        echo "Installing $Options ... "
        FuncInstall${Options^}
    done
fi

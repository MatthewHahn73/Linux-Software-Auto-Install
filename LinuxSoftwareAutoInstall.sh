#!/bin/bash
#BUGS:
    #Manoghud installation doesn't work properly even though it says so. Permission issue with the vm maybe?
    #Some console output makes it through even without verbose. Need to find and correct with a conditional

#TODO: 
    #Install an arch VM to test the arch installations
    #Test the newsly created install functions for Flatseal, VSCode, Emacs, Git, and the Proton Apps

InstallOptions=("$@")
CurrentUser=`echo $USER`
CurrentOS=`grep '^NAME' /etc/os-release` 
CurrentOSReadable=`echo "$CurrentOS" | cut -d'"' -f 2`
Verbose=false

if (( EUID != 0 )); then                                                #Determine if the script was run with the required root permissions
    echo "'$(basename $0)' requires root permissions run" 1>&2
    exit 1
fi

if [[ $(echo "${InstallOptions[@]}" | grep -F -w "verbose") ]]; then    #Determine if the verbose option was passed, if it was, set the flag and remove it from the list
    Verbose=true 
    TempArray=()
    for Option in "${InstallOptions[@]}"; do 
        [[ $Option != "verbose" ]] && TempArray+=("$Option")
    done
    InstallOptions=("${TempArray[@]}")
    unset TempArray
fi 

case $CurrentOSReadable in                                              #Determine the user's package manager by distro name
    "Fedora Linux") 
        CurrentPackageManager="dnf" ;;
    "Ubuntu"|"Linux Mint"|"Debian")
        CurrentPackageManager="apt" ;; 
    "Arch Linux") 
        CurrentPackageManager="pacman" ;;
    *) 
        echo "Error - Unsupported OS:" $CurrentOSReadable
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

function FuncUpdateSystem() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf update -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt update -y && apt upgrade -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -Syu --noconfirm
    fi 
}

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
        apt update && apt install code -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        sudo pacman -S code --noconfirm
    fi 
}

function FuncInstallEmacs() { 
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install emacs -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt install emacs -y
    elif [ $CurrentPackageManager = "pacman" ]; then    
        pacman -S emacs --noconfirm
    fi 
}

function FuncInstallGit() { 
    if [ $CurrentPackageManager = "dnf" ]; then 
        dnf install git -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        apt install git -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S git --noconfirm
    fi 
}

function FuncInstallProtonvpn() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        wget "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release | cut -d\  -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.1-2.noarch.rpm"
        dnf install ./protonvpn-stable-release-1.0.1-2.noarch.rpm 
        dnf check-update && dnf install --refresh proton-vpn-gnome-desktop 
    elif [ $CurrentPackageManager = "apt" ]; then 
        wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-3_all.deb 
        dpkg -i ./protonvpn-stable-release_1.0.3-3_all.deb 
        apt update && apt install proton-vpn-gnome-desktop
    elif [ $CurrentPackageManager = "pacman" ]; then 
        pacman -S git python python-pythondialog python-pyxdg python-keyring python-jinja python-distro python-systemd python-requests python-bcrypt python-gnupg python-pyopenssl
        cd "/home/"$USER"/Downloads/"
        git clone https://aur.archlinux.org/protonvpn.git
        git clone https://aur.archlinux.org/protonvpn-cli.git
        git clone https://aur.archlinux.org/protonvpn-gui.git
        git clone https://aur.archlinux.org/python-protonvpn-nm-lib.git
        git clone https://aur.archlinux.org/python-proton-client.git
        cd python-proton-client/
        makepkg
        pacman -U python-proton-client-* --noconfirm
        cd ..
        cd python-protonvpn-nm-lib/
        makepkg
        pacman -U python-protonvpn-nm-lib-* --noconfirm
        cd ..
        cd protonvpn-cli/
        makepkg
        pacman -U protonvpn-cli-* --noconfirm
        cd ..
        cd protonvpn-gui/
        makepkg
        pacman -U protonvpn-gui-* --noconfirm
        cd ..
        cd protonvpn/
        makepkg
        pacman -U protonvpn-* --noconfirm
        cd ..
        rm -rf python-proton-client/
        rm -rf python-protonvpn-nm-lib/ 
        rm -rf protonvpn-cli/
        rm -rf protonvpn-gui/
        rm -rf protonvpn/
    fi 
}

function FuncInstallProtonmail() { 
    if [ $CurrentPackageManager = "dnf" ]; then 
        wget -q -O ProtonMail-desktop.rpm https://proton.me/download/mail/linux/ProtonMail-desktop-beta.rpm
        rpm -i ProtonMail-desktop.rpm
    elif [ $CurrentPackageManager = "apt" ]; then 
        wget -q -O ProtonMail-desktop.rpm https://proton.me/download/mail/linux/ProtonMail-desktop-beta.deb
        dpkg -i ProtonMail-desktop.deb
    elif [ $CurrentPackageManager = "pacman" ]; then 
        cd "/home/"$USER"/Downloads/"
        git clone https://aur.archlinux.org/protonmail-desktop.git 
        cd protonmail-desktop/
        makepkg
        pacman -U protonmail-desktop-* --noconfirm
        cd ..
        rm -rf protonmail-desktop/
    fi 
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
        flatpak install flathub org.signal.Signal -y
    fi 
}

function FuncInstallSpotify() {
    if [ $CurrentPackageManager = "apt" ]; then 
        curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
        echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
        apt update && apt-get install spotify-client -y
    else    #Spotify only officially supported on apt package manager, have to install the flatpak version otherwise
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

if [ "${#InstallOptions[@]}" -eq 0 ]; then 
    echo "No arguments supplied; Use 'help' for details"
elif [ "${InstallOptions[0]//-/}" = "help" ]; then 
    Output="
        Usage: $(basename $0) [OPTIONS]\n
        Permission requiremnts: root\n
        Supports: Ubuntu, Mint, Fedora, Arch\n
        \n
        Options:\n
            help\t\t        Show available install options\n
            verbose\t       Output all details to the console\n
            emacs\t\t       Installs the GNU Emacs text editor\n
            discord\t       Installs the Discord client\n
            flatpak\t       Installs the Flatpak containerized package manager\n
            flatseal\t      Installs Flatseal for managing Flatpak permissions
            git\t\t         Installs git version control\n
            heroic\t\t      Installs the Heroic client\n
            lutris\t\t      Installs the Lutris client\n
            mangohud\t      Installs the latest MangoHUD release via the repo install script\n
            protonge\t      Installs the latest Glorious Eggroll Proton release (Assuming existing steam install)
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

    ValidPrograms=("Steam","Lutris","Heroic","Discord","Signal","Spotify","Mangohud","Protonge","Git","Vscode","Emacs","Protonvpn","Protonmail","Flatpak","Flatseal")
    for Options in "${ParsedInstallOptions[@]}"; do         #Check that passed parameters are valid, so they can safetly be used for function calls
        if ! [[ $(echo "${ValidPrograms[@]}" | grep -F -w "${Options^}") ]]; then     
            echo "Parameter '$Options' is not a valid install option; See 'help' for details"
            exit 1
        fi 
    done

    echo "Updating system ... "
    if $Verbose; then 
        FuncUpdateSystem
    else 
        FuncUpdateSystem >/dev/null
    fi 
    for Options in "${ParsedInstallOptions[@]}"; do         #If we made it here, all looks good. Run desired installations
        echo "Installing $Options ... "
        if $Verbose; then 
            FuncInstall${Options^}
        else 
            FuncInstall${Options^} >/dev/null
        fi 
    done
fi

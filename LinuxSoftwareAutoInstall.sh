#!/bin/bash

#Notes
    # The following software don't have flatpaks available: 
        # Timeshift
        # Gnome-Disk-Utility
        # Neofetch/Fastfetch
        # Proton GE (Obviously)
    # The following only have flatpaks available: 
        # Flatseal
        # Gnome-Boxes
        # Kodi 
        # Plex
        # Freetube 
        # Bottles
        # ProtonUp-Qt
    # The following only have official packages on the apt package manager and will install flatpaks otherwise: 
        # Signal 
        # Spotify
    # The following require AUR packages (and their dependencies) for installation on arch-like distros
        # brave-bin - https://aur.archlinux.org/packages/brave-bin
        # librewolf-bin - https://aur.archlinux.org/packages/librewolf-bin
        # vscodium-bin - https://aur.archlinux.org/packages/vscodium-bin
        # proton-mail-bin - https://aur.archlinux.org/packages/proton-mail-bin
        # proton-pass - https://aur.archlinux.org/packages/proton-pass
        # github-desktop-bin - https://aur.archlinux.org/packages/github-desktop-bin
        # heroic-games-launcher - https://aur.archlinux.org/packages/heroic-games-launcher-bin
    # The following PPA repos are added for their respective software installation
        # fastfetch - https://launchpad.net/~zhangsongcui3371/+archive/ubuntu/fastfetch
        # retroarch - https://launchpad.net/~libretro/+archive/ubuntu/stable
#TODO
    # Add new install options:
        # N/A
    # Test new install options: 
        # N/A
#Bugs
    # There seems to be a conflict of some files between proton-pass-debug and vscodium-bin-debug on arch
        # If one is installed, can't install the other 
        # Issue persists, even after an uninstall of the problem program
            # Caching issue?

InstallOptions=("$@")
CurrentUser=`(eval echo "$USER")`
CurrentOS=`grep '^NAME' /etc/os-release` 
CurrentOSReadable=`echo "$CurrentOS" | cut -d'"' -f 2`
DownloadDir="/home/"$CurrentUser"/Downloads"
Quiet=false
UseFlatpaks=false

case "$CurrentOSReadable" in                                                 #Determine the user's package manager by distro name
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

if [[ $(echo "${InstallOptions[@]}" | grep -F -w "quiet") ]]; then           #Determine if the quiet option was passed, if it was, set the flag and remove it from the list
    Quiet=true 
    TempArray=()
    for Option in "${InstallOptions[@]}"; do 
        [[ $Option != "quiet" ]] && TempArray+=("$Option")
    done
    InstallOptions=("${TempArray[@]}")
    unset TempArray
fi 

if [[ $(echo "${InstallOptions[@]}" | grep -F -w "useflat") ]]; then         #Determine if the useflat option was passed, if it was, set the flag and remove it from the list
    UseFlatpaks=true 
    TempArray=()
    for Option in "${InstallOptions[@]}"; do 
        [[ $Option != "useflat" ]] && TempArray+=("$Option")
    done
    InstallOptions=("${TempArray[@]}")
    unset TempArray
fi 

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
    
    sudo mkdir -p $DownloadLocation
    echo "Downloading file(s) from '$DesiredURL' ..."
    sudo curl -sOL --output-dir $DownloadLocation ${DesiredURL}

    if [ $Filetype = ".tar.gz" ]; then                      #File is an archive, need to extract
        local TarFileName="$(find $DownloadLocation  -name "*$Filetype")"
        echo "Extracting file(s) from '$TarFileName' ... "
        sudo tar xzf $TarFileName -C $DownloadLocation
        sudo rm $TarFileName
    fi 
}

function FuncEnableArchMultiRepo() {
    mline=$(grep -n "\\[multilib\\]" /etc/sudo pacman.conf | cut -d: -f1)
    rline=$(($mline + 1))
    sed -i ''$mline's|#\[multilib\]|\[multilib\]|g' /etc/sudo pacman.conf
    sed -i ''$rline's|#Include = /etc/sudo pacman.d/mirrorlist|Include = /etc/sudo pacman.d/mirrorlist|g' /etc/sudo pacman.conf
}

function FuncUpdateSystemAndInstallRequired() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        sudo dnf update -y
        sudo dnf install flatpak curl wget gpg git -y
    elif [ $CurrentPackageManager = "apt" ]; then 
        sudo apt-get update -y && sudo apt-get upgrade -y
        sudo apt-get install flatpak curl wget gpg git -y
    elif [ $CurrentPackageManager = "pacman" ]; then 
        sudo pacman -Syu --noconfirm
        sudo pacman -S flatpak curl git --noconfirm --needed             #Arch installs don't require wget or gpg for script functionality
        if ! sudo pacman -Q | grep -q 'yay'; then                        #Check for existing yay installation
            cd $DownloadDir    
            git clone https://aur.archlinux.org/yay-git.git              #Install yay for AUR packages
            cd yay-git
            chmod a+w $DownloadDir/yay-git/ 
            makepkg -si
            cd ..
            rm -rf yay-git/
        fi
    fi 
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

function FuncInstallBrave() {
    if $UseFlatpaks; then 
        flatpak install flathub com.brave.Browser -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install sudo dnf-plugins-core -y
            sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo -y
            rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 
            sudo dnf install brave-browser -y    
        elif [ $CurrentPackageManager = "apt" ]; then 
            curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg 
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"| tee /etc/apt/sources.list.d/brave-browser-release.list
            sudo apt-get update && sudo apt-get install brave-browser -y 
        elif [ $CurrentPackageManager = "pacman" ]; then 
            yay -S brave-bin --sudoloop --noconfirm
        fi  
    fi 
}

function FuncInstallLibrewolf() {
    if $UseFlatpaks; then 
        flatpak install flathub io.gitlab.librewolf-community -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then
            curl -fsSL https://rpm.librewolf.net/librewolf-repo.repo | pkexec tee /etc/yum.repos.d/librewolf.repo 
            sudo dnf install librewolf -y 
        elif [ $CurrentPackageManager = "apt" ]; then 
            distro=$(if echo " bullseye focal impish jammy uma una " \
                | grep -q " $(lsb_release -sc) "; then echo $(lsb_release -sc); else echo focal; fi)
            echo "deb [arch=amd64] http://deb.librewolf.net $distro main" \
                | tee /etc/apt/sources.list.d/librewolf.list
            wget https://deb.librewolf.net/keyring.gpg -O /etc/apt/trusted.gpg.d/librewolf.gpg
            sudo apt-get update && sudo apt-get install librewolf -y
        elif [ $CurrentPackageManager = "pacman" ]; then 
            yay -S librewolf-bin --sudoloop --noconfirm
        fi 
    fi 
}

function FuncInstallFalkon() {
    if $UseFlatpaks; then 
        flatpak install flathub org.kde.falkon -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then
            sudo dnf install falkon -y 
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install falkon -y 
        elif [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S falkon --noconfirm --needed
        fi 
    fi 
}

function FuncInstallThunderbird() { 
    if $UseFlatpaks; then 
        flatpak install flathub org.mozilla.Thunderbird -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then
            sudo dnf install thunderbird -y 
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install thunderbird -y 
        elif [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S thunderbird --noconfirm --needed
        fi 
    fi 
}

function FuncInstallEvolution() {
    if $UseFlatpaks; then 
        flatpak install flathub org.gnome.Evolution -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then
            sudo dnf install evolution -y 
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install evolution -y 
        elif [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S evolution --noconfirm --needed
        fi 
    fi 
}

function FuncInstallProtonmail() { 
    if $UseFlatpaks; then 
        flatpak install flathub me.proton.Mail -y 
    else 
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
            yay -S proton-mail-bin --sudoloop --noconfirm
        fi 
    fi 
}

function FuncInstallTimeshift() {
    if [ $CurrentPackageManager = "dnf" ]; then
        sudo dnf install timeshift -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        sudo apt-get install timeshift -y 
    elif [ $CurrentPackageManager = "pacman" ]; then 
        sudo pacman -S timeshift --noconfirm --needed
    fi 
}

function FuncInstallVscode() {
    if $UseFlatpaks; then 
        flatpak install flathub com.visualstudio.code -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            rpm --import https://packages.microsoft.com/keys/microsoft.asc 
            echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" \
                | tee /etc/yum.repos.d/vscode.repo > /dev/null
            sudo dnf check-update && sudo dnf install code -y
        elif [ $CurrentPackageManager = "apt" ]; then
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
                | gpg --dearmor > packages.microsoft.gpg 
            install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg 
            echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
                | tee /etc/apt/sources.list.d/vscode.list > /dev/null
            rm -f packages.microsoft.gpg
            sudo apt-get update && sudo apt-get install code -y
        elif [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S code --noconfirm --needed
        fi 
    fi 
}

function FuncInstallVscodium() { 
    if $UseFlatpaks; then 
        flatpak install flathub com.vscodium.codium -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg 
            printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" \
                | tee -a /etc/yum.repos.d/vscodium.repo
            sudo dnf install codium -y
        elif [ $CurrentPackageManager = "apt" ]; then
            wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
                | gpg --dearmor \
                | dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
            echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
                | tee /etc/apt/sources.list.d/vscodium.list
            sudo apt-get update && sudo apt-get install codium -y
        elif [ $CurrentPackageManager = "pacman" ]; then 
            yay -S vscodium-bin --sudoloop --noconfirm
        fi 
    fi 
}

function FuncInstallEmacs() { 
    if $UseFlatpaks; then 
        flatpak install flathub org.gnu.emacs -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install emacs -y
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install emacs -y
        elif [ $CurrentPackageManager = "pacman" ]; then    
            sudo pacman -S emacs --noconfirm --needed
        fi 
    fi 
}

function FuncInstallVim() {
    if $UseFlatpaks; then 
        flatpak install flathub org.vim.Vim -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install vim -y
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install vim -y
        elif [ $CurrentPackageManager = "pacman" ]; then    
            sudo pacman -S vim --noconfirm --needed
        fi 
    fi     
}

function FuncInstallDbeaver() {
    if $UseFlatpaks; then 
        flatpak install flathub io.dbeaver.DBeaverCommunity -y 
    else 
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
            sudo pacman -S dbeaver --noconfirm --needed
        fi 
    fi 
}

function FuncInstallGithub() {
    if $UseFlatpaks; then 
        flatpak install flathub io.github.shiftey.Desktop -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            rpm --import https://rpm.packages.shiftkey.dev/gpg.key
            sh -c 'echo -e "[shiftkey-packages]\nname=GitHub Desktop\nbaseurl=https://rpm.packages.shiftkey.dev/rpm/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://rpm.packages.shiftkey.dev/gpg.key" > /etc/yum.repos.d/shiftkey-packages.repo'    
            sudo dnf install github-desktop -y
        elif [ $CurrentPackageManager = "apt" ]; then 
            wget -qO - https://mirror.mwt.me/shiftkey-desktop/gpgkey \
                | gpg --dearmor \
                | tee /usr/share/keyrings/mwt-desktop.gpg > /dev/null
            sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/mwt-desktop.gpg] https://mirror.mwt.me/shiftkey-desktop/deb/ any main" > /etc/apt/sources.list.d/mwt-desktop.list'    
            sudo apt-get update && sudo apt-get install github-desktop -y
        elif [ $CurrentPackageManager = "pacman" ]; then  
            yay -S github-desktop-bin --sudoloop --noconfirm
        fi 
    fi     
}

function FuncInstallDisks() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        sudo dnf install gnome-disk-utility -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        sudo apt-get install gnome-disk-utility -y 
    elif [ $CurrentPackageManager = "pacman" ]; then    
        sudo pacman -S gnome-disk-utility --noconfirm --needed
    fi 
}

function FuncInstallDiskanalyzer() {
    if $UseFlatpaks; then 
        flatpak install flathub org.gnome.baobab -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install baobab -y 
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install baobab -y 
        elif [ $CurrentPackageManager = "pacman" ]; then    
            sudo pacman -S baobab --noconfirm --needed
        fi 
    fi 
}

function FuncInstallGthumb() {
    if $UseFlatpaks; then 
        flatpak install flathub org.gnome.gThumb -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install gthumb -y 
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install gthumb -y 
        elif [ $CurrentPackageManager = "pacman" ]; then    
            sudo pacman -S gthumb --noconfirm --needed
        fi 
    fi     
}

function FuncInstallNeofetch() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        sudo dnf install neofetch -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        sudo apt-get install neofetch -y 
    elif [ $CurrentPackageManager = "pacman" ]; then    
        sudo pacman -S neofetch --noconfirm --needed
    fi 
}

function FuncInstallFastfetch() {
    if [ $CurrentPackageManager = "dnf" ]; then 
        sudo dnf install fastfetch -y 
    elif [ $CurrentPackageManager = "apt" ]; then 
        sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y 
        sudo apt-get update && apt-get install fastfetch -y 
    elif [ $CurrentPackageManager = "pacman" ]; then    
        sudo pacman -S fastfetch --noconfirm --needed
    fi 
}

function FuncInstallProtonvpn() {
    if $UseFlatpaks; then 
        flatpak install flathub com.protonvpn.www -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            cd /home/$CurrentUser/Downloads
            wget -O protonvpn-stable-release.rpm "https://repo.protonvpn.com/fedora-$(cat /etc/fedora-release \
                | cut -d\  -f 3)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.1-2.noarch.rpm"
            sudo dnf install ./protonvpn-stable-release.rpm -y
            sudo dnf check-update && sudo dnf install proton-vpn-gnome-desktop -y 
            rm protonvpn-stable-release.rpm
        elif [ $CurrentPackageManager = "apt" ]; then 
            cd /home/$CurrentUser/Downloads
            wget -O protonvpn-stable-release.deb https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-3_all.deb 
            dpkg -i ./protonvpn-stable-release.deb
            sudo apt-get update && sudo apt-get install proton-vpn-gnome-desktop -y
            rm protonvpn-stable-release.deb
        elif [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S proton-vpn-gtk-app --noconfirm --needed
        fi 
    fi 
}

function FuncInstallProtonpass() {
    if $UseFlatpaks; then 
        flatpak install flathub me.proton.Pass -y 
    else 
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
            yay -S proton-pass-bin --sudoloop --noconfirm
        fi 
    fi 
}

function FuncInstallSteam() {
    if $UseFlatpaks; then 
        flatpak install flathub com.valvesoftware.Steam -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
            sudo dnf install steam -y
        elif [ $CurrentPackageManager = "apt" ]; then 
            cd /home/$CurrentUser/Downloads
            wget -O steam.deb https://cdn.akamai.steamstatic.com/client/installer/steam.deb
            apt install ./steam.deb -y
            rm steam.deb 
        elif [ $CurrentPackageManager = "pacman" ]; then 
            FuncEnableArchMultiRepo
            sudo pacman -Sy steam --noconfirm --needed
        fi 
    fi     
}

function FuncInstallHeroic() {
    if $UseFlatpaks; then 
        flatpak install flathub com.heroicgameslauncher.hgl -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            FuncDownloadAndExtractRepo "Heroic" "Heroic-Games-Launcher/HeroicGamesLauncher" ".rpm"
            local HeroicRpmFile=`basename "$(find $DownloadDir/Heroic -name "heroic-*.x86_64.rpm")"`
            cd $DownloadDir/Heroic
            sudo dnf install ./$HeroicRpmFile -y
        elif [ $CurrentPackageManager = "apt" ]; then 
            FuncDownloadAndExtractRepo "Heroic" "Heroic-Games-Launcher/HeroicGamesLauncher" ".deb"
            local HeroicDebFile=`basename "$(find $DownloadDir/Heroic -name "heroic_*_amd64.deb")"`
            cd $DownloadDir/Heroic
            dpkg -i $HeroicDebFile
        elif [ $CurrentPackageManager = "pacman" ]; then 
            yay -S heroic-games-launcher-bin --sudoloop --noconfirm
        fi 
    fi     
}

function FuncInstallLutris() {
    if $UseFlatpaks; then 
        flatpak install flathub net.lutris.Lutris -y 
    else    
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install lutris -y
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install lutris -y
        elif [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S lutris --noconfirm --needed
        fi 
    fi    
}

function FuncInstallRetroarch() {
    if $UseFlatpaks; then 
        flatpak install flathub org.libretro.RetroArch -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install retroarch -y
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo add-apt-repository ppa:libretro/stable -y 
            sudo apt-get update && sudo apt-get install retroarch -y
        elif [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S retroarch retroarch-assets-ozone retroarch-assets-xmb --noconfirm --needed
        fi 
    fi     
}

function FuncInstallDiscord() {
    if $UseFlatpaks; then 
        flatpak install flathub com.discordapp.Discord -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
            sudo dnf install discord -y
        elif [ $CurrentPackageManager = "apt" ]; then 
            wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
            dpkg -i ./discord.deb -y
        elif [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S discord --noconfirm --needed
        fi 
    fi     
}

function FuncInstallTelegram() {
    if $UseFlatpaks; then 
        flatpak install flathub org.telegram.desktop -y 
    else 
        if [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S telegram-desktop --noconfirm
        else    #Deb and RPM packages for telegram-desktop are abandonware apparently. Use the official website download
            wget -O- https://telegram.org/dl/desktop/linux | tar xJ -C /opt/
            ln -s /opt/Telegram/Telegram /usr/local/bin/telegram-desktop
        fi 
    fi     
}

function FuncInstallSignal() {
    if [ $CurrentPackageManager = "apt" ] && ! $UseFlatpaks; then 
        wget -O- https://updates.signal.org/desktop/apt/keys.asc \
            | gpg --dearmor > signal-desktop-keyring.gpg
        cat signal-desktop-keyring.gpg \
            | tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' \
            | tee /etc/apt/sources.list.d/signal-xenial.list
        sudo apt-get update && sudo apt-get install signal-desktop
    else    #Signal only officially supported on apt package manager
        flatpak install flathub org.signal.Signal -y
    fi 
}

function FuncInstallSpotify() {
    if [ $CurrentPackageManager = "apt" ] && ! $UseFlatpaks; then 
        curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg \
            | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
        echo "deb http://repository.spotify.com stable non-free" \
            | tee /etc/apt/sources.list.d/spotify.list
        sudo apt-get update && sudo apt-get install spotify-client -y
    else    #Spotify only officially supported on apt package manager
        flatpak install flathub com.spotify.Client -y
    fi 
}

function FuncInstallVlc() {
    if $UseFlatpaks; then 
        flatpak install flathub org.videolan.VLC -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y 
            sudo dnf install vlc -y 
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install vlc -y 
        elif [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S vlc --noconfirm --needed
        fi 
    fi 
}

function FuncInstallMangohud() {
    if $UseFlatpaks; then 
        flatpak install org.freedesktop.Platform.VulkanLayer.MangoHud -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install mangohud -y
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install mangohud -y
        elif [ $CurrentPackageManager = "pacman" ]; then 
            FuncEnableArchMultiRepo
            sudo pacman -Sy mangohud --noconfirm --needed
        fi 
    fi     
}

function FuncInstallLibreoffice() {
    if $UseFlatpaks; then 
        flatpak install flathub org.libreoffice.LibreOffice -y 
    else 
        if [ $CurrentPackageManager = "dnf" ]; then 
            sudo dnf install libreoffice-core libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-draw libreoffice-math libreoffice-base -y 
        elif [ $CurrentPackageManager = "apt" ]; then 
            sudo apt-get install libreoffice-core libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-draw libreoffice-math libreoffice-base -y 
        elif [ $CurrentPackageManager = "pacman" ]; then 
            sudo pacman -S libreoffice-still --noconfirm --needed
        fi 
    fi     
}

function FuncInstallProtonge() { 
    FuncDownloadAndExtractRepo "Proton" "GloriousEggroll/proton-ge-custom" ".tar.gz"
    local ProtonDownloadFolder="$(find "/home/$CurrentUser/Downloads/Proton/" -name "GE-Proton*")"
    local ProtonSteamFolder="/home/$CurrentUser/.steam/steam/compatibilitytools.d"
    sudo mkdir -p $ProtonSteamFolder
    sudo cp -r $ProtonDownloadFolder $ProtonSteamFolder
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

function FuncInstallFlatseal() {
    flatpak install flathub com.github.tchx84.Flatseal -y
}

function FuncInstallBoxes() { 
    flatpak install flathub org.gnome.Boxes -y 
}

function FuncInstallMission() { 
    flatpak install flathub io.missioncenter.MissionCenter -y 
}

if [ "${#InstallOptions[@]}" -eq 0 ]; then                  #No arguments found
    echo "No arguments supplied; Use 'help' for details"
elif [ "${InstallOptions[0]//-/}" = "help" ]; then          #Help was supplied
    HelpFile=`(pwd)`/Assets/HelpOutput.txt
    Output=$(cat "$HelpFile")
    echo "$(basename $0)"
    echo -e $Output
else                                                        #Run defaults
    ParsedInstallOptions=() 
    for Options in "${InstallOptions[@]}"; do               #Sanitize all '-' values from all parameters
        ParsedInstallOptions+=("${Options//-/}")
    done

    ValidProgramsFile=`(pwd)`/Assets/ValidInstalls.json
    ValidPrograms=($(awk -v RS= '{for (i=1; i<=NF; i++) {printf "%s ", $i}; print ""}' $ValidProgramsFile))
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
    for Options in "${ParsedInstallOptions[@]}"; do         #Run desired installations
        echo "Installing $Options ... "
        if $Quiet; then 
            FuncInstall${Options^} >/dev/null
        else 
            FuncInstall${Options^} 
        fi 
    done
fi
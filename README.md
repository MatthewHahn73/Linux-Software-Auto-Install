# linux-software-auto-install
<p>Shell script to install some common software on a fresh linux installation</p>

<h3>Script Information</h3>
    <ul>
        <li>The script will install software from traditional package managers, using RPM or PPA repos when available</li>
        <li>The following software are required by the script and will be auto-installed if unavailable</li>
        <ul>
            <li>flatpak, wget, curl, gpg, git</li>
        </ul>
    </ul>
<h1>Supported Operating Systems</h1>
    <ul>
        <li>RPM-based</li>
        <ul>
            <li>Fedora, CentOS, Nobara</li>
        </ul>
        <li>DKPG-based</li>
        <ul>
            <li>Ubuntu & Ubuntu variants (Lubuntu, Xubuntu, Kubuntu), Elementary, PopOS, Mint, Debian</li>
        </ul>
        <li>Pacman-based</li>
        <ul>
            <li>Arch, EndeavourOS, Manjaro</li>
        </ul>
    </ul>

<h1>Basic Script Arguments</h1>
    <ul>
        <li>help - Show available install options</li>
        <li>quiet - Show less output in the console</li>
    </ul>

<h1>Available Installs</h1>
    <ul>
        <li>Web Browsers</li>
        <ul>
            <li>brave - Installs the Brave web browser</li>
            <li>librewolf - Installs the Librewolf web browser</li> 
            <li>falkon - Installs the Falkon web browser</li> 
        </ul>
        <li>Mail Clients</li>
        <ul>
            <li>protonmail - Installs the ProtonMail linux client</li>
            <li>thunderbird - Installs the Thunderbird mail client</li>
            <li>evolution - Installs the Evolution mail client</li>
        </ul>
        <li>Messaging</li>
        <ul>
            <li>discord - Installs the Discord client</li>
            <li>signal - Installs the Signal client</li>
            <li>skype - Installs the Skype client</li>
            <li>telegram - Installs the Telegram messaging app</li>
        </ul>
        <li>Media</li>
        <ul>
            <li>freetube - Installs the Freetube desktop app</li>
            <li>kodi - Installs the Kodi media server app</li>
            <li>vlc - Installs the VLC media player</li>
            <li>plex - Installs the Plex media server app</li>   
            <li>spotify - Installs the Spotify client</li>
        </ul>
        <li>System</li>
        <ul>
            <li>bottles - Installs the Windows compatibility software Bottles</li>
            <li>flatseal - Installs Flatseal for managing Flatpak permissions</li>
            <li>disks - Installs Gnome Disks utility for managing partitions</li>
            <li>diskanalyzer - Installs Gnome Disk Analyzer utility for viewing system storage</li>
            <li>gthumb - Installs the image viewer software Gthumb</li>
            <li>neofetch - Installs the Neofetch command line tool</li>
        </ul>
        <li>Utility</li>
        <ul>
            <li>boxes - Installs the Gnome-Boxes VM software</li>
            <li>timeshift - Installs the Timeshift app</li>    
            <li>protonpass - Installs the ProtonPass linux client</li>
            <li>protonvpn - Installs the ProtonVPN linux client</li>
        </ul>
        <li>Developer Tools</li>
        <ul>
            <li>emacs - Installs the GNU Emacs text editor</li>
            <li>vscode - Installs the Visual Studio Code text editor</li>
            <li>vscodium - Installs the telemetry-free version of Visual Studio Code</li>
            <li>dbeaver - Installs the Dbeaver SQL editor</li>
            <li>vim - Installs the terminal text editor Vim</li>
            <li>github - Installs the linux port of the Github Desktop app</li>
        </ul>
        <li>Gaming Software</li>
        <ul>
            <li>lutris - Installs the Lutris client</li>
            <li>mangohud - Installs the MangoHud game overlay software</li>
            <li>steam - Installs the Steam client</li>
            <li>protonge - Installs the latest Glorious Eggroll Proton release from its repository</li>
            <li>protonupqt - Installs the ProtonUp-Qt compatibility tool</li> 
            <li>heroic - Installs the Heroic client</li>
            <li>retroarch - Installs the Retroarch emulator frontend</li>
        </ul>
    </ul> 
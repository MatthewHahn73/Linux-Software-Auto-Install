# linux-software-auto-install
<p>Shell script to install some common software on a fresh linux installation</p>

<h1>Command Line Arguments</h1>
    <ul>
        <li>Utility</li>
        <ul>
            <li>help - Show available install options</li>
            <li>verbose - Includes all script output</li>
        </ul> 
        <li>Available Programs</li>
        <ul>
            <li>steam - Installs the steam client</li> 
            <li>lutris - Installs the lutris client</li> 
            <li>heroic - Installs the heroic client</li> 
            <li>discord - Installs the discord client</li> 
            <li>signal - Installs the signal client</li> 
            <ul>
              <li>Defaults to the flatpak version if not on an ubuntu-like distro</li>
            </ul>
            <li>spotify - Installs the spotify client</li>
            <ul>
              <li>Defaults to the flatpak version if not on an ubuntu-like distro</li>
            </ul>
            <li>mangohud - Installs the latest MangoHUD release from the repository</li>
            <li>protonge - Installs the latest Glorious Eggroll Proton release and moves it to the steam compatibility folder</li>
            <ul>
              <li>Assumes existing steam install</li>
            </ul>
        </ul>
    </ul> 

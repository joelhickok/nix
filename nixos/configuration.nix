# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./secrets.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "em680"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";33

  # Enable networking
  networking.networkmanager.enable = true;

  services.rpcbind.enable = true;
  services.opensnitch.enable = true;

  boot.supportedFilesystems = ["nfs"];
  boot.initrd.supportedFilesystems = ["nfs"];
  boot.initrd.kernelModules = ["nfs/*  */"];

  hardware.sane = {
    enable = true;
    dsseries.enable = true;
    disabledDefaultBackends = [
      #  "v4l"
    ];
    extraBackends = [
      #  pkgs.hplipWithPlugin pkgs.sane-airscan
    ];
  };
  

  services.fail2ban.enable = false;

  services.desktopManager.gnome = {
    extraGSettingsOverridePackages = with pkgs; [ gnome-settings-daemon ];
    extraGSettingsOverrides = ''
      [org.gnome.settings-daemon.plugins.media-keys]
      custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']

      [org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0]
      binding='<Alt><Super><Space>'
      command='launcher-toggle'
      name='Open Ulauncher'
    '';
  };

  # enable remote desktop
  services.xrdp = {
    enable = true;
    defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
    #serviceConfig = {
    #  ExecStart = lib.mkForce "${pkgs.xrdp}/bin/xrdp --nodaemon --config /etc/xrdp/xrdp.ini";
    #};
  };

  # Use the GNOME Wayland session
  # services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";

  programs.hyprland = {
    enable = false;
    withUWSM = true; # Recommended for integration with systemd
    # withSystemd = true;
    xwayland.enable = false;
  };

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface" = {
        gtk-theme = "Adwaita";
        icon-theme = "Flat-Remix-Red-Dark";
        font-name = "Noto Sans Medium 11";
        document-font-name = "Noto Sans Medium 11";
        monospace-font-name = "Noto Sans Mono Medium 11";
      };
    }
  ];

  # XRDP needs the GNOME remote desktop backend to function
  services.gnome.gnome-remote-desktop.enable = true;

  # Open the default RDP port (3389)
  services.xrdp.openFirewall = true;

  # Disable autologin to avoid session conflicts
  services.displayManager.autoLogin.enable = false;
  services.getty.autologinUser = null;

  # Enable the GNOME RDP components
  # services.gnome.gnome-remote-desktop.enable = true;

  # Ensure the service starts automatically at boot so the settings panel appears
  #systemd.services.gnome-remote-desktop = {
  #  wantedBy = [ "graphical.target" ];
  #};

  # Open the default RDP port (3389)
  networking.firewall.allowedTCPPorts = [ 3389 6666 ];

  # Disable autologin to avoid session conflicts
  #services.displayManager.autoLogin.enable = false;
  #services.getty.autologinUser = null;

  # Disable systemd targets for sleep and hibernation
  systemd.targets.sleep.enable = true;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0x04F9", ATTRS{idProduct}=="0x00E0", MODE="0664", GROUP="scanner", ENV{libsane_matched}="yes"
  '';

  # Bus 003 Device 011: ID 04f9:60e0 Brother Industries, Ltd DS-620

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
    };
  };

  fileSystems."/mnt/NAS" = {
    device = "192.168.8.178:/export/Data";
    fsType = "nfs";
    #options = [ "x-systemd.automount" "noauto" "rw" "nofail" "_netdev" "nfsvers=4.0"]; # other options: "noatime" "noauto" "nfsvers=4.2"
    options = ["x-systemd.automount" "noauto" "_netdev"];
  };

  environment.variables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    EDITOR = "vim"; 
    SUDO_EDITOR="code --wait";
  };

  environment.sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Enable wayland for chromium-based apps (VSCode Discord Brave)
    };

  fonts.packages = with pkgs;
    [
#      font-awesome
      ubuntu-classic
      liberation_ttf
      lato
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
      # nerd-fonts.fira-code
      # nerd-fonts.fira
      # nerd-fonts.droid-sans-mono
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  fonts.enableDefaultPackages = true;
  fonts.fontDir.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
  ];

  fonts.fontconfig = {
    defaultFonts = {
      serif = ["Liberation Serif"];
      sansSerif = ["Ubuntu"];
      monospace = ["Ubuntu Mono"];
    };
  };

  virtualisation = {
    docker.enable = true;
    podman = {
      enable = true;
      # dockerCompat = true;
    };
    libvirtd = {
      enable = true;
      qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    };

  };


  programs.virt-manager.enable = true;

  documentation.nixos.enable = false;

  # Set your time zone.
  time.timeZone = "America/Denver";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  # services.displayManager.defaultSession = "hyprland-uwsm";

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  security.sudo.wheelNeedsPassword = false;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [6666];
    allowSFTP = false;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "yes";
      AllowUsers = [username];
      X11Forwarding = false;
    };
  };

  # services.endlessh = {
  #   enable = true;
  #   port = 6666;
  #   openFirewall = true;
  # };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    packages = with pkgs; [
      #  thunderbird
    ];
    extraGroups = [
      "audio" # Access sound hardware
      "disk" # Access /dev/sda /dev/sdb etc.
      "docker"
      "kvm" # Access virtual machines
      "networkmanager" # Access network manager
      "storage" # Access storage devices
      "video" # 2D/3D hardware acceleration & camera
      "wheel" # Access sudo command
      "scanner"
      "lp"
      "libvirtd"
    ];
    #shell = pkgs.fish;
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # NixOS Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "03:15";
    options = "--delete-older-than 10d"; # "-d"
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget

    # Linux & Sys
    direnv
    hardinfo2
    xdotool
    pavucontrol
    python315
    alsa-utils
    netscanner

    # terminals
    kitty
    # alacritty
    # xtextrm

    naps2
    simple-scan

    dnsmasq # advised through https://wiki.nixos.org/wiki/Virt-manager


    # file managers
    # nemo

    # waybar
    # nwg-dock-hyprland
    # nwg-drawer
    # nwg-panel
    # nwg-bar
    # dunst
    # hyprpanel
    # hyprlock
    # nwg-launchers
    # nwg-menu
    # nwg-look
    # nwg-displays
    # nwg-icon-picker
    # wttrbar
    # hyprmon
    # hyprlauncher
    # hyprland-workspaces
    # rofi
    # wofi
    # hyprsysteminfo
    # hyprsunset
    # hyprpolkitagent
    # hyprland-activewindow
    # hyprlandPlugins.hyprexpo
    # hyprlandPlugins.hyprbars
    # hyprlandPlugins.hyprspace
    # hyprpaper
    # hyprpwcenter
    # hyprshell
    # hyprcursor
    # ashell
    # wireplumber
    # hyprlandPlugins.hyprsplit
    # hyprlandPlugins.hyprtrails
    # hyprlandPlugins.hyprscrolling
    # hyprlandPlugins.hypr-dynamic-cursors
    # playerctl

    # Gnome & UI
    gnome-tweaks
    # marble-shell-theme
    # papirus-icon-theme
    # flat-remix-gnome
    # flat-remix-icon-theme
    # yaru-theme
    refine
    # orchis-theme
    # qogir-theme # https://itsfoss.com/best-gtk-themes/#12-qogir
    # qogir-icon-theme

    # Gnome Extensions
    gnomeExtensions.advanced-alttab-window-switcher
    gnomeExtensions.extension-list
    gnomeExtensions.move-clock
    gnomeExtensions.tiling-shell
    gnomeExtensions.overview-calculator
    gnomeExtensions.window-is-ready-remover
    gnomeExtensions.appindicator
    # gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-dock
    # gnomeExtensions.dash-to-panel
    gnomeExtensions.gsconnect
    gnomeExtensions.logo-menu
    # gnomeExtensions.search-light
    gnomeExtensions.just-perfection
    #gnomeExtensions.arcmenu
    gnomeExtensions.user-themes
    gnomeExtensions.user-themes-x
    gnomeExtensions.open-bar
    # gnomeExtensions.accent-gtk-theme
    gnomeExtensions.ulauncher-toggle
    gnomeExtensions.another-window-session-manager

    # incompatible or error
    # gnomeExtensions.dm-theme-changer
    # gnomeExtensions.accent-user-theme

    # Internet & Email
    brave
    ungoogled-chromium
    evolution
    aspell  # for evolution
    aspellDicts.en    # for evolution
    tor-browser

    dsseries
    usbutils
    sane-backends
    brscan5

    # Developer
    jetbrains.webstorm
    jetbrains.jdk
    jetbrains.pycharm
    git
    gitkraken
    github-desktop
    nodePackages_latest.nodejs
    pnpm
    vscode
    # bun
    # alejandra
    thonny
    devtoolbox

    # Inputs
    keyd # Kensington Expert Mouse
    wmctrl

    # Monitoring
    # lm_sensors
    # cockpit # Web-based graphical interface for servers

    # geospatial
    # whitebox-tools # https://www.whiteboxgeo.com/whitebox-workflows-for-python

    # CLI
    nmap
    
    # phoronix-test-suite
    # speedtest-cli
    # geekbench
    # khard

    # Virtualization
    # docker-compose
    # distrobox

    #qt5Full

    # Apps
    dbeaver-bin
    obsidian
    obs-studio
    # font-manager
    # fontforge
    libreoffice
    opensnitch-ui
    lollypop
    teams-for-linux

    # video editing
    shotcut
    # openshot-qt
    avidemux
    pitivi
    flowblade
   
    # librespot
    waydroid
    #gitkraken
    popsicle
    # pure-maps
    exiftool
    transmission_4-gtk
    bitwarden-desktop
    imagemagick
    gimp-with-plugins
    masterpdfeditor
    # pdf4qt

    freetube
    minitube
    vlc
    gImageReader
    tesseract
    ocrfeeder
    youtube-tui
    # arandr
    ente-auth
    nextcloud-client
    gradia
    postman
    motrix
    embellish
    rpi-imager
    # glances
    audacity
    # zotero
    typora
    retext
    # pulsar   # insecure package??
    apostrophe
    # clementine
    # gpodder
    # musicpod
    # podcasts
    # audacious
    clapgrep
    concessio
    xsensors
    impression
    ulauncher
    neovim
    
    #gis
    gpsd
    gpxsee
    viking
    gpx-viewer
    qgis
    udig
    gpxlab
    satellite
    # comaps

    nixpkgs-fmt
    nixd

    fd

  ];


  services.keyd = {
    enable = true;
    keyboards = {
      expertMouse = {
        ids = ["047d:1020:07438a28"];
        settings = {
          main = {
            # Example: Remap middle button to backspace
            # mouse1 = "S-f10";
            mouse1 = "rightmouse";
            middlemouse = "";
            # middle = "middle";
          };
        };
      };
    };
  };

#  systemd.user.services.ulauncher = {
#   enable = true;
#   description = "Ulauncher application launcher service";
#   documentation = [ "https://ulauncher.io" ];
#   wantedBy = [ "graphical-session.target" ];
#   PartOf = [ "graphical-session.target" ];

#   serviceConfig = {
#     Type = "simple";
#     ExecStart = "${pkgs.bash}/bin/bash -lc '${pkgs.ulauncher}/bin/ulauncher --hide-window --no-window-shadow'";
#     Restart = "on-failure";
#   };
# };



  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true; # Optional: allows access from other devices
    allowed-origins = [
        "https://em680:9090"  # The public-facing URL clients will connect from in the browser
      ];   
    settings = {
      WebService = {
        AllowUnencrypted = true; # Allows HTTP (not recommended for production)
	 ProtocolHeader = "X-Forwarded-Proto";  # Specifies the request goes through a reverse proxy
      };
    };
  };

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-25.11";

  # programs.sensors.enable = true;
  # programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.seahorse.out}/libexec/seahorse/ssh-askpass"; # for kde with gnome

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  #services.dunst.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 1714;
      to = 1764;
    }
  ];
  # networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 1714;
      to = 1764;
    }
  ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}


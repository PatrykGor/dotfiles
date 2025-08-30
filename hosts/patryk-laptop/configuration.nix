# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      inputs.emacs-overlay.overlays.package

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };
    # Opinionated: disable channels
    channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # Colors
  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
  };

  services.locate.enable = true;
  
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;
  boot.kernelParams = [ "quiet" ];

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [ git ];

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "pl_PL.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    enable = true;
    xkb = {
      layout = "pl";
      variant = "";
    };
    desktopManager.session = [
      {
        name = "home-manager";
	      start = ''
	            ${pkgs.runtimeShell} $HOME/.xsession &
	            waitPID=$!
	      '';
      }
    ];
  };

  # Configure console keymap
  console.keyMap = "pl2";

  networking = {
    hostName = "patryk-laptop";
    firewall.checkReversePath = "loose";
  };
  services.tailscale.enable = true;

  services.keyd = {
    enable = true;
    keyboards.default.settings.main = {
      capslock = "overload(control, esc)";
      esc = "capslock";
      leftalt = "leftmeta";
      leftmeta = "leftalt";
    };
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };

  users.users = {
    patryk = {
      initialPassword = "correcthorsebatterystaple";
      isNormalUser = true;
      description = "Patryk Gorski";
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      extraGroups = ["networkmanager" "wheel"];
    };
  };

#  services.udev.packages = [ pkgs.yubikey-personalization ];
#  services.udev.extraRules = ''
#   ACTION=="remove",\
#    ENV{ID_BUS}=="usb",\
#    ENV{ID_MODEL_ID}=="0407",\
#    ENV{ID_VENDOR_ID}=="1050",\
#    ENV{ID_VENDOR}=="Yubico",\
#    RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
#  '';

  services.getty = {
    loginOptions = "-p -- patryk";
    extraArgs = ["--noclear" "--skip-login"];
  };

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # Opinionated: forbid root login through SSH.
      PermitRootLogin = "no";
      # Opinionated: use keys only.
      # Remove if you want to SSH using passwords
      PasswordAuthentication = false;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}

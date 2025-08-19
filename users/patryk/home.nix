# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
    ./emacs
    ./xsession.nix
  ];

  home = {
    username = "patryk";
    homeDirectory = "/home/patryk";
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.palenight-theme;
      name = "palenight";
    };
  };

  programs.git = {
    enable = true;
    userEmail = "patryk@gorscy.net";
    userName = "Patryk Górski";
  };
  
  home.file.authinfo = {
    source = ../../secrets/authinfo;
    target = ".authinfo";
  };
  
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-emacs;
    enableSshSupport = true;
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  home.packages = with pkgs; [
    git-crypt
    dconf
    ungoogled-chromium
    arandr
    vim
    bitwarden-cli
    nixd
  ];

  # Enable home-manager and git
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}

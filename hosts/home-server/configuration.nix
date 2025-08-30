{
  inputs,
  lib,
  config,
  pkgs,
  secrets,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    config = {
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
  
  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/sdb";
    useOSProber = true;
  };

  users.users.patryk = {
    isNormalUser = true;
    description = "Patryk Górski";
    extraGroups = [ "wheel" ];
    packages = [ ];
  };

  services.getty.autologinUser = "patryk";

    fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/data".options = [ "compress=zstd" ];
    "/nix".options = [ "compress=zstd" "noatime" ];
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    git
    recyclarr
  ];

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

  console.keyMap = "pl2";

  networking = {
    hostName = "home-server";
    firewall.checkReversePath = "loose";
    # nameservers = [ "1.1.1.1" "9.9.9.9" ];
  };
  services.tailscale = {
    enable = true;
    # authKeyFile = "/data/secrets/tailscale_key";
    extraUpFlags = [
      "--ssh"
      "--advertise-tags=tag:server"
      "--exit-node=auto:any"
      "--exit-node-allow-lan-access"
    ];
  };
  
  services.flaresolverr = {
    enable = true;
    port = 8191;
  };

  nixarr = {
    enable = true;
    # These two values are also the default, but you can set them to whatever
    # else you want
    # WARNING: Do _not_ set them to `/home/user/whatever`, it will not work!
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    jellyfin.enable = true;

    transmission = {
      enable = true;
    };

    recyclarr = {
      enable = true;
      configuration = {
        sonarr = {
          series = {
            base_url = "http://home-server:8989";
            api_key = secrets.nixarr.sonarr-api-key;
            quality_definition = {
              type = "series";
            };
            delete_old_custom_formats = true;
            quality_profiles = [
              {
                name = "WEB-DL (2160p)";
                reset_unmatched_scores = {
                  enabled = true;
                  except = [
                    "Polish DL"
                    "Polish Dub"
                    "Polish Audio"
                    "Not Polish"
                    "Sub:Polish"
                  ];
                };
                min_format_score = 0;
                upgrade = {
                  allowed = true;
                  until_quality = "WEB 2160p";
                  until_score = 10000;
                };
                qualities = [
                  {
                    name = "WEB 2160p";
                    qualities = [ "WEBDL-2160p" "WEBRip-2160p" ];
                  }
                  {
                    name = "WEB 1080p";
                    qualities = [ "WEBDL-1080p" "WEBRip-1080p" ];
                  }
                  {
                    name = "Bluray-2160p";
                  }
                  {
                    name = "Bluray-1080p";
                  }
                  {
                    name = "HDTV-1080p";
                  }
                  {
                    name = "WEB 720p";
                    qualities = [ "WEBDL-720p" "WEBRip-720p" ];
                  }
                  {
                    name = "Bluray-720p";
                  }
                  {
                    name = "HDTV-720p";
                  }
                ];
              }
            ];
            media_naming = {
              series = "jellyfin-tvdb";
              season = "default";
              episodes = {
                rename = true;
                standard = "default";
                daily = "default";
                anime = "default";
              };
            };
            custom_formats = [
              {
                trash_ids = [
                  "505d871304820ba7106b693be6fe4a9e" # HDR
                  # "7c3a61a9c6cb04f52f1544be6d44a026" # DV Boost
                  "0c4b99df9206d2cfac3c05ab897dd62a" # HDR10+ Boost
                  "9b27ab6498ec0f31a3353992e19434ca" # DV (WEBDL)
                  
                  "85c61753df5da1fb2aab6f2a47426b09" # BR-DISK
                  "9c11cd3f07101cdba90a2d81cf0e56b4" # LQ
                  "e2315f990da2e2cbfc9fa5b7a6fcfe48" # LQ (Release Title)
                  "fbcb31d8dabd2a319072b84fc0b7249c" # Extras
                  "15a05bc7c1a36e2b57fd628f8977e2fc" # AV1

                  "ec8fa7296b64e8cd390a1600981f3923" # Repack/Proper
                  "eb3d5cc0a2be0db205fb823640db6a3c" # Repack v2
                  "44e7c4de10ae50265753082e5dc76047" # Repack v3

                  "d660701077794679fd59e8bdf4ce3a29" # AMZN
                  "f67c9ca88f463a48346062e8ad07713f" # ATVP
                  "77a7b25585c18af08f60b1547bb9b4fb" # CC
                  "36b72f59f4ea20aad9316f475f2d9fbb" # DCU
                  "89358767a60cc28783cdc3d0be9388a4" # DSNP
                  "a880d6abc21e7c16884f3ae393f84179" # HMAX
                  "7a235133c87f7da4c8cccceca7e3c7a6" # HBO
                  "f6cce30f1733d5c8194222a7507909bb" # HULU
                  "0ac24a2a68a9700bcb7eeca8e5cd644c" # iT
                  "81d1fbf600e2540cee87f3a23f9d3c1c" # MAX
                  "d34870697c9db575f17700212167be23" # NF
                  "c67a75ae4a1715f2bb4d492755ba4195" # PMTP
                  "1656adc6d7bb2c8cca6acfb6592db421" # PCOK
                  "ae58039e1319178e6be73caab5c42166" # SHO
                  "1efe8da11bfd74fbbcd4d8117ddb9213" # STAN
                  "9623c5c9cac8e939c1b9aedd32f640bf" # SYFY
                  "43b3cf48cb385cd3eac608ee6bca7f09" # UHD Streaming Boost
                  "d2d299244a92b8a52d4921ce3897a256" # UHD Streaming Cut

                  "e6258996055b9fbab7e9cb2f75819294" # WEB Tier 01
                  "58790d4e2fdcd9733aa7ae68ba2bb503" # WEB Tier 02
                  "d84935abd3f8556dcd51d4f27e22d0a6" # WEB Tier 03
                  "d0c516558625b04b363fa6c5c2c7cfd4" # WEB Scene

                  "9b64dff695c2115facf1b6ea59c9bd07" # x265 (no HDR/DV)
                ];
                assign_scores_to = [
                  { name = "WEB-DL (2160p)"; }
                ];
              }
            ];
          };
        };
        radarr = {
          movies = {
            base_url = "http://home-server:7878";
            api_key = secrets.nixarr.radarr-api-key;
            quality_definition = {
              type = "movie";
            };
            delete_old_custom_formats = true;
          };
        };
      };
    };
    # lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    # readarr.enable = true;
    sonarr.enable = true;
    jellyseerr.enable = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}

{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  xsession = {
    enable = true;
    # initExtra = "emacs --daemon";
    windowManager.command = "emacs";
  };
}

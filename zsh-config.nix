{ inputs, ... }:

{
  programs.zsh.interactiveShellInit = builtins.readFile "${inputs.configfiles}/zshrc";
  # All of these interfere with my settings:
  programs.zsh.enableLsColors = false;
  programs.zsh.enableCompletion = false;
  programs.zsh.enableGlobalCompInit = false;
  programs.zsh.promptInit = "";
}

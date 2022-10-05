# user-nix-steam-deck
Do you want to install Linux command line apps on your Steam Deck without messing with the base system? This script creates a single directory (~/nix) that installs a ~1GB [NixOS](https://nixos.org/) environment. Packages are managed declaratively using [home-manager](https://github.com/nix-community/home-manager) and [flakes](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html).

## Walk through

Install nix, create a flake.nix and home.nix, and setup home-manager to use flakes.
```
bash-5.1$ bash user-nix-steam-deck.sh
Downloading nix-user-chroot
--2022-09-05 04:11:20--  https://github.com/nix-community/nix-user-chroot/releases/download/1.2.2/nix-user-chroot-bin-1.2.2-x86_64-unknown-linux-musl
Resolving github.com (github.com)... 192.30.255.112
Connecting to github.com (github.com)|192.30.255.112|:443... connected.
.
.
.
Q11. Where are these instructions stored?

  /home/deck/nix/home/README

Q12. How do I enter the nix environment again? Run:

  /home/deck/nix/enter

783M    /home/deck/nix
home: /home/deck/nix/home

bash-5.1$ 
```

Take a look at the setup environment.
```
bash-5.1$ ls
deck  home.nix  README

bash-5.1$ which bash
~/.nix-profile/bin/bash
```

Use home-manager switch to rebuild the nix environment.
```
bash-5.1$ home-manager switch
Starting Home Manager activation
Activating checkFilesChanged
Activating checkLinkTargets
Activating writeBoundary
Activating installPackages
replacing old 'home-manager-path'
installing 'home-manager-path'
building '/nix/store/axgc0jk36a0kr7djs6z4402ib7i3diy0-user-environment.drv'...
Activating linkGeneration
Cleaning up orphan links from /home/deck/nix/home
No change so reusing latest profile generation 1
Creating home file links in /home/deck/nix/home
Activating onFilesChange
Activating reloadSystemd
User systemd daemon not running. Skipping reload.
```

Leave the nix environment.
```
bash-5.1$ exit
logout
```

Enter the nix environment again.
```
[deck ~]$ nix/enter
791M    /home/deck/nix
home: /home/deck/nix/home
```

Search for a package (ncdu).
```
bash-5.1$ nix search nixpkgs ncdu
* legacyPackages.x86_64-linux.ncdu (2.1.2)
  Disk usage analyzer with an ncurses interface

* legacyPackages.x86_64-linux.ncdu_1 (1.17)
  Disk usage analyzer with an ncurses interface

* legacyPackages.x86_64-linux.ncdu_2 (2.1.2)
  Disk usage analyzer with an ncurses interface

bash-5.1$
```

Run a package (ncdu).
```
bash-5.1$ nix run nixpkgs#ncdu
```

Enter a shell with a specific package available.
```
bash-5.1$ nix shell nixpkgs#ncdu
bash-4.2$ ncdu
```

Install a program.
```
bash-5.1$ vim home.nix
# Add the package name to the home.packages list and save home.nix:
#
#   home.packages = (with pkgs; [
#     ncdu
#     nix nettools bashInteractive
#   ]);

bash-5.1$ home-manager switch
Starting Home Manager activation
Activating checkFilesChanged
Activating checkLinkTargets
Activating writeBoundary
Activating installPackages
replacing old 'home-manager-path'
installing 'home-manager-path'
building '/nix/store/2hpdvhyinhd2453npv1990v1ybxvvknx-user-environment.drv'...
Activating linkGeneration
Cleaning up orphan links from /home/deck/nix/home
Creating profile generation 3
Creating home file links in /home/deck/nix/home
Activating onFilesChange
Activating reloadSystemd
User systemd daemon not running. Skipping reload.

bash-5.1$ 
```

Update installed programs.
```
bash-5.1$ nix registry pin nixpkgs

bash-5.1$ nix flake update ~/.config/nixpkgs/flake.nix
path '/home/deck/nix/home/.config/nixpkgs/flake.nix' does not contain a 'flake.nix', searching up

bash-5.1$ home-manager switch
Starting Home Manager activation
Activating checkFilesChanged
Activating checkLinkTargets
Activating writeBoundary
Activating installPackages
replacing old 'home-manager-path'
installing 'home-manager-path'
Activating linkGeneration
Cleaning up orphan links from /home/deck/nix/home
No change so reusing latest profile generation 1
Creating home file links in /home/deck/nix/home
Activating onFilesChange
Activating reloadSystemd
User systemd daemon not running. Skipping reload.

bash-5.1$
```

Take a look at the home.nix
```
bash-5.1$ cat home.nix 
# After editing this file, run:
#
#   home-manager switch
#
{ config, pkgs, ... }: {
  home.username = "deck";
  home.homeDirectory = "/home/deck/nix/home";
  home.stateVersion = "22.05";

  home.packages = (with pkgs; [
    nix nettools bashInteractive
    # To find more packages, use:
    #
    #   nix search nixpkgs NAME
    #
  ]);

  #To find more home-manager programs use:
  #
  #  man home-configuration.nix
  #
  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    profileExtra = ''
      . "${config.home.profileDirectory}/etc/profile.d/nix.sh"
    '';
  };
}
```

Take a look at the README.
```
bash-5.1$ cat README
Q1. How do I enter the nix environment? Run:

  /home/deck/nix/enter

Q2. How do I run a program without installing it?

  nix run nixpkgs#ncdu
  nix run nixpkgs#vlc

or

  nix shell nixpkgs#ncdu
  ncdu

Q3. How do I find a program to run?

  nix search nixpkgs ncdu

Q4. How do I install a program? Add the name of the program to home.nix's home.packages line. For example:

  home.packages = (with pkgs; [
    nix nettools bashInteractive
    ncdu vlc
  ]);

Then rebuild with:

  home-manager switch

Q5. Where is the home.nix and flake.nix?

  /home/deck/nix/home/.config/nixpkgs/home.nix
  /home/deck/nix/home/.config/nixpkgs/flake.nix

Q6. How do I rebuild after editing home.nix or flake.nix? Run:

   home-manger switch  

Q7. How do I update the programs?

  nix registry pin nixpkgs
  nix flake update ~/.config/nixpkgs
  home-manager switch

Q8. How do I delete programs that are no longer installed?

  nix-collect-garbage -d

Q9. What is the layout of this install?

  dir          /home/deck/nix
  enter script /home/deck/nix/enter
  home         /home/deck/nix/home
  README       /home/deck/nix/home/README
  nix store    /home/deck/nix/root-nix/store

Q10. How do I remove everything, including the nix home directory?

  chmod -R u+w '/home/deck/nix'
  rm '/home/deck/nix' -r

Q11. Where are these instructions stored?

  /home/deck/nix/home/README

Q12. How do I enter the nix environment again? Run:

  /home/deck/nix/enter
```

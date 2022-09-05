#!/bin/bash

export N=/dev/shm/nix     # temp install to RAM
#export N=$HOME/nix  # real install to ~/nix

{
oops() { echo "$0:" "$@" >&2; exit 1; }
title() { echo "$*"; sleep 0.5; printf "\033]0;%s\007" "$*"; }

USER=$(id -u -n)

if [ -d $N ]; then
    echo "Nix already installed. Entering environment."
    echo "In future enter nix by running:"
    echo
    echo "  $N/enter"
    echo
    exec $N/enter
fi

mkdir $N $N/root-nix $N/home $N/home/.config $N/home/.config/{nix,nixpkgs} || oops "Unable to create directories"
ln -s $HOME $N/home/$USER || oops "unable to create $USER symlink"
ln -s .config/nixpkgs/home.nix $N/home/home.nix || oops "unable to create home.nix symlink"

title "Downloading nix-user-chroot"
wget -O $N/nix-user-chroot https://github.com/nix-community/nix-user-chroot/releases/download/1.2.2/nix-user-chroot-bin-1.2.2-x86_64-unknown-linux-musl || oops "Failed to download nix-user-chroot"
chmod u+x $N/nix-user-chroot || oops "Unable to make $N/nix-user-chroot executable"

title "Downloading nixos.org/nix/install"
wget -O $N/nix.install https://nixos.org/nix/install || oops "Failed to download nixos.org/nix/install"

title "Creating files"
cat <<EOF > $N/home/README
Q1. How do I enter the nix environment? Run:

  $N/enter

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
    nixFlakes nettools bashInteractive
    ncdu vlc
  ]);

Then rebuild with:

  home-manager switch

Q5. Where is the home.nix and flake.nix?

  $N/home/.config/nixpkgs/home.nix
  $N/home/.config/nixpkgs/flake.nix

Q6. How do I rebuild after editing home.nix or flake.nix? Run:

   home-manger switch  

Q7. How do I update the programs?

  nix registry pin nixpkgs
  nix flake update ~/.config/nixpkgs
  home-manager switch

Q8. How do I delete programs that are no longer installed?

  nix-collect-garbage -d

Q9. What is the layout of this install?

  dir          $N
  enter script $N/enter
  home         $N/home
  README       $N/home/README
  nix store    $N/root-nix/store

Q10. How do I remove everything, including the nix home directory?

  chmod -R u+w '$N'
  rm '$N' -r

Q11. Where are these instructions stored?

  $N/home/README

Q12. How do I enter the nix environment again? Run:

  $N/enter

EOF

cat <<EOF > $N/home/.config/nix/nix.conf
experimental-features = nix-command flakes
EOF

cat <<EOF > $N/home/.config/nixpkgs/flake.nix
{
  inputs = {
    hm.url = "github:nix-community/home-manager";
  };
  outputs = { self, nixpkgs, hm }: {
    homeConfigurations.$USER = hm.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        ./home.nix
      ];
    };
  };
}
EOF

cat <<EOF > $N/home/.config/nixpkgs/home.nix
# After editing this file, run:
#
#   home-manager switch
#
{ config, pkgs, ... }: {
  home.username = "$USER";
  home.homeDirectory = "$N/home";
  home.stateVersion = "22.05";

  home.packages = (with pkgs; [
    nixFlakes nettools bashInteractive
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
      . "\${config.home.profileDirectory}/etc/profile.d/nix.sh"
    '';
  };
}
EOF

cat <<EOF > $N/enter
#!/bin/bash
export HOME=$N/home
cd ~/
du -hs $N
echo "home:" \$HOME
exec $N/nix-user-chroot $N/root-nix ~/.nix-profile/bin/bash -l
EOF

chmod u+x $N/enter || oops "Unable to make $N/enter executable"

cat <<EOF > $N/home-manager-flake.install
oops() { echo "$0:" "$@" >&2; exit 1; }
title() { printf "\033]0;%s\007" "$*"; }

title "Loading ~/.nix-profile/etc/profile.d/nix.sh"
. ~/.nix-profile/etc/profile.d/nix.sh || oops "failed to source ~/.nix-profile/etc/profile.d/nix.sh"

title "nix registry pin nixpkgs"
nix registry pin nixpkgs || oops "failed to: nix registry pin nixpkgs"

title "Building home-manager configuration"
nix-env --set-flag priority 10 nix || oops "failed to: nix-env --set-flag priority 10 nix"
nix build --no-link ~/.config/nixpkgs/flake.nix#homeConfigurations.$USER.activationPackage || oops "failed to build ~/.config/nixpkgs/flake.nix#homeConfigurations.$USER.activationPackage"

title "Activating home-manager configuration"
"\$(nix path-info ~/.config/nixpkgs/flake.nix#homeConfigurations.$USER.activationPackage)"/activate || oops "failed to activate home-manager config"

title "Removing nix-env's nix command"
nix-env -e nix || oops "failed to remove nix-env's version of the nix command"

title "nix-collect-garbage -d"
nix-collect-garbage -d || oops "failed to nix-collect-garbage -d"
EOF

title "Running nixos.org/nix/install"
HOME=$N/home $N/nix-user-chroot $N/root-nix /bin/bash $N/nix.install || oops "nixos.org/nix/install failed"

title "Installing home-manager"
HOME=$N/home $N/nix-user-chroot $N/root-nix /bin/bash $N/home-manager-flake.install || oops "home-manager-flake.install failed"

echo
du -hs $N
echo
cat $N/home/README

$N/enter
}

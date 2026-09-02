{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = [
    (pkgs.python310.withPackages (pythonPackages: with pythonPackages; [
      setuptools
      build
      rembg
      pillow
    ]))
  ];

  shellHook = ''
    echo "Shinyuu development environment loaded."
    python --version
  '';
}

{
  description = "Shinyuu development environment with CUDA support";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos-cuda.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      # Configure Nixpkgs with CUDA and unfree support
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };

      # Build Python 3.10 with the required GPU packages
      pythonEnv = pkgs.python310.withPackages (ps: with ps; [
        setuptools
        build
        rembg
        onnxruntime-gpu # Provides GPU backing for rembg
        pillow
      ]);
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pythonEnv
          pkgs.cudaPackages.cudatoolkit # Provides essential CUDA drivers/libraries
        ];

        shellHook = ''
          # Expose C++ / NVIDIA libraries so ONNX Runtime can access the GPU drivers
          export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.linuxPackages.nvidia_x11}/lib:$LD_LIBRARY_PATH"

          echo "Shinyuu development environment loaded."
          python --version
        '';
      };
    };
}

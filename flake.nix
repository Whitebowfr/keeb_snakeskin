{
  description = "runme application";

  inputs = {
    # Helpers for system-specific outputs
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    # Create system-specific outputs for the standard Nix systems
    # https://github.com/numtide/flake-utils/blob/master/default.nix#L3-L9
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
	      pythonPackages = pkgs.python312Packages;
      in
      {
	      buildInputs = [
          # A Python interpreter including the 'venv' module is required to bootstrap
          # the environment.
          pythonPackages.python

          # This executes some shell code to initialize a venv in $venvDir before
          # dropping into the shell
          pythonPackages.venvShellHook
          pkgs.xorg.libX11
          pkgs.xorg.libX11.dev
          pkgs.expat
          pkgs.libGL
          # Those are dependencies that we would like to use from nixpkgs, which will
          # add them to PYTHONPATH and thus make them accessible from within the venv.
          pythonPackages.numpy
        ];
	
	      postShellHook = ''
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${
            with pkgs;
                lib.makeLibraryPath [ libGL xorg.libX11 xorg.libXi expat]
              }"
       '';

        # A simple executable package
        packages.default = pkgs.writeScriptBin "runme" ''
          #!/bin/bash
          python ./src/snakeskin.py

        '';


        # An app that uses the `runme` package

        apps.default = {

          type = "app";

          program = "${self.packages.${system}.default}/bin/runme";

        };
      });
}

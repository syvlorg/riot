{
    nixConfig = {
        # Adapted From: https://github.com/divnix/digga/blob/main/examples/devos/flake.nix#L4
        # extra-substituters = "https://cache.nixos.org/ https://nix-community.cachix.org/";
        trusted-substituters = "https://cache.nixos.org/";
        # extra-trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        # keep-derivations = true;
        # keep-outputs = true;
        extra-experimental-features = "nix-command flakes";
        # accept-flake-config = true;
        # show-trace = true;
        # fallback = true;
        # auto-optimise-store = true;
        # builders-use-substitutes = true;
        # cores = 0;
        # flake-registry = https://raw.githubusercontent.com/sylvorg/settings/main/flake-registry.json;
        # allow-unsafe-native-code-during-evaluation = true;
        # min-free = 262144000;
        # max-free = 1073741824;
    };
    description = "Automatically import supported filetypes as `org' on opening, then exporting back as the original type when saving!";
    inputs = rec {
        settings.url = github:sylvorg/settings;
        titan.follows = "settings/titan";
        nixpkgs.follows = "settings/nixpkgs";

        epkg-meq.url = github:syvlorg/meq;

        flake-utils.url = github:numtide/flake-utils;
        flake-compat = {
            url = "github:edolstra/flake-compat";
            flake = false;
        };
    };
    outputs = inputs@{ self, flake-utils, settings, ... }: with builtins; with settings.lib; with flake-utils.lib; settings.mkOutputs {
        inherit inputs;
        type = "emacs-nox";
        pname = "riot";
        callPackage = { emacs, pname }: emacs.pkgs.trivialBuild rec {
            inherit pname;
            src = ./.;
            buildInputs = flatten [ emacs propagatedUserEnvPkgs ];
            propagatedUserEnvPkgs = with emacs.pkgs; flatten [ meq meq.propagatedUserEnvPkgs a ];
            meta = {
              inherit (emacs.meta) platforms;
              homepage = "https://github.com/syvlorg/${pname}";
              description = "Automatically import supported filetypes as `org' on opening, then exporting back as the original type when saving!";
            };
        };
    };
}

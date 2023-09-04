with builtins;
let
  this-flake = import ./.;
  flake =
    this-flake.inputs.valiant or this-flake.inputs.bundle.inputs.valiant or (if (builtins
      ? getFlake) then
      (getFlake "github:syvlorg/valiant")
    else
      (import fetchTarball (let
        lockExists = pathExists ./flake.lock;
        lock = if lockExists then
          (fromJSON (readFile ./flake.lock))
        else {
          nodes.valiant.locked.rev = "main";
        };
      in {
        url =
          "https://github.com/syvlorg/valiant/archive/${lock.nodes.valiant.locked.rev}.tar.gz";
        ${if lockExists then "sha256" else null} =
          lock.nodes.valiant.locked.narHash;
      }) { src = ./.; }).defaultNix);
  inherit (flake.${currentSystem}) pkgs;
in with pkgs;
mkShell rec {
  buildInputs = [ valiant ];
  nativeBuildInputs = buildInputs;
}

with builtins; if (builtins ? getFlake) then (getFlake (toString ./.)) else (import fetchTarball (let
    lockExists = pathExists ./flake.lock;
    lock = if lockExists then (fromJSON (readFile ./flake.lock)) else { nodes.flake-compat.locked.rev = "master"; };
in {
    url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    ${if lockExists then "sha256" else null} = lock.nodes.flake-compat.locked.narHash;
}) { src = ./.; }).defaultNix

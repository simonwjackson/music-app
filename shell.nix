let
  pkgs = import <nixpkgs> { overlays = [ (import ./cypress-overlay.nix) ]; };
  project_root = builtins.toString ./.;

  osShellHook =
    if pkgs.system == "x86_64-linux" then ''
      export CYPRESS_INSTALL_BINARY=0
      export CYPRESS_RUN_BINARY=${pkgs.cypress}/bin/Cypress

    '' else ''
      # No exports needed
    '';

  osCypressInputs =
    if pkgs.system == "x86_64-linux" then with pkgs; [
      cypress
      (with dotnetCorePackages; combinePackages [ sdk_5_0 runtime_5_0 ])
    ] else [

    ];
in
pkgs.mkShell {
  name = "gtv-frontend";

  buildInputs = with pkgs; [
    nodePackages.lcov-result-merger
    nodejs-16_x
    yarn
    git
    tmux
    entr
  ] ++ osCypressInputs;

  shellHook = ''
    ${osShellHook}
    export CYPRESS_CRASH_REPORTS=0
    export CYPRESS_COMMERCIAL_RECOMMENDATIONS=0

    export PATH+=$PATH:${project_root}/node_modules/.bin
    export PATH+=$PATH:${project_root}/bin

    export $(cat ${project_root}/.env | xargs)
    env.mts

    yarn install

    # TODO: Move this into nx
    # lcov-result-merger './{apps,libs}/**/lcov.info' "${project_root}/coverage/lcov.info"
  '';
}

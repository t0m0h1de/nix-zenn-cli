{
  description = "A flake for the latest zenn-cli using pnpm";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation (finalAttrs:
          let
            pnpm = pkgs.pnpm_10;
          in
          {
          pname = "zenn-cli";
          version = "0.5.7";

          src = pkgs.fetchFromGitHub {
            owner = "zenn-dev";
            repo = "zenn-editor";
            rev = "v${finalAttrs.version}";
            hash = "sha256-ZT+MRJRQ3wNoUEroP+OdK45IbAA1hvSv/L0G++ZIHRM=";
          };

          sourceRoot = "source";

          nativeBuildInputs = [ 
            pkgs.makeWrapper
            pkgs.nodejs
            pnpm
            pkgs.pnpmConfigHook
          ];

          pnpmWorkspaces = [ "zenn-cli..." ];

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) pname version src pnpmWorkspaces;
            inherit pnpm;
            fetcherVersion = 3;
            hash = "sha256-Qnrh1Q+89KSiv09KVBj5oIIxXV3uwb1PaTiW7K8wrdY=";
          };

          preBuild = ''
            echo 'VITE_EMBED_SERVER_ORIGIN="https://embed.zenn.studio"' > packages/zenn-cli/.env
          '';

          buildPhase = ''
            runHook preBuild
            pnpm build --no-daemon
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin $out/lib/packages
            rm -rf node_modules packages/zenn-cli/node_modules packages/zenn-markdown-html/node_modules
            pnpm install --filter=zenn-cli --filter=zenn-markdown-html --prod --ignore-scripts
            cp -r node_modules $out/lib/
            # zenn-cli has a production dependency on this workspace package.
            # pnpm represents workspace dependencies as symlinks, so preserve
            # the matching package layout in the output to avoid a dangling
            # symlink after Nix's fixup phase.
            cp -r packages/zenn-markdown-html $out/lib/packages/zenn-markdown-html
            cp -r packages/zenn-cli $out/lib/packages/zenn-cli
            makeWrapper ${pkgs.nodejs}/bin/node $out/bin/zenn \
              --add-flags $out/lib/packages/zenn-cli/dist/server/zenn.js
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "CLI tool for Zenn";
            homepage = "https://github.com/zenn-dev/zenn-editor";
            license = licenses.mit;
            mainProgram = "zenn";
            platforms = platforms.all;
          };
          });
      });
    };
}

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
          version = "0.4.6";

          src = pkgs.fetchFromGitHub {
            owner = "zenn-dev";
            repo = "zenn-editor";
            rev = "v${finalAttrs.version}";
            hash = "sha256-tv6H/KvA4vgb3Fsvz9rkf1DAJxidRExpvjIUV8FK1L0=";
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
            hash = "sha256-duKl1fQlXPJZuBiw/5xiq9ixpMXKNF1X4By4l+QSIf8=";
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
            rm -rf node_modules packages/zenn-cli/node_modules
            pnpm install --filter=zenn-cli --prod --ignore-scripts
            cp -r node_modules $out/lib/
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

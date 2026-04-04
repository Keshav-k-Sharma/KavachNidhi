{
  description = "Flutter frontend (Android via Nix-composed SDK)";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, android-nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk = {
            accept_license = true;
          };
        };
      };
      pinnedJDK = pkgs.jdk17;
      androidSdk = android-nixpkgs.sdk.${system} (
        sdkPkgs: with sdkPkgs; [
          cmdline-tools-latest
          platform-tools
          build-tools-35-0-0
          platforms-android-34
          platforms-android-35
          platforms-android-36
          ndk-28-2-13676358
          cmake-3-22-1
        ]
      );
    in {
      devShells.default = pkgs.mkShell {
        name = "frontend-flutter";
        buildInputs =
          (with pkgs; [flutter pinnedJDK])
          ++ [androidSdk];
        shellHook = ''
          export GRADLE_USER_HOME="''${HOME}/.gradle"
          export ANDROID_USER_HOME="''${HOME}/.android"
          export ANDROID_SDK_HOME="''${HOME}"
        '';
        JAVA_HOME = pinnedJDK;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
      };
    });
}

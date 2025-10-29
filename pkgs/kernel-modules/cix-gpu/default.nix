{
  lib,
  fetchFromGitLab,
  stdenv,
  kernel,
  kernelModuleMakeFlags,
  nix-update-script,
  ...
}:
let
  kernelVersion = kernel.modDirVersion;
  kernelDir = "${kernel.dev}/lib/modules/${kernelVersion}";
in
stdenv.mkDerivation (finalAttr: {
  pname = "cix-gpu";
  version = "1.0.0";

  src = fetchFromGitLab {
    owner = "cix-linux/cix_opensource";
    repo = "gpu_kernel";
    rev = "b8eee14f46f2aba8cdcf524a406a29ec75a0d8db";
    hash = "sha256-8QN5y3Vy/WF7cAWDNCDwe5obS2IzdI3FmXgRWAvWeZA=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  postPatch = ''
    patchShebangs .
  '';

  makeFlags = kernelModuleMakeFlags ++ [
    "KDIR=${kernelDir}"
    "KVER=${kernelVersion}"
  ];

  installFlags = [ "INSTALL_MOD_PATH=$(out)" ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version"
      "branch=ee8f6/48bff/cix_p1_K6.6_2025Q3_dev"
    ];
  };

  meta = {
    description = "Mellanox virtiofs kernel module";
    platforms = [ "aarch64-linux" ];
    maintainers = with lib.maintainers; [ codgician ];
  };
})

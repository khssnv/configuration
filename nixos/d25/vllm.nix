{ lib, pkgs, ... }:

let
  modelConfig = {
    model = "google/gemma-4-E4B-it";
    revision = "ee0ef6023621cff504d758262d4e04895a5af4a2";
    # Core Ultra 9 285K has AVX2, without AVX512/BF16 instructions.
    dtype = "float32";
    max-model-len = 4096;
    max-num-seqs = 1;
    reasoning-parser = "gemma4";
    language-model-only = true;
  };

  # vLLM 0.32 expects the model as a positional argument, outside the YAML.
  # JSON is valid YAML; using it avoids a build-time YAML serializer.
  configFile = pkgs.writeText "vllm-model.yaml" (
    builtins.toJSON (builtins.removeAttrs modelConfig [ "model" ])
  );
in

{
  systemd.tmpfiles.rules = [
    "d /var/lib/vllm/huggingface 0750 root root -"
  ];

  virtualisation.oci-containers = {
    backend = "docker";
    containers.vllm = {
      image = "vllm/vllm-openai-cpu:v0.32.0-x86_64@sha256:827ef38187f9b52f2bb838695ef815ec5b65f4bf3e4c061b002b2b0a19cb0701";

      volumes = [
        "/var/lib/vllm/huggingface:/root/.cache/huggingface"
        "${configFile}:/etc/vllm/model.yaml:ro"
      ];

      environment = {
        VLLM_CPU_KVCACHE_SPACE = "2";
        VLLM_CPU_NUM_OF_RESERVED_CPU = "1";
      };

      # Host networking keeps LAN access under the NixOS input firewall.
      extraOptions = [
        "--network=host"
        "--shm-size=4g"
      ];

      cmd = [
        modelConfig.model
        "--config"
        "/etc/vllm/model.yaml"
      ];
    };
  };

  # Retry transient download failures without exhausting systemd's start limit.
  systemd.services.docker-vllm.serviceConfig.RestartSec = "10s";

  networking.firewall.interfaces =
    lib.genAttrs
      [
        "enp129s0"
        "wlp128s20f3"
      ]
      (_: {
        allowedTCPPorts = [ 8000 ];
      });
}

{
  den.aspects.ai.nixos =
    { config, pkgs, ... }:
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        user = "ollama";
        group = "ollama";
        loadModels = [ "hf.co/unsloth/Qwen3.8-27B-GGUF:UD-Q3_K_XL" ];
        environmentVariables = {
          OLLAMA_CONTEXT_LENGTH = "32768";
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
        };
      };

      systemd.services.ollama-tuned-models = {
        description = "Build tuned ollama models from checked-in Modelfiles";
        wantedBy = [ "multi-user.target" ];
        after = [
          "ollama.service"
          "ollama-model-loader.service"
        ];
        bindsTo = [ "ollama.service" ];
        environment = {
          OLLAMA_HOST = "127.0.0.1:11434";
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "ollama";
          Group = "ollama";
          TimeoutStartSec = "2h";
        };
        path = [ config.services.ollama.package ];
        script = ''
          base=hf.co/unsloth/Qwen3.8-27B-GGUF:UD-Q3_K_XL
          until ollama show "$base" >/dev/null 2>&1; do sleep 15; done
          ollama create qwen38 -f ${./qwen38.Modelfile}
        '';
      };
    };
}

{
  den.aspects.ai.nixos =
    { config, pkgs, ... }:
    let
      modelsDir = config.services.ollama.modelsDir;
      ggufDir = "${dirOf modelsDir}/gguf";
      gguf = "${ggufDir}/Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf";
      ggufUrl = "https://huggingface.co/ISTA-DASLab/Qwen3.8-27B-GSQ-RCO-GGUF/resolve/main/Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf";
      ollamaHost = "${config.services.ollama.host}:${toString config.services.ollama.port}";
      modelfile = pkgs.writeText "qwen38.Modelfile" ''
        FROM ${gguf}

        PARAMETER num_ctx 65536
        PARAMETER temperature 1.0
        PARAMETER top_p 0.95
        PARAMETER top_k 20
        PARAMETER min_p 0.0
        PARAMETER repeat_penalty 1.0
      '';
    in
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        user = "ollama";
        group = "ollama";
        environmentVariables = {
          OLLAMA_CONTEXT_LENGTH = "65536";
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
        };
      };

      systemd.tmpfiles.rules = [ "d ${ggufDir} 0750 ollama ollama -" ];

      systemd.services.ollama-tuned-models = {
        description = "Build the tuned qwen38 model from its GGUF";
        wantedBy = [ "multi-user.target" ];
        after = [ "ollama.service" ];
        bindsTo = [ "ollama.service" ];
        unitConfig.RequiresMountsFor = [ modelsDir ];
        environment.OLLAMA_HOST = ollamaHost;
        path = [
          config.services.ollama.package
          pkgs.curl
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "ollama";
          Group = "ollama";
          TimeoutStartSec = "2h";
        };
        # ollama's registry client fetches every blob as a ranged request, and
        # hf.co serves this repo's 481-byte config blob in >30s that way, always
        # tripping ollama's fixed 30s deadline. Fetch the GGUF directly instead.
        script = ''
          if [ ! -s ${gguf} ]; then
            curl -fL --retry 5 --retry-delay 5 -C - -o ${gguf}.part ${ggufUrl}
            mv ${gguf}.part ${gguf}
          fi
          ollama create qwen38 -f ${modelfile}
        '';
      };
    };
}

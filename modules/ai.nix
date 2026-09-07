{
  den.aspects.ai.nixos =
    { config, pkgs, ... }:
    let
      modelsDir = config.services.ollama.modelsDir;
      ggufDir = "${dirOf modelsDir}/gguf";
      gguf = "${ggufDir}/Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf";
      ggufUrl = "https://huggingface.co/ISTA-DASLab/Qwen3.8-27B-GSQ-RCO-GGUF/resolve/main/Qwen3.8-27B-GSQ-RCO-IQ3_XXS.gguf";
      ggufSha256 = "fdfcb6a29b11188956dfbfd904223588a6c1b77eb250c3e8a36e1bd269df91f7";
      ggufSize = "10094357632";
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

      # ollama's module leaves modelsDir to the operator, and a ReadWritePaths
      # entry that does not exist fails the unit's namespace setup. Creating
      # these via tmpfiles would race a nofail mount and land them on the root
      # filesystem instead, so gate on the mount here.
      systemd.services.ollama-dirs = {
        description = "Create the ollama model and GGUF directories";
        requiredBy = [ "ollama.service" ];
        before = [ "ollama.service" ];
        unitConfig.RequiresMountsFor = [ modelsDir ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          for d in ${modelsDir} ${ggufDir}; do
            mkdir -p "$d"
            chown ollama:ollama "$d"
            chmod 0750 "$d"
          done
        '';
      };

      systemd.services.ollama-tuned-models = {
        description = "Build the tuned qwen38 model from its GGUF";
        wantedBy = [ "multi-user.target" ];
        after = [
          "ollama.service"
          "network-online.target"
        ];
        wants = [ "network-online.target" ];
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
          Restart = "on-failure";
          RestartSec = 60;
          TimeoutStartSec = "2h";
        };
        # ollama's registry client fetches every blob as a ranged request, and
        # hf.co serves this repo's 481-byte config blob in >30s that way, always
        # tripping ollama's fixed 30s deadline. Fetch the GGUF directly instead.
        script = ''
          if [ "$(stat -c %s ${gguf} 2>/dev/null || echo 0)" != "${ggufSize}" ]; then
            curl -fL --retry 5 --retry-delay 5 -C - -o ${gguf}.part ${ggufUrl}
            echo "${ggufSha256}  ${gguf}.part" | sha256sum -c --status
            mv ${gguf}.part ${gguf}
          fi

          # ollama.service is Type=exec, so it is "started" before the HTTP
          # listener accepts connections.
          until curl -sf "http://${ollamaHost}/" >/dev/null; do sleep 2; done

          ollama create qwen38 -f ${modelfile}
        '';
      };
    };
}

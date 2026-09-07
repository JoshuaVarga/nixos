{
  den.aspects.ai.nixos =
    { pkgs, ... }:
    {
      services.ollama.enable = true;
      services.ollama.package = pkgs.ollama-cuda;
      services.ollama.user = "ollama";
      services.ollama.group = "ollama";
      services.ollama.environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "131072";
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
      };
    };
}

{
  den.aspects.ai.nixos =
    { pkgs, ... }:
    {
      services.ollama.enable = true;
      services.ollama.package = pkgs.ollama-cuda;
    };
}

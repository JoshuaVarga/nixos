{ inputs, lib, ... }:
let
  rev = inputs.self.rev or inputs.self.dirtyRev or "dirty";
in
{
  den.aspects.version.nixos = {
    system.configurationRevision = rev;
    system.nixos.label = "${lib.fileContents ../VERSION}.g${builtins.substring 0 7 rev}";
  };
}

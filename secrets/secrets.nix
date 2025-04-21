let
  usu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILPV/ur0bttQ5BA/Hzr2zulipcQh+KHZGpgqx29qkAgu martonaronvarga@gmail.com";
in {
  "usu.age".publicKeys = [usu];
}

{ lib, stdenv, fetchFromGitHub, rustPlatform, Security }:

rustPlatform.buildRustPackage rec {
  pname = "cargo-show-asm";
  version = "0.2.38";

  src = fetchFromGitHub {
    owner = "pacak";
    repo = pname;
    rev = version;
    sha256 = "df6kzsmxgdms9lq5z9ynnmxymk9k2lzlp3caa52wqjvdw1grw0rb";
  };

  cargoSha256 = "dc22aal3i7zbyxr2c41fimfx13fwp9anmhh641951yd7cqb8xij2";

  buildInputs = lib.optional stdenv.isDarwin Security;


  # Test checks against machine code output, which fails with some
  # LLVM/compiler versions.
  doCheck = false;

  meta = with lib; {
    description = "A cargo subcommand that displays the Assembly, LLVM-IR, MIR and WASM generated for Rust source code";
    homepage = "https://github.com/pacak/cargo-show-asm";
    license = with lib.licenses; [mit apache];
    maintainers = with maintainers; [ DieracDelta ];
  };
}

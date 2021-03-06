{ lib, stdenv, fetchPypi, python, buildPythonPackage, pycairo, backports_functools_lru_cache
, which, cycler, dateutil, nose, numpy, pyparsing, sphinx, tornado, kiwisolver
, freetype, libpng, pkgconfig, mock, pytz, pygobject3, gobject-introspection, functools32, subprocess32
, fetchpatch
, enableGhostscript ? false, ghostscript ? null, gtk3
, enableGtk3 ? false, cairo
# darwin has its own "MacOSX" backend
, enableTk ? !stdenv.isDarwin, tcl ? null, tk ? null, tkinter ? null, libX11 ? null
, enableQt ? false, pyqt4
, Cocoa
, pythonOlder
}:

assert enableGhostscript -> ghostscript != null;
assert enableTk -> (tcl != null)
                && (tk != null)
                && (tkinter != null)
                && (libX11 != null)
                ;
assert enableQt -> pyqt4 != null;

buildPythonPackage rec {
  version = "2.2.3";
  pname = "matplotlib";

  src = fetchPypi {
    inherit pname version;
    sha256 = "7355bf757ecacd5f0ac9dd9523c8e1a1103faadf8d33c22664178e17533f8ce5";
  };

  patches = [
    # https://github.com/matplotlib/matplotlib/pull/12478
    (fetchpatch {
      name = "numpy-1.16-compat.patch";
      url = "https://github.com/matplotlib/matplotlib/commit/2980184d092382a40ab21f95b79582ffae6e19d6.patch";
      sha256 = "1c0wj28zy8s5h6qiavx9zzbhlmhjwpzbc3fyyw9039mbnqk0spg2";
    })
  ];

  XDG_RUNTIME_DIR = "/tmp";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [ which sphinx ]
    ++ stdenv.lib.optional enableGhostscript ghostscript
    ++ stdenv.lib.optional stdenv.isDarwin [ Cocoa ];

  propagatedBuildInputs =
    [ cycler dateutil nose numpy pyparsing tornado freetype kiwisolver
      libpng mock pytz ]
    ++ stdenv.lib.optional (pythonOlder "3.3") backports_functools_lru_cache
    ++ stdenv.lib.optionals enableGtk3 [ cairo pycairo gtk3 gobject-introspection pygobject3 ]
    ++ stdenv.lib.optionals enableTk [ tcl tk tkinter libX11 ]
    ++ stdenv.lib.optionals enableQt [ pyqt4 ]
    ++ stdenv.lib.optionals python.isPy2 [ functools32 subprocess32 ];

  setup_cfg = ./setup.cfg;
  preBuild = ''
    cp "$setup_cfg" ./setup.cfg
  '';

  # Matplotlib tries to find Tcl/Tk by opening a Tk window and asking the
  # corresponding interpreter object for its library paths. This fails if
  # `$DISPLAY` is not set. The fallback option assumes that Tcl/Tk are both
  # installed under the same path which is not true in Nix.
  # With the following patch we just hard-code these paths into the install
  # script.
  postPatch =
    let
      inherit (stdenv.lib.strings) substring;
      tcl_tk_cache = ''"${tk}/lib", "${tcl}/lib", "${substring 0 3 tk.version}"'';
    in
    stdenv.lib.optionalString enableTk
      "sed -i '/self.tcl_tk_cache = None/s|None|${tcl_tk_cache}|' setupext.py";

  # Matplotlib needs to be built against a specific version of freetype in
  # order for all of the tests to pass.
  doCheck = false;

  meta = with lib; {
    description = "Python plotting library, making publication quality plots";
    homepage    = "https://matplotlib.org/";
    maintainers = with maintainers; [ lovek323 veprbl ];
  };

}

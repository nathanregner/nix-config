# disable xvfb-run tests to fix build on darwin
_prev: pkg:
(pkg.overridePythonAttrs (_oldAttrs: {
  nativeCheckInputs = [ ];
})).overrideAttrs
  (_oldAttrs: {
    doInstallCheck = false;
  })

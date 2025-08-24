polkit.addRule(function (action, subject) {
  polkit.log("action.id: " + action.id);
  if (
    (action.id == "org.freedesktop.resolve1.set-dns-servers" ||
      action.id == "org.freedesktop.resolve1.set-domains") &&
    subject.user == "nregner"
  ) {
    return polkit.Result.YES;
  }
});

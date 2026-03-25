(function attachEmailValidator(globalScope) {
  const localPartPattern = /^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+$/;
  const domainLabelPattern = /^[A-Za-z0-9-]+$/;
  const tldPattern = /^[A-Za-z]{2,63}$/;

  function isValidEmail(value) {
    const email = String(value || "").trim().toLowerCase();

    if (!email || email.length > 254 || email.includes(" ")) {
      return false;
    }

    const parts = email.split("@");
    if (parts.length !== 2) {
      return false;
    }

    const localPart = parts[0];
    const domain = parts[1];

    if (
      !localPart ||
      !domain ||
      localPart.length > 64 ||
      localPart.startsWith(".") ||
      localPart.endsWith(".") ||
      localPart.includes("..") ||
      !localPartPattern.test(localPart)
    ) {
      return false;
    }

    if (
      domain.startsWith(".") ||
      domain.endsWith(".") ||
      domain.includes("..")
    ) {
      return false;
    }

    const labels = domain.split(".");
    if (labels.length < 2) {
      return false;
    }

    for (const label of labels) {
      if (
        !label ||
        label.length > 63 ||
        label.startsWith("-") ||
        label.endsWith("-") ||
        !domainLabelPattern.test(label)
      ) {
        return false;
      }
    }

    return tldPattern.test(labels[labels.length - 1]);
  }

  globalScope.isValidEmail = isValidEmail;
})(window);

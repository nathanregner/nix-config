(() => {
  const userCode = document.querySelector("#user-code")?.innerText;
  if (userCode) {
    const searchParams = new URLSearchParams(window.location.search);
    if (userCode === searchParams.get("user_code")) {
      document.querySelector("#cli_verification_btn").click();
    }
    return;
  }

  let clicked = false;
  function clickAllow() {
    const button = document.querySelector(
      'button[data-testid="allow-access-button"]',
    );
    if (button) {
      clicked = true;
      button.click();
    }
  }

  clickAllow();

  var observer = new MutationObserver(clickAllow);
  observer.observe(document, { childList: true, subtree: true });
})();

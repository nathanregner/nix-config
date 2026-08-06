(() => {
  const ACCOUNT = "ClickBank Production";
  const ROLE = "DbReadOnly"; // "DB Read Only"

  // The Account/Role fields are AWS Cloudscape (awsui) <Select> widgets: a
  // trigger <button aria-haspopup="listbox"> that opens a listbox of
  // role="option" items in a portal. Cloudscape ignores a synthetic
  // element.click(), so realClick() dispatches the full pointer/mouse chain.
  const realClick = (el) => {
    el.scrollIntoView({ block: "center" });
    const opts = { bubbles: true, cancelable: true, view: window };
    el.dispatchEvent(new PointerEvent("pointerdown", { ...opts, pointerId: 1 }));
    el.dispatchEvent(new MouseEvent("mousedown", opts));
    el.dispatchEvent(new PointerEvent("pointerup", { ...opts, pointerId: 1 }));
    el.dispatchEvent(new MouseEvent("mouseup", opts));
    el.dispatchEvent(new MouseEvent("click", opts));
  };

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  const waitFor = async (fn, { timeout = 10000, interval = 50 } = {}) => {
    const end = Date.now() + timeout;
    for (;;) {
      const v = fn();
      if (v) return v;
      if (Date.now() > end) throw new Error("waitFor: timed out");
      await sleep(interval);
    }
  };

  // The label text lives in a separate FormField element, not inside the
  // trigger button, so find the label leaf then walk up to the nearby trigger.
  const findTriggerByField = (label) => {
    const field = [...document.querySelectorAll("*")].find(
      (el) =>
        el.children.length === 0 &&
        el.textContent.trim().toLowerCase() === label.toLowerCase(),
    );
    if (!field) return null;
    let scope = field.closest("div");
    for (let i = 0; i < 6 && scope; i++) {
      const btn = scope.querySelector('button[aria-haspopup="listbox"]');
      if (btn) return btn;
      scope = scope.parentElement;
    }
    return null;
  };

  const openSelect = async (label) => {
    const trigger = await waitFor(() => findTriggerByField(label));
    realClick(trigger);
    return waitFor(() =>
      [...document.querySelectorAll('[role="listbox"]')].find(
        (l) => l.offsetParent !== null && l.querySelector('[role="option"]'),
      ),
    );
  };

  const pickOption = async (listbox, text) => {
    const option = await waitFor(() =>
      [...listbox.querySelectorAll('[role="option"]')].find((o) =>
        o.textContent.toLowerCase().includes(text.toLowerCase()),
      ),
    );
    realClick(option);
    // Close the popover so the next trigger isn't intercepted.
    document.body.dispatchEvent(
      new KeyboardEvent("keydown", { key: "Escape", bubbles: true }),
    );
    await sleep(300);
  };

  const alreadySelected = () => {
    const triggers = [
      ...document.querySelectorAll('button[aria-haspopup="listbox"]'),
    ].map((b) => b.textContent.trim());
    return (
      triggers.some((t) => t.includes(ACCOUNT)) &&
      triggers.some((t) => t.includes(ROLE))
    );
  };

  let ran = false;
  async function autoSelect() {
    if (ran || alreadySelected()) return;
    // Only start once both selects are present.
    if (!findTriggerByField("Account") || !findTriggerByField("Role")) return;
    ran = true;
    try {
      const acctBox = await openSelect("Account");
      await pickOption(acctBox, ACCOUNT);
      const roleBox = await openSelect("Role");
      await pickOption(roleBox, ROLE);
    } catch (err) {
      ran = false; // allow a retry if the form re-rendered mid-run
      console.error("TEAM auto-select failed:", err);
    }
  }

  autoSelect();

  const observer = new MutationObserver(autoSelect);
  observer.observe(document, { childList: true, subtree: true });
})();

// Signum: mejlknappen kopierar adressen i stället för att öppna ett mejlprogram.
// Går kopieringen inte (gammal webbläsare, osäker sida) öppnas mailto som reserv.
for (const button of document.querySelectorAll('.signum-link[data-signum="mail"]')) {
  let timer;
  button.addEventListener("click", async () => {
    const email = `${button.dataset.user}@${button.dataset.domain}`;
    try {
      await navigator.clipboard.writeText(email);
    } catch {
      location.href = `mailto:${email}`;
      return;
    }
    const tip = button.dataset.tipDefault ?? (button.dataset.tipDefault = button.dataset.tip);
    const status = button.closest(".signum")?.querySelector(".signum-status");
    button.dataset.tip = button.dataset.tipCopied ?? "Kopierad!";
    button.dataset.copied = "";
    if (status) status.textContent = `${email} är kopierad`;
    clearTimeout(timer);
    timer = setTimeout(() => {
      button.dataset.tip = tip;
      delete button.dataset.copied;
      if (status) status.textContent = "";
    }, 2000);
  });
}

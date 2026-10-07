"use client";

// Signum (React/Next). Samma markup och klasser som signum.html, så signum.css
// styr utseendet: lägg filen i projektet och importera den globalt.
// Ingen tooltip-komponent från ui-biblioteket: CSS-tooltipen gör att det ser
// likadant ut på sajter utan React.
import { useRef, useState } from "react";

const USER = "e.ehnsio";
const DOMAIN = "gmail.com";

const svg = {
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 2,
  strokeLinecap: "round",
  strokeLinejoin: "round",
  "aria-hidden": true,
} as const;

export function Signum() {
  const [copied, setCopied] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout>>(undefined);

  const copyEmail = async () => {
    const email = `${USER}@${DOMAIN}`;
    try {
      await navigator.clipboard.writeText(email);
    } catch {
      location.href = `mailto:${email}`;
      return;
    }
    setCopied(true);
    clearTimeout(timer.current);
    timer.current = setTimeout(() => setCopied(false), 2000);
  };

  return (
    <nav className="signum" aria-label="Kontakt">
      <button
        type="button"
        className="signum-link"
        data-signum="mail"
        data-tip={copied ? "Kopierad!" : "Kopiera e-post"}
        data-copied={copied ? "" : undefined}
        aria-label="Kopiera e-postadress"
        onClick={copyEmail}
      >
        <svg className="signum-mail" {...svg}>
          <path d="m22 7-8.991 5.727a2 2 0 0 1-2.009 0L2 7" />
          <rect x="2" y="4" width="20" height="16" rx="2" />
        </svg>
        <svg className="signum-check" {...svg}>
          <path d="M20 6 9 17l-5-5" />
        </svg>
      </button>
      <a
        className="signum-link"
        data-signum="github"
        href="https://github.com/eehnsio"
        target="_blank"
        rel="noopener noreferrer"
        data-tip="GitHub"
        aria-label="Erik på GitHub"
      >
        <svg {...svg}>
          <path d="M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.403 5.403 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4" />
          <path d="M9 18c-4.51 2-5-2-7-2" />
        </svg>
      </a>
      <a
        className="signum-link"
        data-signum="coffee"
        href="https://buymeacoffee.com/eehnsio"
        target="_blank"
        rel="noopener noreferrer"
        data-tip="Köp mig en kaffe"
        aria-label="Köp mig en kaffe"
      >
        <svg {...svg}>
          <path d="M10 2v2" />
          <path d="M14 2v2" />
          <path d="M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1" />
          <path d="M6 2v2" />
        </svg>
      </a>
      <span className="signum-status" role="status">
        {copied ? `${USER}@${DOMAIN} är kopierad` : ""}
      </span>
    </nav>
  );
}

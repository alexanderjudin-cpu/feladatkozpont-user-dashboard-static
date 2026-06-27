/* ============================================================================
 *  HD Direkt — Feladatközpont · Gmail összekötés adapter
 * ----------------------------------------------------------------------------
 *  CÉL: email érkezik → kártya születik. A "milyen email → milyen kártya"
 *  szabályokat a UI-ban (Automatizmusok nézet) állítod be intuitívan, ez a
 *  fájl csak a BEÉRKEZÉST köti be. A szabály-kiértékelés az appban fut.
 *
 *  Ajánlott bekötés (egyik):
 *   A) Gmail → Google Apps Script trigger → POST Supabase Edge Function →
 *      insert task_center.task_cards (RLS/jogosultság a DB-ben). [legbiztonságosabb]
 *   B) Gmail → Pub/Sub watch → Cloud Function → Supabase.
 *   C) Gmail → n8n/Make → webhook → ez a frontend (postMessage) vagy Supabase.
 *
 *  Az app az alábbi eseményre figyel és lefuttatja a szabályokat:
 *     window.postMessage({ type:'task_center_incoming_email', payload:{ email } }, '*')
 *  vagy ha endpoint van megadva, innen pollozható a friss, még fel nem dolgozott email.
 *
 *  Normalizált email alak (erre illeszkednek a szabályok):
 *   { id, from, fromName, to, subject, snippet, body, labels:[], hasAttachment, receivedAt }
 * ========================================================================== */

window.TASK_CENTER_GMAIL_CONFIG = {
  mode: "none",          // 'none' | 'appsscript' | 'pubsub' | 'n8n'
  pollEndpoint: "",      // opcionális: GET → { emails:[normalizedEmail,...] }
  authHeader: "",
  account: ""            // megjelenítendő fiók, pl. "feladat@hddirekt.com"
};

(function () {
  const cfg = window.TASK_CENTER_GMAIL_CONFIG;

  function normalize(raw) {
    return {
      id: raw.id || ("mail-" + Date.now()),
      from: raw.from || raw.From || "",
      fromName: raw.fromName || (raw.from ? raw.from.split("<")[0].trim() : ""),
      to: raw.to || raw.To || "",
      subject: raw.subject || raw.Subject || "",
      snippet: raw.snippet || (raw.body || "").slice(0, 160),
      body: raw.body || raw.Body || "",
      labels: raw.labels || [],
      hasAttachment: !!raw.hasAttachment,
      receivedAt: raw.receivedAt || new Date().toISOString()
    };
  }

  window.TaskCenterGmail = {
    config: cfg,
    connected() { return cfg.mode !== "none" && (!!cfg.pollEndpoint || cfg.mode === "appsscript" || cfg.mode === "pubsub" || cfg.mode === "n8n"); },
    status() { return cfg.mode === "none" ? "Nincs összekötve" : ("Összekötve · " + cfg.mode + (cfg.account ? " · " + cfg.account : "")); },
    normalize,
    // n8n/webhook → frontend: hívd ezt, vagy küldj postMessage-t a fenti típussal
    feed(rawEmail) { window.postMessage({ type: "task_center_incoming_email", payload: { email: normalize(rawEmail) } }, "*"); },
    async poll() {
      if (!cfg.pollEndpoint) return [];
      const res = await fetch(cfg.pollEndpoint, { headers: cfg.authHeader ? { Authorization: cfg.authHeader } : {} });
      if (!res.ok) throw new Error("gmail poll " + res.status);
      const data = await res.json();
      return (data.emails || []).map(normalize);
    }
  };
})();

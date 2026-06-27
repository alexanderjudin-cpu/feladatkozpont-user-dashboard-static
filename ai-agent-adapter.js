/* ============================================================================
 *  HD Direkt — Feladatközpont · AI Agent adapter
 * ----------------------------------------------------------------------------
 *  Az AI agent: olvashat source contextet, javasolhat checklistet/summary-t,
 *  előkészíthet actiont — de ÉLES üzleti rekordot nem ír jóváhagyás nélkül.
 *  (lásd SECURITY_AND_PERMISSIONS.md). A javaslatot a user "Alkalmaz"-zal hagyja jóvá.
 *
 *  Bekötési sorrend (amelyik elérhető):
 *   1) endpoint  → POST a saját agentedhez (Supabase Edge Function / n8n / Retool webhook)
 *   2) window.claude.complete → beépített Claude (prototípus/demo)
 *   3) lokális sablon → offline fallback
 * ========================================================================== */

window.TASK_CENTER_AGENT_CONFIG = {
  agentKey: "task_assistant",
  endpoint: "",          // pl. "https://xxxx.functions.supabase.co/agent-run"  (üres = nincs)
  authHeader: ""         // pl. "Bearer ..."  (csak ha az endpoint kéri)
};

(function () {
  const cfg = window.TASK_CENTER_AGENT_CONFIG;

  async function viaEndpoint(card, jobType) {
    const res = await fetch(cfg.endpoint, {
      method: "POST",
      headers: Object.assign({ "Content-Type": "application/json" }, cfg.authHeader ? { Authorization: cfg.authHeader } : {}),
      body: JSON.stringify({ agent_key: cfg.agentKey, job_type: jobType, card })
    });
    if (!res.ok) throw new Error("agent endpoint " + res.status);
    return await res.json(); // várt: { summary, checklist:[{text}], confidence }
  }

  async function viaClaude(card, jobType) {
    const prompt = [
      "Te egy belső feladatkezelő AI agent vagy egy magyar vállalatnál.",
      "Egy feladatkártyához kell rövid, gyakorlati előkészítést adnod.",
      "Feladat címe: " + (card.title || ""),
      "Leírás: " + (card.description || "—"),
      "Modul: " + (card.module_label || card.module_key || "—") + ", prioritás: " + (card.priority || "normal") + ".",
      "Adj vissza KIZÁRÓLAG JSON-t, semmi mást, ebben a formában:",
      '{"summary":"egy mondatos összefoglaló magyarul","checklist":["lépés 1","lépés 2","lépés 3"],"confidence":0.0-1.0}'
    ].join("\n");
    const raw = await window.claude.complete(prompt);
    const m = raw.match(/\{[\s\S]*\}/);
    const obj = JSON.parse(m ? m[0] : raw);
    return { summary: obj.summary, checklist: (obj.checklist || []).map(t => ({ text: typeof t === "string" ? t : t.text })), confidence: obj.confidence ?? 0.8 };
  }

  function viaLocal(card) {
    const t = (card.title || "feladat").toLowerCase();
    let steps = ["Forrásrekord ellenőrzése", "Hiányzó adatok azonosítása", "Felelős egyeztetése", "Dokumentálás és lezárás"];
    if (t.includes("jóváhagy")) steps = ["Adatok ellenőrzése", "Eltérések jelölése", "Jóváhagyó értesítése", "Döntés rögzítése"];
    if (t.includes("dokument") || t.includes("útlevél") || t.includes("hiány")) steps = ["Hiányzó dokumentum beazonosítása", "Bekérő üzenet előkészítése", "Határidő beállítása", "Beérkezés ellenőrzése"];
    if (t.includes("szállás") || t.includes("cím")) steps = ["Cím/partner adat ellenőrzése", "Ár és kapacitás egyeztetés", "Foglalás rögzítése", "Visszaigazolás"];
    return { summary: "Javasolt előkészítés a(z) „" + (card.title || "feladat") + "” feladathoz.", checklist: steps.map(text => ({ text })), confidence: 0.6 };
  }

  window.TaskCenterAgent = {
    agentKey: cfg.agentKey,
    available() { return !!cfg.endpoint || (typeof window.claude !== "undefined") || true; },
    source() { return cfg.endpoint ? "endpoint" : (typeof window.claude !== "undefined" ? "claude" : "local"); },
    async run(card, jobType) {
      jobType = jobType || "prepare_checklist";
      try { if (cfg.endpoint) return await viaEndpoint(card, jobType); } catch (e) { console.warn("agent endpoint failed:", e.message); }
      try { if (typeof window.claude !== "undefined") return await viaClaude(card, jobType); } catch (e) { console.warn("claude agent failed:", e.message); }
      return viaLocal(card);
    }
  };
})();

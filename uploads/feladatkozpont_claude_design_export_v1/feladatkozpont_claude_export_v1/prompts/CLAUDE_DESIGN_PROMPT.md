# Claude Design prompt — Feladatközpont User Dashboard

Dolgozz senior product designer + senior frontend architectként.

Egy különálló, linkkel elérhető, Trello-szerű Feladatközpont / User Dashboard appot kell továbbtervezned és frontend szinten javítanod.

## Kontextus

Ez nem IT dashboard, nem UAHUN modul, nem szállás modul. Ez az alap user nézet minden belső modul fölött.

Ide később Supabase-ből érkeznek majd task cardok:

- új case / ügy
- hiányzó adat
- jóváhagyásra váró rekord
- lejárat / SLA
- dokumentum hiány
- partner visszajelzés
- agent / AI által generált teendő
- automata kontroll találat

## Design cél

Legyen luxi, gyors, profi, Trello/Monday/Jira minőségű. Light enterprise UI, fehér/világosszürke/narancs színvilággal. Ne legyen gamer, ne legyen túl sötét, ne legyen sima Retool table.

## Kötelező UX

- Minden, ami gombnak/tabnak/kártyának néz ki, legyen kattintható.
- Top navigáció tabok: Saját nézet, Csapat, Minden jogosult, Naptár, Automatizmusok, Beállítások.
- Board: Új, Folyamatban, Jóváhagyásra vár, AI előkészítés, Kész.
- Drag & drop.
- Jobb oldali részletező panel.
- Kártya szerkesztő modal.
- Checklist.
- Komment és activity kártyaszinten megengedett, de külön üzenet/chat ikon nem kell.
- Értesítés ikon maradhat task notification célra.
- Jobb felső monogram-stack mutassa a board tagokat, mint Trellóban.
- Monogramokra kattintva nyíljon board members drawer.
- Board members drawerben user szűrés legyen.
- AI / agent panel és gombok maradjanak, de kontrollált, auditálható műveletekként.

## Backend contract

A frontend task cardokat kap, nem konkrét üzleti táblákat. Minden card mögött generikus source van:

- source_module
- source_type
- source_id
- source_payload

A Supabase schema és JSON contractok a csomagban vannak.

## Fejlesztési elv

- Legyen standalone, gyors, könnyen hostolható.
- Első körben vanilla HTML/JS/CSS is oké, később React/Vite-re át lehet írni.
- A design legyen komponens-gondolkodású.
- A Supabase/RLS/Realtime bekötésre készüljön fel.
- postMessage bridge maradjon kompatibilis Retool vagy más parent app felé.

## Amit kérünk tőled

1. Nézd át a meglévő HTML snapshotot és a contractokat.
2. Tervezz modernebb, egységesebb UI-t.
3. Tisztítsd a komponensstruktúrát.
4. Adj javaslatot React/Vite migrációra is, ha szükséges.
5. Tartsd meg a narancs-fehér enterprise irányt.
6. Ne tegyél bele IT-specifikus tartalmat.
7. Ne töröld az AI/agent, user presence és Supabase live bekötési pontokat.

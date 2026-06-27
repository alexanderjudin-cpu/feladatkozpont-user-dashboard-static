# Projekt brief — Feladatközpont / User Dashboard

## Mi ez?

A Feladatközpont egy különálló, linkkel elérhető, Trello-szerű alap user dashboard.
Ez lesz a központi felhasználói munkafelület, ahol a user látja a saját, csapat vagy jogosultság alapján elérhető teendőit.

## Mit NEM jelent?

- Nem IT dashboard.
- Nem UAHUN modul.
- Nem szállás modul.
- Nem a meglévő Retool appba beépített tab.
- Nem egy statikus látványterv.

## Mit jelent?

Egy külön app / külön dashboard, amelyre később minden modulból lehet task cardot küldeni:

- új ügy/case létrejött
- hiányzó adat
- jóváhagyásra váró rekord
- lejárat / SLA / határidő
- dokumentum hiány
- partner visszajelzés
- AI agent által generált következő lépés
- automata kontroll találat

## Technológiai döntés

Frontend: standalone HTML/JS/CSS vagy később React/Vite.
Hosting: GitHub Pages jelenleg, később Cloudflare Pages is jó.
Backend: Supabase PostgreSQL + Realtime + RPC + RLS.
Retool: csak hivatkozás, wrapper, vagy bridge. Ne legyen a fő appba beégetve.

## Célélmény

A user belép és azonnal látja:

- mi az új dolga
- mi van folyamatban
- mi vár jóváhagyásra
- mit készít elő AI/agent
- mi van kész
- melyik userhez tartozik mi
- mi sürgős
- honnan jött a feladat
- mit lehet vele csinálni egy kattintással

## Fő UI zónák

1. Felső header
   - kereső
   - szűrők
   - új feladat
   - értesítések
   - AI gyorsnézet
   - board members monogram stack

2. Fő navigáció
   - Saját nézet
   - Csapat
   - Minden jogosult
   - Naptár
   - Automatizmusok
   - Beállítások

3. KPI sor
   - Nyitott
   - Folyamatban
   - Kritikus
   - AI javaslat

4. Kanban board
   - Új
   - Folyamatban
   - Jóváhagyásra vár
   - AI előkészítés
   - Kész

5. Jobb oldali detail panel
   - részletek
   - checklist
   - kommentek
   - activity
   - AI / Agent

6. Drawerek
   - szűrők
   - értesítések
   - board tagok / user lista


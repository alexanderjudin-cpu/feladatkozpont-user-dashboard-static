# UI / UX követelmények

## Stílus

- Light enterprise SaaS UI.
- Fehér / világosszürke / narancs akcentus.
- Ne legyen sötét gamer app.
- Ne legyen túl Retool-táblázatos.
- Legyen Trello/Monday/Jira szintű interaktív dashboard érzése.
- Profi, gyors, sima, modern, de vállalati belső rendszerbe illő.

## Színek

- Primary accent: #f8991c / #ffb24a
- Background: #f5f6f8
- Surface: #ffffff
- Line: #e3e5ea
- Text: #17181c
- Muted: #6d717a
- Status colors:
  - critical: red
  - high: yellow/orange
  - normal: green/blue
  - AI: purple

## Interakciók

Minden kattintható, ami vizuálisan kattinthatónak tűnik.

Kötelező interakciók:

- fő tabok váltása
- kártya kiválasztása
- kártya drag & drop oszlopok között
- kártya duplakatt szerkesztés
- kártya hárompontos menü
- oszlop hárompontos menü
- új feladat modal
- gyors keresés
- szűrő drawer
- user monogram stack / board member drawer
- userre szűrés
- jobb panel tabjai
- checklist módosítás
- komment írás
- AI előkészítés gomb
- forrásrekord megnyitás gomb
- bulk kijelölés / bulk státuszváltás
- lista / board nézet váltás

## Top user presence rész

A jobb felső monogram stack nem dekoráció.
Ez a boardhoz / user dashboardhoz jogosult embereket mutatja:

- monogram
- opcionális avatar
- online/offline állapot
- +N ha több user van
- kattintásra drawer
- drawerben lista: név, role, státusz, szűrés gomb
- később Supabase `task_center.board_members` vagy `public.profiles` adja az adatot

Üzenetek / chat ikon egyelőre nem kell.
Értesítés maradhat, mert task notification később lesz.

## Teljesítmény

- 1000 kártyáig legyen gyors.
- A boardon egyszerre csak a szükséges DOM legyen aktív.
- Később virtualizáció javasolt.
- Drag & drop ne akadozzon.
- Backend frissítés legyen optimistic UI.

## Mobil / tablet

Első körben desktop-first.
Később tablet támogatás:
- oszlopok horizontális scrollban
- detail panel drawerként
- topbar kompaktabb


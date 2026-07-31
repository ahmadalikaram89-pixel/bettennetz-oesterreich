# TODO — BettenNetz Österreich

## Erledigt
- Erster Prototyp (Karte, Dashboard, Login-Mock) ins Repo übernommen
- GitHub Pages aktiviert: https://ahmadalikaram89-pixel.github.io/bettennetz-oesterreich/
- UX-Fixes: Theme-Umschalter entfernt (nur Light-Mode), Fachrichtungen-Speichern zeigt jetzt eine Bestätigung, OP-Kapazität-Eingaben korrigieren sich sichtbar bei ungültigen Werten
- Karte + Dashboard responsive für Mobile (Sidebar stapelt sich, Detailpanel als Bottom Sheet, Tabellen scrollen horizontal statt das Layout zu sprengen)
- Supabase-Anbindung für `transfers` vorbereitet (`supabase/schema.sql`, Realtime-Subscription im Code) — läuft aktuell im lokalen Fallback-Modus, da noch kein Supabase-Projekt verbunden ist

## Offen
- [ ] Supabase-Projekt anlegen/verbinden (Projekt-URL + anon key in `index.html` eintragen), `supabase/schema.sql` ausführen
- [ ] Transfer-Sync zwischen mehreren Krankenhäusern/Sessions live testen, sobald Supabase verbunden ist
- [ ] Echtes Login/Auth statt der client-seitigen Demo-Zugänge (aktuell Passwörter im Klartext im JS)
- [ ] Supabase RLS-Policies verschärfen, sobald echtes Auth existiert (aktuell offener Lese-/Schreibzugriff für den anon key)
- [ ] Weitere UX-Politur nach Bedarf (Login-Screen auf sehr schmalen Displays, Ladezustände, Fehlermeldungen in der UI)

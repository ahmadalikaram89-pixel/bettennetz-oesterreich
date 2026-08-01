# TODO — BettenNetz Österreich

## Erledigt
- Erster Prototyp (Karte, Dashboard, Login-Mock) ins Repo übernommen
- GitHub Pages aktiviert: https://ahmadalikaram89-pixel.github.io/bettennetz-oesterreich/
- UX-Fixes: Theme-Umschalter entfernt (nur Light-Mode), Fachrichtungen-Speichern zeigt jetzt eine Bestätigung, OP-Kapazität-Eingaben korrigieren sich sichtbar bei ungültigen Werten
- Karte + Dashboard responsive für Mobile (Sidebar stapelt sich, Detailpanel als Bottom Sheet, Tabellen scrollen horizontal statt das Layout zu sprengen)
- Supabase-Anbindung für `transfers` vorbereitet (`supabase/schema.sql`, Realtime-Subscription im Code) — läuft aktuell im lokalen Fallback-Modus, da noch kein Supabase-Projekt verbunden ist
- UX-Politur: Modal schließt per Klick auf den Hintergrund oder Escape, das mobile Bottom-Sheet hat jetzt ein abgedunkeltes Overlay (schließt genauso), "Anfrage senden" zeigt einen Ladezustand statt starr zu wirken
- Zwei weitere kleine Fixes: Enter im Benutzername-Feld loggt jetzt auch ein, Suchfeld hat einen ×-Button zum Löschen
- Anfragen sind jetzt an ein Ziel-Krankenhaus geroutet (`to_hospital`) statt ein globaler Posteingang für alle zu sein; "Eingehend" zeigt nur an uns gerichtete Anfragen
- Bestätigte Reservierung: Annahme einer Anfrage reduziert sofort die passende OP-Kapazität ("Frei heute") des annehmenden Krankenhauses, um Doppelbuchungen zu vermeiden — und die Anfrage-ID wird im neuen "Gesendet"-Tab als Code fürs Patienten-Handover angezeigt
- OP-Kapazität-Kategorien sind jetzt erweiterbar: Krankenhäuser können per "+ Kategorie hinzufügen" eigene Kategorien (z. B. Geburtshilfe / Entbindung) aus den noch nicht belegten Fachrichtungen ergänzen, statt auf die 4 festen Kategorien beschränkt zu sein
- Echtes Logo eingebaut (`assets/logo.png`, freigestellt/rund zugeschnitten) — ersetzt das 🏥-Emoji in Login-Screen, Topbar und Favicon
- Deployment jetzt auch über Vercel verfügbar (https://bettennetz-oesterreich.vercel.app/), zusätzlich zu GitHub Pages — beide folgen automatisch jedem Push auf `main`
- Umfassender Codecheck: "Speichern & veröffentlichen" schrieb bisher nirgends in die Kartendaten zurück (Karte/Liste zeigten nie die eigenen Änderungen), Annehmen/Ablehnen einer Anfrage tat im lokalen Fallback-Modus gar nichts (String/Number-Vergleich der IDs), manuelle OP-Kapazität-Eingaben gingen beim Hinzufügen einer neuen Kategorie stillschweigend verloren, die Kapazitätsbalken in der Krankenhaus-Liste zeigten feste Fake-Prozente statt echter Werte — alle vier behoben und mit Playwright nachgetestet
- XSS-Härtung: Anfragedaten werden jetzt escaped bevor sie ins DOM geschrieben werden, `supabase/schema.sql` hat jetzt CHECK-Constraints auf `fach`/`prio`/Namenslängen
- Echtes Login/Auth vorbereitet: `index.html` nutzt jetzt Supabase Auth (`signInWithPassword`) sobald `SUPABASE_CONFIGURED` ist, mit `hospital_profiles`-Tabelle statt der Klartext-Passwörter; `supabase/schema.sql` hat dafür verschärfte RLS-Policies (jedes Krankenhaus sieht/verwaltet nur eigene Anfragen, GÖG sieht alles, Status-Updates sind auf die annehmende Klinik + die Spalte `status` beschränkt). Der lokale Demo-Fallback (ACCS, Klartext-Passwörter) bleibt aktiv bis ein echtes Supabase-Projekt verbunden ist — siehe „Offen" unten

## Offen
- [ ] Supabase-Projekt anlegen, `supabase/schema.sql` ausführen (Reihenfolge steht im Dateikopf)
- [ ] Pro Krankenhaus einen echten Supabase-Auth-User anlegen (`<username>@bettennetz.local` + echtes Passwort) und per `hospital_profiles`-Insert verknüpfen — danach die alten Demo-Passwörter aus `ACCS` in `index.html` entfernen
- [ ] Projekt-URL + anon key in `index.html` eintragen (`SUPABASE_URL`/`SUPABASE_ANON_KEY`)
- [ ] Transfer-Sync (inkl. Reservierungs-Sperre) zwischen mehreren Krankenhäusern/Sessions live testen, sobald Supabase verbunden ist
- [ ] Weitere UX-Politur nach Bedarf (Login-Screen auf sehr schmalen Displays, Fehlermeldungen in der UI)

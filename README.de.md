# EasyPocket

**Version:** 0.5.1-octowow-alpha · **Autor:** edwinvancleef577

[English](README.md) | Deutsch

Mehrere Zaubertaschen pro Charakter für **OctoWoW / Vanilla-API, Interface 11200, Lua 5.0**. Keine Abhängigkeit von DragonForgeUI, pfUI, ClassicAPI oder SuperWoW.

## Installation

### OctoWoW Launcher

Diese Git-Adresse in der Addon-Verwaltung hinzufügen:

`https://github.com/edwinvancleef577/EasyPocket.git`

Die Addon-Dateien und `EasyPocket.toc` liegen direkt im Repository-Hauptverzeichnis.

### Manuelle Installation und Übernahme

1. WoW beenden.
2. Auf GitHub **Code → Download ZIP** wählen und entpacken. Den entpackten Ordner in `EasyPocket` umbenennen und nach `Interface/AddOns` kopieren; eine vorhandene Addon-Version ersetzen. Keine zusätzliche Ordnerebene anlegen.
3. WoW neu starten. `EasyPocket.toc`, `Locale.lua` und `Widgets.lua` müssen direkt im Addon-Ordner liegen.

Vorhandene Taschen, Namen, Icons, Zauber, Leisten-Makros und Positionen werden übernommen. Die bisherigen automatisch berechneten Raster werden einmalig in eine feste Größe mit denselben sichtbaren Zauberpositionen überführt. Danach werden Breite und Höhe ausschließlich im Menü geändert. Keine Dateien im WTF-Ordner löschen.

## Neues Menü

Minimap-Icon oder `/ep` öffnet die Verwaltung. Rahmen, mittiges Titelschild, goldbraune Buttons und Dropdowns verwenden dieselben nativen WoW-Texturen wie die EasyThreat-Menüs.

**Links stehen ausschließlich Taschen-Icons.** Jede Spalte füllt sich von oben bis zum unteren Rand. Erst danach beginnt die nächste Spalte rechts daneben. Das Plus ist immer der letzte Eintrag. Im aktuellen 540 Einheiten hohen Menü passen neun Plätze pro Spalte. Bis zu vier Spalten werden gleichzeitig angezeigt; bei noch mehr Taschen verschiebt das Mausrad den sichtbaren Spaltenbereich.

- **Plus:** neue Tasche anlegen.
- **Taschen-Icon anklicken:** Tasche auswählen und deren Inhaltsfenster öffnen bzw. schließen.
- **Taschen-Icon ziehen:** das zugehörige Makro auf einen Aktionsleistenslot legen.
- **Name rechts:** Enter oder Verlassen des Feldes speichert.
- **Icon wählen:** native WoW-Makro-Icons durchblättern.
- **Tasche löschen:** neben „Icon wählen“; zweiter Klick bestätigt. Entfernt die Tasche und nur ihre eigenen Makros.

Es gibt keine zusätzlichen Buttons zum Öffnen oder Aufnehmen eines Taschen-Icons. Das Menü enthält auch keine Zauberauswahl.

## Einstellungen je Taschenfenster

**Position** als Dropdown:

- **Frei beweglich:** Standard für neue Taschen; neues Fenster zuerst in der Bildschirmmitte. Rand oder leeren Platz ziehen, auf einem Zauber Umschalt-Ziehen verwenden.
- **Fest verankert:** die gewählte Bildschirmposition sperren.
- **Relativ zur Tasche:** dem erkannten Leisten-Icon mit dem gewählten Abstand folgen. Verschieben des Fensters ändert den Abstand. Ohne erkannten Button bleibt zunächst die gespeicherte Bildschirmposition bzw. die Bildschirmmitte erhalten.

**Design** als Dropdown:

- **Aktuell:** der bisherige Tooltip-Rahmen und die bisherigen Quickslot-Buttons.
- **Klassisch:** dunkler WoW-Dialoghintergrund, Metallrahmen und gerahmte Plätze, im klassischen WoW-Stil. Standard für neue Taschen.
- **PFUI-Stil:** flache dunkle Flächen und schmale schwarze Rahmen. Eigenständige Darstellung, keine pfUI-Abhängigkeit.

**Breite** und **Höhe** haben getrennte Dropdowns mit Werten **2 bis 5**. Keine automatische Größenänderung. Das Raster kann komplett gefüllt werden. Beim Verkleinern müssen alle Plätze außerhalb der neuen Grenzen vorher geleert oder nach innen verschoben werden; EasyPocket löscht dafür keine Zauber.

## Freie Platzierung und Drag-and-drop

Zauber direkt aus dem Zauberbuch in eine geöffnete Tasche ziehen. Jeder sichtbare Platz ist einzeln belegbar; Lücken bleiben erhalten. Derselbe Zauber darf an mehreren Stellen vorkommen.

- **Leerer Platz:** genau dort ablegen.
- **Taschenhintergrund:** ersten freien sichtbaren Platz verwenden.
- **Zauber herausziehen:** nach erfolgreicher nativer Aufnahme sofort aus genau diesem Platz entfernen. Keine übrigen Einträge rücken nach.
- **Belegter Zielplatz:** der abgelegte Zauber ersetzt den Inhalt; der bisherige Inhalt hängt anschließend am Mauszeiger und kann anderswo abgelegt werden.
- **Zwischen Taschen ziehen:** verschieben statt kopieren.
- **Herausziehen und verwerfen:** der Quellplatz bleibt leer. Zum Zurücklegen wieder auf den ursprünglichen Platz ablegen.
- **Rechtsklick auf einen Platz:** diesen Eintrag entfernen.
- **Linksklick auf einen Zauber:** wirken; die Tasche bleibt geöffnet.

Die native Aufnahme über `PickupSpell`, `PickupMacro` bzw. `PickupAction` bleibt für die Aktionsleisten zuständig. EasyPocket verwendet ausschließlich die native Cursor-Anzeige, ohne ein zweites Icon darüberzuzeichnen. Makro-Icons unterstützen sowohl die numerische Vanilla-API als auch Clients mit Icon-Dateinamen. Die Icon-Auswahl aktualisiert Menü, Makro und erkannte Leistenbuttons unmittelbar. Ein Drop wird nicht als Zauberklick behandelt.

Das Herausziehen eines Taschen-Icons aus einer Aktionsleiste folgt der normalen WoW-Leistenbedienung. Es entfernt den Shortcut von diesem Slot, **nicht** die gespeicherte Tasche aus der Verwaltung. Die Verwaltungseinträge bleiben verfügbar, bis „Tasche löschen“ verwendet wird.

## Sprache und Fenster-Ebenen

Unten rechts stehen Sprache und Debug. Sprachen: Automatisch nach Spielsprache, Englisch, Deutsch, Französisch, Spanisch, Portugiesisch, Russisch, Koreanisch und vereinfachtes Chinesisch. Die Auswahl gilt pro Charakter und aktualisiert die Bedienoberfläche sofort. Selbst vergebene Taschennamen und die vom Spiel gelieferten Zaubernamen werden dabei nicht übersetzt. Für asiatische bzw. kyrillische Zeichen muss die Spielschrift passende Zeichen enthalten. Technische Debug-Daten und Laufzeitfehlermeldungen können ihre Originalsprache behalten.

Jedes Fenster wird mit allen Kind-Frames gemeinsam angeordnet und in den Vordergrund geholt. Die Icon-Auswahl bleibt über ihrer Verwaltung; Dropdown-Liste und Auswahlzeilen verwenden eine eigene darüberliegende Ebene. Dunkle Flächen sind deckend, damit Inhalte darunter nicht durchscheinen.

## Debug und Kompatibilität

**Debug** zeigt Ladezustand und die letzten zehn abgefangenen EasyPocket-Fehler in einem eigenen Fenster. Text anklicken, Strg+A, Strg+C. Alternativ `/ep debug` oder `/ep status`.

Das Addon verwendet die alten Vanilla-Ereignisparameter und vollständige fünfteilige `SetPoint`-Aufrufe. Geänderte Zauberbuchränge werden neu aufgelöst. Unterstützt werden aktive Spielerzauber, keine Items, Begleiteraktionen oder beliebigen Makros als Tascheninhalt. Eigene Zauberbuch-Addons müssen den nativen `PickupSpell`-Weg verwenden. Eigene Aktionsleisten können über ihre `action`-Slotnummer als Positionsanker erkannt werden.

Für jede Tasche auf einer Aktionsleiste wird ein charakterbezogenes Makro benötigt. Ist das Makrolimit des Clients erreicht, bleibt die Tasche über das Menü nutzbar; fremde Makros werden niemals automatisch gelöscht. Die Makro-Kennung bleibt unabhängig von Listenposition und Namen stabil.

## Prüfstand

**46 Verhaltenstests unter Lua 5.0.3** mit nachgebildeter Vanilla-API bestanden; Syntax aller Lua-Dateien geprüft. Geprüft sind unter anderem Datenmigration, feste Zellpositionen, vollständige Spalten, Dropdowns, Sprachwechsel, Größenänderungen, Drag-and-drop inklusive Cursor-Tausch, Designwechsel, Fenster-Ebenen, Makros und Fehleranzeige.

**Nicht im echten OctoWoW-Client ausgeführt.** Die tatsächliche Darstellung sowie das Zusammenspiel mit der installierten DragonForgeUI-/Benilla-Version benötigen den Praxistest.

Entwicklertest im Addon-Ordner: `lua tests/run_vanilla.lua` mit Lua 5.0.3. Testdateien werden nicht von WoW geladen.

## Lizenz

Siehe [LICENSE](LICENSE). Nutzung, Kopieren, Ändern und Weitergabe sind unter Beibehaltung des Hinweises erlaubt. Die Nutzung mit offiziellen, von Blizzard betriebenen World-of-Warcraft-Diensten ist nicht gestattet; OctoWoW-Nutzung ist willkommen. Eigenständiges Fanprojekt ohne Gewährleistung. Spielgrafiken und Schriften gehören ihren jeweiligen Rechteinhabern.

## Fehler melden

Bitte Version, Client-Version und Schritte zum Nachstellen in einem GitHub-Issue angeben. Debug-Ausgaben vor dem Teilen auf persönliche Angaben prüfen. Keine kompletten WTF-Ordner, SavedVariables oder Kontodaten hochladen.

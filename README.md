# FHV Dashboard

Inoffizielle Flutter-App für Studierende der Fachhochschule Vorarlberg. Bündelt die wichtigsten FHV-Onlinedienste (Stundenplan, Noten, Prüfungstermine, Raumsuche) in einer schnellen, übersichtlichen Oberfläche.

> Diese App steht in keiner Verbindung zur FHV und wird unabhängig entwickelt. Es werden keinerlei Daten serverseitig gespeichert – Zugangsdaten und alle abgerufenen Inhalte verbleiben ausschließlich lokal auf dem Gerät.

## Features

- **Start** – Profilübersicht, nächster anstehender Termin, Studienfortschritt (ECTS) und Schnellzugriff auf FHV-Plattformen (Ilias, Outlook, Inside FHV, ...)
- **Stundenplan** – Listen- und Wochenraster-Ansicht, wochenweise navigierbar
- **Prüfungstermine** – bevorstehende Prüfungen
- **Noten** – Übersicht nach Semester, Notenschnitt & ECTS-Fortschritt, Benachrichtigung bei neuen/geänderten Noten
- **Raumsuche** – freie Räume für einen gewünschten Zeitraum finden oder den Belegungsplan eines bestimmten Raums einsehen
- **Anpassbares Dashboard** – Start-Karten nach Wunsch ein-/ausblenden
- **Offline-freundlich** – Noten, Stundenplan und nächster Termin werden lokal zwischengespeichert, beim Start sofort angezeigt und im Hintergrund aktualisiert

## Technisch

- Flutter, unterstützt Android, iOS (nicht getestet)
- Ruft FHV-interne Webseiten (a5.fhv.at) über eine authentifizierte Session ab und parst die Inhalte clientseitig

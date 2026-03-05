-- =============================================================================
-- Buchtausch-App: Datenbankimplementierung (Phase 2)
-- Kurs: Data-Mart-Erstellung in SQL (DLBDSPBDM01_D)
-- =============================================================================
-- MySQL 9.x: verleiher_id != entleiher_id per Trigger (CHECK auf FK-Spalten nicht erlaubt).
-- =============================================================================

-- Datenbank neu anlegen (Skript vollständig ausführbar)
DROP DATABASE IF EXISTS buchtausch_app;

-- -----------------------------------------------------------------------------
-- Datenbank anlegen und auswählen
-- -----------------------------------------------------------------------------
CREATE DATABASE buchtausch_app
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE buchtausch_app;

-- Tabellen löschen (Reihenfolge wegen Fremdschlüssel)

SET FOREIGN_KEY_CHECKS = 0;

DROP TRIGGER IF EXISTS trg_ausleih_benutzer_before_insert;
DROP TRIGGER IF EXISTS trg_ausleih_benutzer_before_update;

DROP TABLE IF EXISTS bewertung;
DROP TABLE IF EXISTS ausleihvorgang;
DROP TABLE IF EXISTS zeitslot;
DROP TABLE IF EXISTS buch;
DROP TABLE IF EXISTS benutzer;
DROP TABLE IF EXISTS standort;
DROP TABLE IF EXISTS uebergabeart;
DROP TABLE IF EXISTS genre;
DROP TABLE IF EXISTS verlag;
DROP TABLE IF EXISTS autor;

SET FOREIGN_KEY_CHECKS = 1;

-- Tabellen erstellen
CREATE TABLE standort (
  standort_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  stadt         VARCHAR(100) NOT NULL,
  postleitzahl  VARCHAR(10)  NOT NULL,
  latitude      DECIMAL(10, 7) NULL COMMENT 'Breitengrad für Karten-/Nähe-Suche',
  longitude     DECIMAL(10, 7) NULL COMMENT 'Längengrad für Karten-/Nähe-Suche',
  PRIMARY KEY (standort_id),
  INDEX idx_standort_stadt (stadt),
  INDEX idx_standort_plz (postleitzahl),
  INDEX idx_standort_geo (latitude, longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Standorte der Benutzer für räumliche Suche (Karte, Nähe)';

-- Standort
CREATE TABLE autor (
  autor_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name     VARCHAR(200) NOT NULL,
  PRIMARY KEY (autor_id),
  INDEX idx_autor_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Autorinnen und Autoren der Bücher';

-- Autor
CREATE TABLE verlag (
  verlag_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name      VARCHAR(200) NOT NULL,
  PRIMARY KEY (verlag_id),
  INDEX idx_verlag_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Verlage der Bücher';

-- Verlag
CREATE TABLE genre (
  genre_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  bezeichnung VARCHAR(100) NOT NULL,
  PRIMARY KEY (genre_id),
  UNIQUE KEY uk_genre_bezeichnung (bezeichnung)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Genres zur Kategorisierung der Bücher';

-- Genre
CREATE TABLE uebergabeart (
  uebergabeart_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  bezeichnung     VARCHAR(50) NOT NULL,
  PRIMARY KEY (uebergabeart_id),
  UNIQUE KEY uk_uebergabeart_bezeichnung (bezeichnung)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Art der Übergabe: z.B. Abholung, Versand';

-- Uebergabeart
CREATE TABLE benutzer (
  benutzer_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vorname      VARCHAR(100) NOT NULL,
  nachname     VARCHAR(100) NOT NULL,
  email        VARCHAR(255) NOT NULL,
  telefon      VARCHAR(30)  NULL,
  standort_id  INT UNSIGNED NOT NULL,
  PRIMARY KEY (benutzer_id),
  UNIQUE KEY uk_benutzer_email (email),
  CONSTRAINT fk_benutzer_standort
    FOREIGN KEY (standort_id) REFERENCES standort (standort_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_benutzer_name (nachname, vorname),
  INDEX idx_benutzer_standort (standort_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registrierte Benutzer der Buchtausch-App';

-- Benutzer
CREATE TABLE buch (
  buch_id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  titel                   VARCHAR(300) NOT NULL,
  erscheinungsjahr        SMALLINT UNSIGNED NOT NULL,
  zustand                 VARCHAR(50)  NOT NULL COMMENT 'z.B. neuwertig, gut, gebraucht',
  sprache                 VARCHAR(50)  NULL COMMENT 'Sprache des Buches',
  maximale_ausleihdauer   INT UNSIGNED NOT NULL COMMENT 'Max. Ausleihdauer in Tagen',
  benutzer_id             INT UNSIGNED NOT NULL COMMENT 'Besitzer/Anbieter',
  autor_id                INT UNSIGNED NOT NULL,
  verlag_id               INT UNSIGNED NOT NULL,
  genre_id                INT UNSIGNED NOT NULL,
  uebergabeart_id         INT UNSIGNED NOT NULL,
  PRIMARY KEY (buch_id),
  CONSTRAINT fk_buch_benutzer
    FOREIGN KEY (benutzer_id) REFERENCES benutzer (benutzer_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_buch_autor
    FOREIGN KEY (autor_id) REFERENCES autor (autor_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_buch_verlag
    FOREIGN KEY (verlag_id) REFERENCES verlag (verlag_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_buch_genre
    FOREIGN KEY (genre_id) REFERENCES genre (genre_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_buch_uebergabeart
    FOREIGN KEY (uebergabeart_id) REFERENCES uebergabeart (uebergabeart_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_buch_titel (titel),
  INDEX idx_buch_genre (genre_id),
  INDEX idx_buch_benutzer (benutzer_id),
  INDEX idx_buch_erscheinungsjahr (erscheinungsjahr)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bücher, die von Benutzern zur Ausleihe angeboten werden';

-- Buch
CREATE TABLE zeitslot (
  zeitslot_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  buch_id     INT UNSIGNED NOT NULL,
  startzeit   TIME NOT NULL,
  endzeit     TIME NOT NULL,
  PRIMARY KEY (zeitslot_id),
  CONSTRAINT fk_zeitslot_buch
    FOREIGN KEY (buch_id) REFERENCES buch (buch_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_zeitslot_buch (buch_id),
  CONSTRAINT chk_zeitslot_zeit CHECK (endzeit > startzeit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Verfügbare Abholzeiten pro Buch';

-- Zeitslot
CREATE TABLE ausleihvorgang (
  ausleih_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  buch_id         INT UNSIGNED NOT NULL,
  verleiher_id    INT UNSIGNED NOT NULL COMMENT 'Benutzer, der das Buch anbietet',
  entleiher_id    INT UNSIGNED NOT NULL COMMENT 'Benutzer, der das Buch ausleiht',
  startdatum      DATE NOT NULL,
  enddatum        DATE NOT NULL COMMENT 'Geplantes Ende der Ausleihe',
  rueckgabedatum  DATE NULL COMMENT 'Tatsächliches Rückgabedatum',
  status          VARCHAR(20)  NOT NULL DEFAULT 'aktiv' COMMENT 'z.B. angefragt, aktiv, zurueckgegeben, storniert',
  PRIMARY KEY (ausleih_id),
  CONSTRAINT fk_ausleih_buch
    FOREIGN KEY (buch_id) REFERENCES buch (buch_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_ausleih_verleiher
    FOREIGN KEY (verleiher_id) REFERENCES benutzer (benutzer_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_ausleih_entleiher
    FOREIGN KEY (entleiher_id) REFERENCES benutzer (benutzer_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_ausleih_buch (buch_id),
  INDEX idx_ausleih_entleiher (entleiher_id),
  INDEX idx_ausleih_verleiher (verleiher_id),
  INDEX idx_ausleih_status (status),
  INDEX idx_ausleih_datum (startdatum, enddatum)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Ausleihvorgänge zwischen Verleiher und Entleiher für ein Buch';

-- Ausleihvorgang
DELIMITER //

CREATE TRIGGER trg_ausleih_benutzer_before_insert
BEFORE INSERT ON ausleihvorgang
FOR EACH ROW
BEGIN
  IF NEW.verleiher_id = NEW.entleiher_id THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'verleiher_id und entleiher_id dürfen nicht gleich sein.';
  END IF;
END//

CREATE TRIGGER trg_ausleih_benutzer_before_update
BEFORE UPDATE ON ausleihvorgang
FOR EACH ROW
BEGIN
  IF NEW.verleiher_id = NEW.entleiher_id THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'verleiher_id und entleiher_id dürfen nicht gleich sein.';
  END IF;
END//

DELIMITER ;

-- Bewertung
CREATE TABLE bewertung (
  bewertung_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  benutzer_id  INT UNSIGNED NOT NULL,
  buch_id      INT UNSIGNED NOT NULL,
  ausleih_id   INT UNSIGNED NOT NULL,
  sterne       TINYINT UNSIGNED NOT NULL COMMENT 'Bewertung 1-5',
  kommentar    TEXT NULL,
  PRIMARY KEY (bewertung_id),
  CONSTRAINT fk_bewertung_benutzer
    FOREIGN KEY (benutzer_id) REFERENCES benutzer (benutzer_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_bewertung_buch
    FOREIGN KEY (buch_id) REFERENCES buch (buch_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_bewertung_ausleih
    FOREIGN KEY (ausleih_id) REFERENCES ausleihvorgang (ausleih_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_bewertung_sterne CHECK (sterne BETWEEN 1 AND 5),
  UNIQUE KEY uk_bewertung_ausleih (ausleih_id) COMMENT 'Pro Ausleihvorgang max. eine Bewertung',
  INDEX idx_bewertung_buch (buch_id),
  INDEX idx_bewertung_benutzer (benutzer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bewertungen von Benutzern zu Büchern nach Abschluss einer Ausleihe';

-- Dummy-Daten (mind. 10 pro Tabelle)
INSERT INTO standort (stadt, postleitzahl, latitude, longitude) VALUES
('Berlin',     '10115', 52.520008, 13.404954),
('Berlin',     '10997', 52.499602, 13.449097),
('Hamburg',    '20095', 53.551086, 9.993682),
('München',    '80331', 48.135125, 11.581981),
('Köln',       '50667', 50.937531, 6.960279),
('Frankfurt',  '60311', 50.110924, 8.682127),
('Stuttgart',  '70173', 48.775846, 9.182932),
('Leipzig',    '04109', 51.339695, 12.373075),
('Düsseldorf', '40213', 51.227741, 6.773456),
('Dortmund',   '44135', 51.513587, 7.465298),
('Hannover',   '30159', 52.375892, 9.732010),
('Nürnberg',   '90402', 49.452102, 11.076665);

-- Standort
INSERT INTO autor (name) VALUES
('Joanne K. Rowling'),
('George Orwell'),
('Haruki Murakami'),
('Stephen King'),
('Jane Austen'),
('Thomas Mann'),
('Hermann Hesse'),
('Daniel Kehlmann'),
('Bernhard Schlink'),
('Cornelia Funke'),
('Sebastian Fitzek'),
('Nele Neuhaus');

-- Autor
INSERT INTO verlag (name) VALUES
('Carl Hanser Verlag'),
('Rowohlt'),
('Suhrkamp'),
('Fischer'),
('Piper'),
('dtv'),
('Ullstein'),
('Goldmann'),
('Penguin'),
('Diogenes'),
('Kiepenheuer & Witsch'),
('S. Fischer');

-- Verlag
INSERT INTO genre (bezeichnung) VALUES
('Roman'),
('Krimi'),
('Fantasy'),
('Science-Fiction'),
('Sachbuch'),
('Biografie'),
('Thriller'),
('Jugendbuch'),
('Klassiker'),
('Lyrik'),
('Reise'),
('Ratgeber');

-- Genre
INSERT INTO uebergabeart (bezeichnung) VALUES
('Abholung'),
('Versand'),
('Abholung oder Versand'),
('Abholung an der Haustür'),
('Abholung an öffentlichem Ort'),
('Versand nur innerhalb DE'),
('Abholung nach Vereinbarung'),
('Versand weltweit'),
('Nur Abholung'),
('Nur Versand'),
('Übergabe im Café'),
('Büchertausch-Station');

-- Benutzer
INSERT INTO benutzer (vorname, nachname, email, telefon, standort_id) VALUES
('Anna',   'Schmidt',   'anna.schmidt@example.com',    '030-12345678', 1),
('Tom',    'Müller',    'tom.mueller@example.com',     '030-87654321', 2),
('Lisa',   'Fischer',   'lisa.fischer@example.com',      '040-11122233', 3),
('Max',    'Weber',     'max.weber@example.com',       '089-44455566', 4),
('Julia',  'Wagner',    'julia.wagner@example.com',    '0221-77788899', 5),
('Paul',   'Becker',    'paul.becker@example.com',      '069-12131415', 6),
('Sarah',  'Schulz',    'sarah.schulz@example.com',    NULL,           7),
('Felix',  'Hoffmann',  'felix.hoffmann@example.com',  '0341-16171819', 8),
('Laura',  'Koch',     'laura.koch@example.com',       '0211-20212223', 9),
('David',  'Richter',   'david.richter@example.com',   '0231-24252627', 10),
('Emma',   'Klein',    'emma.klein@example.com',       '0511-28293031', 11),
('Leon',   'Wolf',     'leon.wolf@example.com',        '0911-32333435', 12);

-- Buch
INSERT INTO buch (titel, erscheinungsjahr, zustand, sprache, maximale_ausleihdauer, benutzer_id, autor_id, verlag_id, genre_id, uebergabeart_id) VALUES
('Harry Potter und der Stein der Weisen', 1998, 'gut',       'Deutsch', 28, 1,  1, 2, 3, 1),
('1984',                                  1949, 'gebraucht', 'Deutsch', 21, 2,  2, 3, 4, 2),
('Norwegian Wood',                        2000, 'neuwertig', 'Deutsch', 14, 3,  3, 4, 1, 3),
('Es',                                     1986, 'gut',       'Deutsch', 30, 4,  4, 5, 7, 4),
('Stolz und Vorurteil',                    1813, 'gut',       'Deutsch', 21, 5,  5, 6, 1, 5),
('Der Zauberberg',                         1924, 'gebraucht', 'Deutsch', 42, 6,  6, 7, 9, 6),
('Der Steppenwolf',                        1927, 'gut',       'Deutsch', 21, 7,  7, 4, 9, 7),
('Die Vermessung der Welt',                2005, 'neuwertig', 'Deutsch', 28, 8,  8, 1, 1, 8),
('Der Vorleser',                           1995, 'gut',       'Deutsch', 21, 9,  9, 8, 1, 9),
('Tintenherz',                             2003, 'neuwertig', 'Deutsch', 28, 10, 10, 9, 8, 10),
('Der Seelenbrecher',                      2008, 'gut',       'Deutsch', 21, 11, 11, 10, 7, 11),
('Schweigegeld',                           2010, 'gut',       'Deutsch', 21, 12, 12, 11, 2, 12);

-- Zeitslot
INSERT INTO zeitslot (buch_id, startzeit, endzeit) VALUES
(1,  '09:00', '12:00'),
(1,  '14:00', '18:00'),
(2,  '10:00', '16:00'),
(3,  '08:00', '20:00'),
(4,  '12:00', '18:00'),
(5,  '09:00', '15:00'),
(6,  '10:00', '14:00'),
(7,  '11:00', '17:00'),
(8,  '09:00', '18:00'),
(9,  '10:00', '16:00'),
(10, '08:00', '12:00'),
(11, '13:00', '19:00'),
(12, '09:00', '17:00');

-- Ausleihvorgang
INSERT INTO ausleihvorgang (buch_id, verleiher_id, entleiher_id, startdatum, enddatum, rueckgabedatum, status) VALUES
(1,  1, 2,  '2024-01-10', '2024-02-07', '2024-02-05', 'zurueckgegeben'),
(2,  2, 3,  '2024-02-01', '2024-02-22', '2024-02-20', 'zurueckgegeben'),
(3,  3, 4,  '2024-01-15', '2024-01-29', '2024-01-28', 'zurueckgegeben'),
(4,  4, 5,  '2024-02-10', '2024-03-11', '2024-03-09', 'zurueckgegeben'),
(5,  5, 6,  '2024-01-20', '2024-02-10', '2024-02-09', 'zurueckgegeben'),
(6,  6, 7,  '2024-02-05', '2024-03-18', '2024-03-16', 'zurueckgegeben'),
(7,  7, 8,  '2024-01-25', '2024-02-15', '2024-02-14', 'zurueckgegeben'),
(8,  8, 9,  '2024-02-12', '2024-03-11', '2024-03-10', 'zurueckgegeben'),
(9,  9, 10, '2024-01-08', '2024-01-29', '2024-01-27', 'zurueckgegeben'),
(10, 10, 11,'2024-02-15', '2024-03-14', '2024-03-12', 'zurueckgegeben'),
(11, 11, 12,'2024-01-12', '2024-02-02', '2024-02-01', 'zurueckgegeben'),
(12, 12, 1, '2024-02-20', '2024-03-12', NULL,          'aktiv');

-- Bewertung
INSERT INTO bewertung (benutzer_id, buch_id, ausleih_id, sterne, kommentar) VALUES
(2, 1, 1, 5, 'Schnelle Abholung, Buch in gutem Zustand.'),
(3, 2, 2, 4, 'Unkomplizierte Übergabe.'),
(4, 3, 3, 4, 'Hat etwas länger gedauert mit der Rückgabe, aber alles ok.'),
(5, 4, 4, 5, 'Sehr zuverlässig, vielen Dank.'),
(6, 5, 5, 5, 'Sehr netter Kontakt, gerne wieder.'),
(7, 6, 6, 4, 'Buch pünktlich zurück.'),
(8, 7, 7, 4, 'Buch wie beschrieben.'),
(9, 8, 8, 5, 'Tolle Absprache.'),
(10, 9, 9, 5, 'Unkompliziert und pünktlich.'),
(11, 10, 10, 4, 'Gute Kommunikation.');

-- Testabfragen

-- Verfügbare Bücher in Berlin (nicht aktiv ausgeliehen)
SELECT b.buch_id, b.titel, a.name AS autor, g.bezeichnung AS genre, s.stadt, s.postleitzahl
FROM buch b
JOIN benutzer bn ON b.benutzer_id = bn.benutzer_id
JOIN standort s ON bn.standort_id = s.standort_id
JOIN autor a ON b.autor_id = a.autor_id
JOIN genre g ON b.genre_id = g.genre_id
WHERE s.stadt = 'Berlin'
  AND b.buch_id NOT IN (
    SELECT buch_id FROM ausleihvorgang WHERE status = 'aktiv'
  )
ORDER BY b.titel;

-- Aktive Ausleihen von Nutzer 2
SELECT a.ausleih_id, b.titel, CONCAT(v.vorname, ' ', v.nachname) AS verleiher,
       a.startdatum, a.enddatum, a.status
FROM ausleihvorgang a
JOIN buch b ON a.buch_id = b.buch_id
JOIN benutzer v ON a.verleiher_id = v.benutzer_id
WHERE a.entleiher_id = 2 AND a.status = 'aktiv';

-- Bewertungsdurchschnitt pro Buch
SELECT b.buch_id, b.titel, ar.name AS autor,
       ROUND(AVG(be.sterne), 2) AS durchschnitt_sterne,
       COUNT(be.bewertung_id) AS anzahl_bewertungen
FROM buch b
LEFT JOIN bewertung be ON b.buch_id = be.buch_id
LEFT JOIN autor ar ON b.autor_id = ar.autor_id
GROUP BY b.buch_id, b.titel, ar.name
ORDER BY durchschnitt_sterne IS NULL, durchschnitt_sterne DESC, b.titel;

-- Bücher Genre Fantasy
SELECT b.buch_id, b.titel, a.name AS autor, b.zustand, b.maximale_ausleihdauer
FROM buch b
JOIN autor a ON b.autor_id = a.autor_id
JOIN genre g ON b.genre_id = g.genre_id
WHERE g.bezeichnung = 'Fantasy'
ORDER BY b.titel;

-- Bücher in München (standortbasiert)
SELECT b.buch_id, b.titel, s.stadt, s.postleitzahl, s.latitude, s.longitude
FROM buch b
JOIN benutzer bn ON b.benutzer_id = bn.benutzer_id
JOIN standort s ON bn.standort_id = s.standort_id
WHERE s.stadt = 'München'
  AND b.buch_id NOT IN (SELECT buch_id FROM ausleihvorgang WHERE status = 'aktiv')
ORDER BY b.titel;

-- Zeilenanzahl pro Tabelle
SELECT 'standort'      AS tabelle, COUNT(*) AS anzahl FROM standort
UNION ALL SELECT 'autor',          COUNT(*) FROM autor
UNION ALL SELECT 'verlag',         COUNT(*) FROM verlag
UNION ALL SELECT 'genre',          COUNT(*) FROM genre
UNION ALL SELECT 'uebergabeart',   COUNT(*) FROM uebergabeart
UNION ALL SELECT 'benutzer',       COUNT(*) FROM benutzer
UNION ALL SELECT 'buch',           COUNT(*) FROM buch
UNION ALL SELECT 'zeitslot',       COUNT(*) FROM zeitslot
UNION ALL SELECT 'ausleihvorgang', COUNT(*) FROM ausleihvorgang
UNION ALL SELECT 'bewertung',      COUNT(*) FROM bewertung;
CREATE DATABASE IF NOT EXISTS gestione_fotocopiatrici_buzzi;
USE gestione_fotocopiatrici_buzzi;

CREATE TABLE utenti (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    cognome VARCHAR(50) NOT NULL,
    ruolo ENUM('standard', 'gestore') NOT NULL DEFAULT 'standard',
    codice_tessera VARCHAR(20) NOT NULL UNIQUE,
    credito DECIMAL(6,2) NOT NULL DEFAULT 10.00
);

CREATE TABLE formato(
    id INT AUTO_INCREMENT PRIMARY KEY,
    dimensioni VARCHAR(20) NOT NULL UNIQUE,
    costo DECIMAL(10,2) NOT NULL
);

CREATE TABLE stampe (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_utente INT NOT NULL,
    numero_pagine INT NOT NULL,
    formato_scelto VARCHAR(20) NOT NULL,
    data_stampa DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_utente) REFERENCES utenti(id),
    FOREIGN KEY (formato_scelto) REFERENCES formato(dimensioni)
);

INSERT INTO formato (dimensioni, costo) VALUES ("A4", 0.05), ("A3", 0.10);

INSERT INTO utenti 
(nome, cognome, ruolo, codice_tessera, credito)
VALUES
('Giovanni', 'Panza', 'gestore', 'BUZZI-GEST-001', 100.00),
('Daniele', 'Maddaluno', 'standard', 'BUZZI-DOC-001', 10.00),
('Caterina', 'Bianchi', 'standard', 'BUZZI-DOC-002', 10.00),
('Barbara', 'Signorini', 'standard', 'BUZZI-DOC-003', 10.00),
('Carlo', 'Rossi', 'standard', 'BUZZI-VICE-001', 10.00),
('Angela', 'Cortese', 'standard', 'BUZZI-DOC-004', 10.00),
('Maria', 'Stella', 'standard', 'BUZZI-DOC-005', 10.00),
('Fabio', 'Cherici', 'standard', 'BUZZI-DOC-006', 10.00),
('Sascia', 'Neri', 'standard', 'BUZZI-ATA-001', 10.00),
('Lucia', 'Verdi', 'standard', 'BUZZI-ATA-002', 10.00);


DELIMITER //

CREATE PROCEDURE AcquistaProdotto(
    IN p_codice_tessera VARCHAR(20), 
    IN p_foglio VARCHAR(20), 
    IN p_numero_pagine INT
)
BEGIN
   
    DECLARE v_costo_totale DECIMAL(10,2);
    DECLARE v_saldo_attuale DECIMAL(10,2);
    DECLARE v_id_utente INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT id, credito INTO v_id_utente, v_saldo_attuale 
    FROM utenti 
    WHERE codice_tessera = p_codice_tessera FOR UPDATE;

    SELECT costo * p_numero_pagine INTO v_costo_totale 
    FROM formato 
    WHERE dimensioni = p_foglio;

    IF v_id_utente IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Utente non trovato!';
    ELSEIF v_saldo_attuale >= v_costo_totale THEN
       
        UPDATE utenti SET credito = credito - v_costo_totale WHERE id = v_id_utente;
        
        INSERT INTO stampe (id_utente, numero_pagine, formato_scelto) 
        VALUES (v_id_utente, p_numero_pagine, p_foglio);
        
        COMMIT;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insufficiente!';
    END IF;
END //

DELIMITER ;
# "-- /usr/local/mysql-8.0.23-macos10.15-x86_64/bin/mysql -u root -p"
DROP DATABASE testdb;
CREATE DATABASE testdb;
USE testdb;

CREATE TABLE Utilisateur(courriel VARCHAR(25), motDePasse VARCHAR(25), PRIMARY KEY (courriel));

CREATE TABLE Continent (nomContinent varchar(50), nombreGraine integer, nombreEspece integer, nombreGenre integer,
    PRIMARY KEY (nomContinent));

CREATE TABLE Deposant (codeDeposant char(6), nom varchar(120), ville varchar(50), nombreEspeceDepose integer, nombreGenreDepose
    integer, nombreGraineDepose integer, courriel varchar(25), UNIQUE (courriel), 
    PRIMARY KEY (codeDeposant), 
    FOREIGN KEY (courriel) REFERENCES Utilisateur(courriel) ON UPDATE CASCADE ON DELETE CASCADE);

CREATE TABLE CasierConservation (idCase integer NOT NULL, quantite integer, nombreDepot integer, nombreRetrait integer, 
    PRIMARY KEY (idCase));

CREATE TABLE Espece (espece varchar(50), nomVernaculaire varchar(50), nombreDeposant integer, quantite integer, 
    PRIMARY KEY (espece));

CREATE TABLE Pays (pays varchar(50), continent varchar(50), nombreEspeceDepose integer, nombreGenreDepose integer,
    nombreGraineDepose integer, PRIMARY KEY (pays), 
    FOREIGN KEY (continent) REFERENCES Continent(nomContinent) ON UPDATE CASCADE);

CREATE TABLE Entreposer(idCase integer, espece varchar(50), codeDeposant char(6), dateOuverture DATETIME, pays varchar(50),
PRIMARY KEY (idCase, espece, pays, codeDeposant),
FOREIGN KEY (idCase) REFERENCES CasierConservation(idCase) ON UPDATE CASCADE ON DELETE CASCADE ,
FOREIGN KEY (espece) REFERENCES Espece(espece) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY (codeDeposant) REFERENCES Deposant(codeDeposant) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY (pays) REFERENCES Pays(pays) ON UPDATE CASCADE);

CREATE TABLE Genre (genre varchar(50), nomVernaculaire varchar(50), nombreDeposant integer, nombreEspece integer, quantite integer,
PRIMARY KEY (genre));

CREATE TABLE AppartenirGenre (espece varchar(50), genre varchar(50), PRIMARY KEY (espece, genre),
FOREIGN KEY (espece) REFERENCES Espece(espece) ON UPDATE CASCADE,
FOREIGN KEY (genre) REFERENCES Genre(genre) ON UPDATE CASCADE );

CREATE TABLE ProvenirDeposant (pays varchar(50), codeDeposant char(6), PRIMARY KEY (codeDeposant),
FOREIGN KEY (codeDeposant) REFERENCES Deposant(codeDeposant) ON UPDATE CASCADE ON DELETE CASCADE,
FOREIGN KEY (pays) REFERENCES Pays(pays) ON UPDATE CASCADE);

CREATE TABLE Deposer (espece varchar(50), codeDeposant char(6), quantite integer, nombreBoites integer, dateArriver DATETIME(3), PRIMARY Key (codeDeposant, dateArriver, espece),
FOREIGN Key (codeDeposant) REFERENCES Deposant(codeDeposant) ON UPDATE CASCADE,
FOREIGN Key (espece) REFERENCES Espece(espece) ON UPDATE CASCADE);


CREATE TABLE Retirer (espece varchar(50), codeDeposant char(6), quantite integer, nombreBoites integer, dateSortie DATETIME(3), PRIMARY Key (codeDeposant, dateSortie, espece),
FOREIGN Key (codeDeposant) REFERENCES Deposant(codeDeposant) ON UPDATE CASCADE,
FOREIGN Key (espece) REFERENCES Espece(espece) ON UPDATE CASCADE);

CREATE INDEX Index_EntreposerSurEspece ON Entreposer(espece) USING BTREE;
CREATE INDEX Index_EntreposerSurPays ON Entreposer(pays) USING HASH;
CREATE INDEX Index_PaysSurContinent ON Pays(continent) USING BTREE ;
CREATE INDEX Index_DeposerSurCodeDeposant ON Deposer(codeDeposant) USING HASH ;
CREATE INDEX Index_RetirerSurCodeDeposant ON Retirer(codeDeposant) USING HASH ;


# "Update la quantite d'espece déposer pour un déposant"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteEspeceParDeposant(IN  codeDeposant char(6))
BEGIN
    DECLARE quantiteEspece integer;
    SELECT COUNT(DISTINCT E.espece)
    INTO quantiteEspece
        FROM Espece E, Entreposer E1
    WHERE E1.codeDeposant = codeDeposant AND E.Espece = E1.espece;

    UPDATE Deposant D
    SET D.nombreEspeceDepose = quantiteEspece
    WHERE D.codeDeposant = codeDeposant;

END //
DELIMITER ;

# "Update la quantite de genre déposer pour un déposant"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteGenreParDeposant(IN  codeDeposant char(6))
BEGIN
    DECLARE quantiteGenre integer;
    SELECT COUNT(DISTINCT A.genre)
    INTO quantiteGenre
        FROM Espece E, Entreposer E1, AppartenirGenre A
    WHERE E1.codeDeposant = codeDeposant AND E.Espece = E1.espece AND E1.espece = A.espece;

    UPDATE Deposant D
    SET D.nombreGenreDepose = quantiteGenre
    WHERE D.codeDeposant = codeDeposant;

END //
DELIMITER ;


# "Update la quantite de graine déposer pour un déposant"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteGraineParDeposant(IN  codeDeposant char(6))
BEGIN
    DECLARE quantiteGraine integer;
    SELECT SUM(C.quantite)
    INTO quantiteGraine
        FROM CasierConservation C, Entreposer E
    WHERE C.idCase = E.idCase AND E.codeDeposant = codeDeposant;

    UPDATE Deposant D
    SET D.nombreGRaineDepose = quantiteGraine
    WHERE D.codeDeposant = codeDeposant;

END //
DELIMITER ;

# "Update la quantite de graines déposees pour un pays"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteGraineParPays(IN  paysEntree varchar(50))
BEGIN
    DECLARE quantiteGraine integer;
    SELECT SUM(C.quantite)
    INTO quantiteGraine
        FROM CasierConservation C, Entreposer E, Pays P
    WHERE C.idCase = E.idCase AND E.pays = paysEntree;

    UPDATE Pays P
    SET P.nombreGraineDepose = quantiteGraine
    WHERE P.pays = paysEntree;

END //
DELIMITER ;

# "Update la quantite d'especes déposees pour un pays"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteEspeceParPays(IN  paysEntree varchar(50))
BEGIN
    DECLARE quantiteEspece integer;
    SELECT COUNT(DISTINCT E.espece)
    INTO quantiteEspece
        FROM Entreposer E
    WHERE E.pays = paysEntree;

    UPDATE Pays P
    SET P.nombreEspeceDepose = quantiteEspece
    WHERE P.pays = paysEntree;

END //
DELIMITER ;

# "Update la quantite de genres déposees pour un pays"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteGenreParPays(IN  paysEntree varchar(50))
BEGIN
    DECLARE quantiteGenre integer;
    SELECT COUNT( DISTINCT A.genre)
    INTO quantiteGenre
        FROM Entreposer E, Espece ES, AppartenirGenre A, Genre G
    WHERE E.pays = paysEntree AND E.espece = ES.espece AND ES.espece = A.espece;

    UPDATE Pays P
    SET P.nombreGenreDepose = quantiteGenre
    WHERE P.pays = paysEntree;

END //
DELIMITER ;


# "Update la quantite de graines déposees pour un contient"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteGraineParContinent(IN  paysEntree varchar(50))
BEGIN
    DECLARE quantiteGraine integer;
    SELECT SUM( CA.quantite)
    INTO quantiteGraine
        FROM Entreposer E, Pays P, Continent C, CasierConservation CA
    WHERE C.nomContinent = P.continent AND P.pays = E.pays
      AND E.idCase = CA.idCase AND C.nomContinent =(SELECT P.continent
                                                    FROM PAYS P
                                                    WHERE P.pays = paysEntree);

    UPDATE Continent C
    SET C.nombreGraine = quantiteGraine
    WHERE C.nomContinent = (SELECT P.continent
                             FROM PAYS P
                            WHERE P.pays = paysEntree);

END //
DELIMITER ;


# "Update la quantite de especes déposees pour un contient"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteEspeceParContinent(IN  paysEntree varchar(50))
BEGIN
    DECLARE quantiteEspece integer;
    SELECT COUNT(DISTINCT E.espece)
    INTO quantiteEspece
        FROM Entreposer E, Pays P, Continent C
    WHERE C.nomContinent = P.continent AND  P.pays = E.pays
       AND C.nomContinent =(SELECT P.continent
                             FROM PAYS P
                            WHERE P.pays = paysEntree);
    UPDATE Continent C
    SET C.nombreEspece = quantiteEspece
    WHERE C.nomContinent = (SELECT P.continent
                             FROM PAYS P
                            WHERE P.pays = paysEntree);

END //
DELIMITER ;


# "Update la quantite de genres déposees pour un contient"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteGenreParContinent(IN  paysEntree varchar(50))
BEGIN
    DECLARE quantiteGenre integer;
    SELECT COUNT(DISTINCT AG.genre)
    INTO quantiteGenre
        FROM Entreposer E, Pays P, Espece ES, AppartenirGenre AG, Continent C
    WHERE C.nomContinent = P.continent AND P.pays = E.pays
      AND E.espece = ES.espece AND ES.espece =AG.espece AND C.nomContinent =
                                                            (SELECT P.continent
                                                             FROM PAYS P
                                                             WHERE P.pays = paysEntree);

    UPDATE Continent C
    SET C.nombreGenre = quantiteGenre
    WHERE C.nomContinent = (SELECT P.continent
                            FROM PAYS P
                            WHERE P.pays = paysEntree);

END //
DELIMITER ;

# "Modifie la quantité d'espèces pour chaque genre"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteEspecesParGenre(IN  depotGenre varchar(50))
BEGIN
    DECLARE quantiteEspece integer;
    SELECT COUNT(A.espece)
    INTO quantiteEspece
        FROM Genre G, AppartenirGenre A
    WHERE A.genre = G.genre AND G.genre = depotGenre;

    UPDATE Genre G
    SET G.nombreEspece = quantiteEspece
    WHERE G.genre = depotGenre;

END //
DELIMITER ;


# "Modifie la quantité de deposants pour chaque espece"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteDeposantsParEspece(IN  depotEspece varchar(50))
BEGIN
    DECLARE deposantsEspeces integer;

    SELECT COUNT(DISTINCT E.codedeposant)
    INTO deposantsEspeces
        FROM Entreposer E, Espece ES, Deposant D
    WHERE ES.espece = depotEspece AND E.espece = ES.espece;

    UPDATE Espece E
    SET E.nombreDeposant = deposantsEspeces
    WHERE E.espece = depotEspece;

END //
DELIMITER ;


# "Modifie la quantité de deposants pour chaque genre"
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteDeposantsParGenre(IN  depotGenre varchar(50))
BEGIN
    DECLARE deposantsGenre integer;

    SELECT COUNT(E.codedeposant)
    INTO deposantsGenre
        FROM Entreposer E, Espece ES, AppartenirGenre A
    WHERE A.genre = depotGenre AND A.espece = ES.espece AND ES.espece = E.espece;


    UPDATE Genre G2
    SET G2.nombreDeposant = deposantsGenre
    WHERE G2.genre = depotGenre;

END //
DELIMITER ;


#Met à jour la quantité du genre
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteGenre(IN  genreEntree varchar(50))
BEGIN
    DECLARE quantiteGenre integer;

    SELECT SUM(E.quantite)
    INTO quantiteGenre
        FROM Espece E, AppartenirGenre A
    WHERE A.genre = genreEntree AND A.espece = E.espece;

    UPDATE Genre G
    SET G.quantite = quantiteGenre
    WHERE G.genre = genreEntree;

END //
DELIMITER ;


# "Crée ou met-à-jour les tuples de l'entité Genre"
DELIMITER //
CREATE  PROCEDURE AjoutUpdateTuplesGenre(IN  especeEntree varchar(50), IN nomVernaculaireEspece varchar(50), IN genreEntree varchar(50), IN nomVernaculaireGenre varchar(50),
 IN quantiteDepot integer)
BEGIN
DECLARE nomGenre varchar(50);
DECLARE lecture_complete integer DEFAULT FALSE;
DECLARE curseur CURSOR FOR SELECT G.genre FROM Genre G;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET lecture_complete = TRUE;

OPEN curseur;
boucle : LOOP

FETCH curseur INTO nomGenre;
IF lecture_complete THEN
    INSERT INTO Genre (genre, nomVernaculaire, nombreDeposant, nombreEspece, quantite) VALUES (genreEntree, nomVernaculaireGenre,
                                                                                               1, 1, quantiteDepot);
    INSERT INTO Espece(espece, nomVernaculaire, nombreDeposant, quantite) VALUES (especeEntree, nomVernaculaireEspece, 1, quantiteDepot);
    INSERT INTO AppartenirGenre(espece, genre) VALUES (especeEntree, genreEntree);
    LEAVE boucle;
END IF;

IF nomGenre = genreEntree THEN
    CALL EntreeUpdateTuplesEspece(especeEntree, nomVernaculaireEspece,genreEntree, quantiteDepot);
    UPDATE Genre G
    SET G.quantite = G.quantite + quantiteDepot
    WHERE G.genre =genreEntree;
    CALL UpdateQuantiteDeposantsParGenre(genreEntree);
    CALL UpdateQuantiteEspecesParGenre(genreEntree);
    LEAVE boucle;
END IF;

END LOOP boucle;
CLOSE curseur;

END //
DELIMITER ;


# "Crée ou met-à-jour les tuples de l'entité Espece"
DELIMITER //
CREATE  PROCEDURE EntreeUpdateTuplesEspece(IN  especeEntree varchar(50), IN nomVernaculaireEspece varchar(50), IN genreEntree varchar(50),
 IN quantiteDepot integer)
BEGIN
DECLARE nomEspece varchar(50);
DECLARE lecture_complete integer DEFAULT FALSE;
DECLARE curseur CURSOR FOR SELECT E.espece FROM Espece E;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET lecture_complete = TRUE;

OPEN curseur;
boucle : LOOP

FETCH curseur INTO nomEspece;
IF lecture_complete THEN
    INSERT INTO Espece(espece, nomVernaculaire, nombreDeposant, quantite) VALUES (especeEntree, nomVernaculaireEspece, 1, quantiteDepot);
    INSERT INTO AppartenirGenre(espece, genre) VALUES (especeEntree, genreEntree);
    LEAVE boucle;
END IF;

IF nomEspece = especeEntree THEN
    UPDATE Espece E
    SET E.quantite = E.quantite + quantiteDepot
     WHERE E.espece = especeEntree;
    CALL UpdateQuantiteDeposantsParEspece(especeEntree);
     LEAVE boucle;
END IF;

END LOOP boucle;
CLOSE curseur;

END //
DELIMITER ;


# "Crée ou met-à-jour les tuples de Entreposer et CaseConservation"
DELIMITER //
CREATE  PROCEDURE EntreeUpdateTuplesEntreposerCaseConservation(IN  especeEntree varchar(50), IN IdDeposant varchar(50), IN paysEchantillon varchar(50),
 IN quantiteDepotGraine integer)
BEGIN
DECLARE compartiment varchar(50);
DECLARE codeDeposant char(6);
DECLARE provenance varchar(50);
DECLARE EspeceGraine varchar(50);
DECLARE quantitePresente integer;
DECLARE caseMax integer;
DECLARE quantiteMaxParCase integer;
DECLARE quantiteGraine integer;
DECLARE date DATETIME;
DECLARE lecture_complete integer DEFAULT FALSE;
DECLARE curseur CURSOR FOR SELECT E.espece, E.codeDeposant, E.pays, E.idCase  FROM Entreposer E ;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET lecture_complete = TRUE;

SET quantiteMaxParCase = 2000;
SET quantiteGraine = quantiteDepotGraine;


OPEN curseur;
boucle : LOOP

FETCH curseur INTO EspeceGraine, codeDeposant, provenance, compartiment;

IF lecture_complete THEN
WHILE quantiteGraine <> 0 DO
    SELECT MAX(C.idCase)
    INTO caseMax
    FROM CasierConservation C;
    SET caseMax = IFNULL(caseMax,0);
    SET date = NOW();
    IF quantiteGraine <= quantiteMaxParCase THEN

        INSERT INTO CasierConservation(idCase, quantite, nombreDepot, nombreRetrait) VALUES (caseMax+1, quantiteGraine,1,0);
        INSERT INTO Entreposer(idCase, espece, codeDeposant, dateOuverture, pays) VALUES (caseMax+1, especeEntree, IdDeposant,
                                                                                         date, paysEchantillon);
        SET quantiteGraine = 0;
    ELSE
       INSERT INTO CasierConservation(idCase, quantite, nombreDepot, nombreRetrait) VALUES (caseMax+1, quantiteMaxParCase,1,0);
       INSERT INTO Entreposer(idCase, espece, codeDeposant, dateOuverture, pays) VALUES (caseMax+1, especeEntree, IdDeposant,
                                                                                         date, paysEchantillon);
        SET quantiteGraine = quantiteGraine - quantiteMaxParCase;

    END IF;
    END WHILE;
    LEAVE boucle;
END IF;

IF EspeceGraine = especeEntree AND codeDeposant = IdDeposant AND provenance = paysEchantillon AND quantiteGraine > 0  THEN
    SELECT C.quantite
    INTO quantitePresente
    FROM CasierConservation C
    WHERE C.idCase = compartiment;
    IF quantitePresente = quantiteMaxParCase THEN
    SET quantitePresente =quantitePresente; #ne rien faire

    ELSEIF quantiteGraine + quantitePresente <= quantiteMaxParCase THEN

        UPDATE CasierConservation C
        SET C.quantite = C.quantite + quantiteGraine, C.nombreDepot = C.nombreDepot +1
        WHERE C.idCase = compartiment;
        SET quantiteGraine = 0;
    ELSE
        UPDATE CasierConservation C
        SET C.quantite = quantiteMaxParCase, C.nombreDepot = C.nombreDepot +1
        WHERE C.idCase = compartiment;

        SET quantiteGraine = quantiteGraine - quantiteMaxParCase + quantitePresente;

    END IF;
     IF quantiteGraine = 0 THEN
        LEAVE boucle;
    END IF;
END IF;

IF EspeceGraine = especeEntree AND codeDeposant = IdDeposant AND provenance = paysEchantillon AND quantiteGraine < 0  THEN
   SELECT C.quantite
    INTO quantitePresente
    FROM CasierConservation C
    WHERE C.idCase = compartiment;

   IF quantitePresente = 0 THEN
    SET quantitePresente =quantitePresente; #ne rien faire

   ELSEIF quantiteGraine + quantitePresente >= 0 THEN

    UPDATE CasierConservation C
        SET C.quantite = C.quantite + quantiteGraine, C.nombreRetrait = C.nombreRetrait +1
        WHERE C.idCase = compartiment;
    SET quantiteGraine = 0;

    ELSE
       UPDATE CasierConservation C
        SET C.quantite = 0, C.nombreRetrait = C.nombreRetrait +1
        WHERE C.idCase = compartiment;
    SET quantiteGraine = quantiteGraine + quantitePresente;

    END IF;
    IF quantiteGraine = 0 THEN
        LEAVE boucle;
    END IF;
END IF;

 IF quantiteGraine = 0 THEN
        LEAVE boucle;
    END IF;

END LOOP boucle;
CLOSE curseur;

END //
DELIMITER ;


-- drop procedure  DeposerRetirer;

# Met-à-jour tous les tuples de la base de donnee
DELIMITER //
CREATE  PROCEDURE DeposerRetirer(IN  especeEntree varchar(50),IN nomVernaculaireEspece varchar(50),IN genreEntree varchar(50),
 IN nomVernaculaireGenre varchar(50), IN quantiteDepot integer, IN IdDeposant varchar(50), IN paysEchantillon varchar(50),
  IN quantiteBoite integer)
BEGIN

    DECLARE Date DATETIME;
    DECLARE QuantiteGraineDeDeposantPresente integer;

    SELECT SUM(C.quantite)
    INTO QuantiteGraineDeDeposantPresente
    FROM CasierConservation C, Entreposer E
    WHERE E.codeDeposant = IdDeposant AND E.espece = especeEntree AND E.pays = paysEchantillon AND E.idCase = C.idCase;

    IF QuantiteGraineDeDeposantPresente + quantiteDepot < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La quantité de graines disponible est insuffisante pour la demande de retrait';
    END IF;

    IF quantiteDepot = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un dépôt ne peut pas être constitué de 0 graine';
    END IF;

    SELECT VerifierEspeceValide(especeEntree, genreEntree);

        CALL AjoutUpdateTuplesGenre(especeEntree,nomVernaculaireEspece,
        genreEntree,nomVernaculaireGenre,quantiteDepot);
        CALL EntreeUpdateTuplesEntreposerCaseConservation(especeEntree,IdDeposant,paysEchantillon,quantiteDepot);
        CALL UpdateQuantiteGenreParPays(paysEchantillon);
        CALL UpdateQuantiteEspeceParPays(paysEchantillon);
        CALL UpdateQuantiteGraineParPays(paysEchantillon);
        CALL UpdateQuantiteGenreParDeposant(IdDeposant);
        CALL UpdateQuantiteEspeceParDeposant(IdDeposant);
        CALL UpdateQuantiteGraineParDeposant(IdDeposant);
        CALL UpdateQuantiteGenreParContinent(paysEchantillon);
        CALL UpdateQuantiteEspeceParContinent(paysEchantillon);
        CALL UpdateQuantiteGraineParContinent(paysEchantillon);
        SET Date = NOW();
        IF quantiteDepot > 0 THEN
            INSERT INTO Deposer(espece, codeDeposant, quantite, nombreBoites, dateArriver) VALUES
             (especeEntree,IdDeposant,quantiteDepot,quantiteBoite,Date);
            ELSEIF quantiteDepot < 0 THEN
            INSERT INTO Retirer(espece, codeDeposant, quantite, nombreBoites, dateSortie) VALUES
             (especeEntree,IdDeposant,-quantiteDepot,quantiteBoite,Date);
            END IF;
END //
DELIMITER ;

# "Met-à-jour tous les tuples de la base de donnee sans update les quantite (batch add)"
DELIMITER //
CREATE  PROCEDURE DeposerRetirerSansUpdateQuantite(IN  especeEntree varchar(50),IN nomVernaculaireEspece varchar(50),IN genreEntree varchar(50),
 IN nomVernaculaireGenre varchar(50), IN quantiteDepot integer, IN IdDeposant varchar(50), IN paysEchantillon varchar(50),
  IN quantiteBoite integer)
BEGIN

    DECLARE Date DATETIME;
    DECLARE QuantiteGraineDeDeposantPresente integer;

    SELECT SUM(C.quantite)
    INTO QuantiteGraineDeDeposantPresente
    FROM CasierConservation C, Entreposer E
    WHERE E.codeDeposant = IdDeposant AND E.espece = especeEntree AND E.pays = paysEchantillon AND E.idCase = C.idCase;

    IF QuantiteGraineDeDeposantPresente + quantiteDepot < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La quantité de graines disponible est insuffisante pour la demande de retrait';
    END IF;

    IF quantiteDepot = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un dépôt ne peut pas être constitué de 0 graine';
    END IF;

    -- SELECT VerifierEspeceValide(especeEntree, genreEntree);

        CALL AjoutUpdateTuplesGenre(especeEntree,nomVernaculaireEspece,
        genreEntree,nomVernaculaireGenre,quantiteDepot);
        CALL EntreeUpdateTuplesEntreposerCaseConservation(especeEntree,IdDeposant,paysEchantillon,quantiteDepot);
        SET Date = NOW();
        IF quantiteDepot > 0 THEN
            INSERT INTO Deposer(espece, codeDeposant, quantite, nombreBoites, dateArriver) VALUES
             (especeEntree,IdDeposant,quantiteDepot,quantiteBoite,Date);
            ELSEIF quantiteDepot < 0 THEN
            INSERT INTO Retirer(espece, codeDeposant, quantite, nombreBoites, dateSortie) VALUES
             (especeEntree,IdDeposant,-quantiteDepot,quantiteBoite,Date);
            END IF;
END //
DELIMITER ;

# update les quantite selon le pays
DELIMITER //
CREATE  PROCEDURE UpdateQuantitePays(IN paysEchantillon varchar(50))
BEGIN
    CALL UpdateQuantiteGenreParPays(paysEchantillon);
    CALL UpdateQuantiteEspeceParPays(paysEchantillon);
    CALL UpdateQuantiteGraineParPays(paysEchantillon);
    CALL UpdateQuantiteGenreParContinent(paysEchantillon);
    CALL UpdateQuantiteEspeceParContinent(paysEchantillon);
    CALL UpdateQuantiteGraineParContinent(paysEchantillon);
END //
DELIMITER ;

# update les quantite selon le deposant
DELIMITER //
CREATE  PROCEDURE UpdateQuantiteDeposant(IN IdDeposant char(6))
BEGIN
    CALL UpdateQuantiteGenreParDeposant(IdDeposant);
    CALL UpdateQuantiteEspeceParDeposant(IdDeposant);
    CALL UpdateQuantiteGraineParDeposant(IdDeposant);
END //
DELIMITER ;


SELECT * FROM AppartenirGenre;
SELECT * FROM CasierConservation;
SELECT * FROM PAYS;
SELECT * FROM Deposant;
SELECT * FROM Espece;
SELECT * FROM Entreposer;
SELECT * FROM GENRE;
SELECT * FROM Continent;
SELECT * FROM Deposer;
SELECT * FROM Retirer;
-- CALL DeposerRetirer('ne','black cohosh',
    -- 'Jur','baneberry',3,'CAN004','Canada',3);


# Vérifie que le codeDeposant est d'une longueur de 6 caractères et s'assure que le nombre de graines, genres et espèces à 0
DELIMITER //
CREATE TRIGGER DeposantValide
BEFORE INSERT ON Deposant
FOR EACH ROW
BEGIN
IF LENGTH(NEW.codeDeposant) <> 6 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Le code dun deposant doit être de 6 caractères';
ELSEIF NEW.nombreGenreDepose <> 0 OR NEW.nombreGraineDepose <> 0 OR NEW.nombreEspeceDepose <> 0 THEN
    SET NEW.nombreGraineDepose =0;
    SET NEW.nombreEspeceDepose = 0;
    SET NEW.nombreGenreDepose = 0;
END IF;
END;//
DELIMITER ;

#"S'assure que le nombre initial de graines, genres et espèces à 0 pour les continents"
DELIMITER //
CREATE TRIGGER ContinentValide
BEFORE INSERT ON Continent
FOR EACH ROW
BEGIN
IF NEW.nombreGraine <> 0 OR NEW.nombreEspece <> 0 OR NEW.nombreGenre <> 0 THEN
    SET NEW.nombreGraine =0;
    SET NEW.nombreEspece = 0;
    SET NEW.nombreGenre = 0;
END IF;
END;//
DELIMITER ;

#"S'assure que le nombre initial de graines, genres et espèces à 0 pour les les pays"
DELIMITER //
CREATE TRIGGER PaysValide
BEFORE INSERT ON Pays
FOR EACH ROW
BEGIN
IF NEW.nombreGenreDepose <> 0 OR NEW.nombreEspeceDepose <> 0 OR NEW.nombreGraineDepose <> 0 THEN
    SET NEW.nombreGraineDepose =0;
    SET NEW.nombreEspeceDepose = 0;
    SET NEW.nombreGenreDepose = 0;
END IF;
END;//
DELIMITER ;

#"Vérifie qu'un courriel possède un @"
DELIMITER //
CREATE TRIGGER CourrielValide
BEFORE INSERT ON Deposant
FOR EACH ROW
BEGIN
    IF NEW.courriel NOT LIKE '%@%' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cette adresse courriel nest pas valide';
    END IF;
END;//
DELIMITER ;


#"Détermine si la combinaison genre/espece est valide"
DELIMITER //
CREATE  FUNCTION VerifierEspeceValide (especeEntree  varchar(50), genreEntree varchar(50))
RETURNS BIT(1)
READS SQL DATA
BEGIN
   DECLARE CountGenre integer;
   DECLARE CountEspece integer;
   DECLARE Retour BIT(1);

    SELECT count(genre)
    INTO CountGenre
    FROM Genre
    WHERE genre = genreEntree;

   SELECT count(espece)
    INTO CountEspece
    FROM Espece
    WHERE espece = especeEntree;


    IF CountGenre = 0 AND CountEspece = 1 THEN
        SET Retour = 0;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La combinaison entre genre et espèce n est pas valide';
    ELSE
        SET Retour = 1;
        END IF;
    RETURN Retour;
END; //
DELIMITER ;

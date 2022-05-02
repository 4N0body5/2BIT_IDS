/* ********************************************************************************* */
/*                                                                                   */
/*   nazov projektu:     IDS - 4.cast; Zadanie c.33 - Lekarna                        */
/*   autori projektu:    Natalia Bubakova (xbubak01) a Alena Klimecká (xklime47)     */
/*   naposledy upravene: 2.5.2022                                                    */
/*                                                                                   */
/* ********************************************************************************* */

/* ********* len pre vyhnutie sa znovu-vytvoreniu pri opakovanom pusteni *********** */
drop table liek              CASCADE CONSTRAINTS;
drop table liek_na_predpis   CASCADE CONSTRAINTS;
drop table liek_bez_predpisu CASCADE CONSTRAINTS;
drop table pobocka           CASCADE CONSTRAINTS;
drop table poistovna         CASCADE CONSTRAINTS;
drop table mnozstvo          CASCADE CONSTRAINTS;
drop table vyska_prispevku   CASCADE CONSTRAINTS;
drop table vydany_liek       CASCADE CONSTRAINTS;

purge recyclebin;
/* ********************************************************************************* */


/* ********************** zakladne objekty schematu databaze *********************** */

/*  prva varianta implementacie specializacie pretoze typ lieku na predpis a bez predpisu sa prekryva  */
create table liek (
    ean_lieku varchar(13) check(regexp_like(ean_lieku,'^\d{13}$')) primary key,
    nazov varchar(255) not null unique,
    popis varchar(255),
    cena number(10,2) not null check(cena >= 0)
/*nutnost_predpisu varchar(11) check (nutnost_predpisu in ('na predpis','bez predpis')), ** asi skor pre tretiu variantu **/
);

create table liek_na_predpis (
    ean_lieku_na_predpis varchar(13) primary key references liek(ean_lieku)
);

create table liek_bez_predpisu (
    ean_lieku_bez_predpisu varchar(13) primary key references liek(ean_lieku)
);


create table pobocka (
    id_pobocky int generated by default as identity(start with 1 increment by 1) primary key,
    adresa varchar(255) not null check(regexp_like(adresa, '^\w+(\s\S+)*\s\d+(\/\d+)?\,?\s\w+(\s\w+)*\,?\s\d{5}$')) unique, -- ulica cislo[/cislo][,] mesto[,] psc
/*ulica varchar(255) not null, mesto varchar(255) not null, psc int check(length(psc) = 5) not null, ** keby s tym potrebujeme pracovat **/
    telefon varchar(13) not null check(regexp_like(telefon,'^\+\d{12}$'))
);

create table mnozstvo (
    ean_lieku varchar(13),
    id_pobocky int,
    mnozstvo int not null check(mnozstvo >= 0),
    primary key (ean_lieku, id_pobocky),
    foreign key (ean_lieku) references liek(ean_lieku),
    foreign key (id_pobocky) references pobocka(id_pobocky)
);

create table poistovna (
    kod_poistovne varchar(3) check(regexp_like(kod_poistovne,'^\d{3}$')) primary key,
    nazov varchar(255) not null unique,
    email varchar(255) not null check(regexp_like(email,'^\S+\@\w+\.\w{2,3}$')), -- jozko_mrkva@gmail.com
    telefon varchar(13) not null check(regexp_like(telefon,'^\+\d{12}$'))        -- +420123456789
);

create table vyska_prispevku (
    ean_lieku varchar(13),
    kod_poistovne varchar(3),
    vyska_prispevku number(10,2) not null check(vyska_prispevku >= 0),
    vysledna_cena_lieku number(10,2) not null check(vysledna_cena_lieku >= 0),
    primary key (ean_lieku, kod_poistovne),
    foreign key (ean_lieku) references liek(ean_lieku),
    foreign key (kod_poistovne) references poistovna(kod_poistovne)
);

create table vydany_liek (
    id_vydaneho_lieku int generated by default as identity primary key,
    datum_vydania date not null,
    ean_lieku_bez_predpisu varchar(13) references liek_bez_predpisu(ean_lieku_bez_predpisu),
    ean_lieku_na_predpis varchar(13) references liek_na_predpis(ean_lieku_na_predpis),      -- vydany bud na predpis alebo bez predpisu
    constraint check_with_or_without check ((ean_lieku_bez_predpisu is null or ean_lieku_na_predpis is null) and (not (ean_lieku_bez_predpisu is null and ean_lieku_na_predpis is null))),
    kod_poistovne varchar(3) references poistovna(kod_poistovne),      -- zavislost poistovne na lieku_na_predpis
    constraint check_with_and_ins check ((kod_poistovne is null and ean_lieku_na_predpis is null) or (not(kod_poistovne is null and ean_lieku_na_predpis is null))),
    id_pobocky int not null references pobocka(id_pobocky)
);

/* Trigger 
CREATE OR REPLACE TRIGGER liek_trigger
    AFTER INSERT
    ON LIEK
    FOR EACH ROW
BEGIN
    IF :new.LIEK.mnozstvo < 0
    THEN
        RAISE_APPLICATION_ERROR(-20000, 'Je potřeba přiobjednat lék!');
    END IF;
end;
*/

insert into liek values ('8595116523847','Paralen 500', null, 50.00);
insert into liek values ('3664798033953', 'Ibalgin 400', null, 85.00);
insert into liek values ('7612076354814', 'EXCIPIAL U LIPOLOTIO', 'EXCIPIAL U LIPOLOTIO 40MG/ML kožní podání emulze 200ML', 159.00);
insert into liek values ('8584055999424','Elocom', 'ELOCOM je kortizónový hormonálny liek určený na aplikáciu na kožu.', 110.00);

insert into liek_bez_predpisu select ean_lieku from liek where nazov='Paralen 500';
insert into liek_bez_predpisu values ('3664798033953');
insert into liek_bez_predpisu values ('7612076354814');

insert into liek_na_predpis values ('7612076354814');
insert into liek_na_predpis values ('8584055999424');

insert into pobocka values (default, 'Bašty 413/2, Brno, 62100', '+420541226066');
insert into pobocka values (default, 'Nádražní 595, Brno, 60200', '+420542211283');

insert into mnozstvo values ('8595116523847', 1, 63);
insert into mnozstvo values ('8595116523847', 2, 55);
insert into mnozstvo values ('3664798033953', 1, 21);
insert into mnozstvo values ('3664798033953', 2, 13);
insert into mnozstvo values ('7612076354814', 1, 27);
insert into mnozstvo values ('7612076354814', 2, 16);
insert into mnozstvo values ('8584055999424', 1, 8);
insert into mnozstvo values ('8584055999424', 2, 6);

insert into poistovna values ('111', 'Všeobecná zdravotní pojišťovna', 'info@vzp.cz', '+420952222222');
insert into poistovna values ('201', 'Vojenská zdravotní pojišťovna', 'posta@vozp.cz', '+420222929199');

insert into vyska_prispevku values ('7612076354814', '111', 52.47, 106.53);
insert into vyska_prispevku values ('7612076354814', '201', 55.42, 103.58);
insert into vyska_prispevku values ('8584055999424', '111', 61.83, 48.17);
insert into vyska_prispevku values ('8584055999424', '201', 67.33, 42.67);

insert into vydany_liek values (default, to_date('2021-06-06', 'YYYY-MM-DD'), '3664798033953', null, null, 1);
insert into vydany_liek values (default, to_date('2021-06-09', 'YYYY-MM-DD'), null, '8584055999424', '111', 1);
insert into vydany_liek values (default, to_date('2021-06-09', 'YYYY-MM-DD'), null, '8584055999424', '201', 2);
insert into vydany_liek values (default, to_date('2021-06-13', 'YYYY-MM-DD'), null, '7612076354814', '111', 1);
insert into vydany_liek values (default, to_date('2021-06-13', 'YYYY-MM-DD'), null, '7612076354814', '111', 1);

/* ********************************** SELECT dotazy ********************************** */

/* 1) spojeni dvou tabulek */
/* Jaká je adresa poboček, které vydali lék dne 06.06.2021 */
SELECT P.adresa
FROM pobocka P, vydany_liek V
WHERE P.id_pobocky = V.id_pobocky AND V.datum_vydania = to_date('2021-06-06', 'YYYY-MM-DD');

/* 2) spojeni dvou tabulek */
/* Kolik kusů léku s EAN označením 3664798033953 má pobočka Nádražní 595, Brno, 60200 */
SELECT mnozstvo
FROM pobocka NATURAL JOIN mnozstvo
WHERE ean_lieku = '3664798033953' AND adresa = 'Nádražní 595, Brno, 60200';

/* 3) spojeni tří tabulek */
/* Jaká je víše přízpěvku pojišťoven na lék EXCIPIAL U LIPOLOTIO */
SELECT P.kod_poistovne, P.nazov, V.vyska_prispevku
FROM poistovna P, liek L, vyska_prispevku V
WHERE P.kod_poistovne = V.kod_poistovne AND V.ean_lieku = L.ean_lieku AND L.nazov = 'EXCIPIAL U LIPOLOTIO';

/* 4) klauzule GROUP BY a agregační funkce */
/* Kolik léků bylo vydáno v jaké dny */
SELECT datum_vydania, COUNT(*)
FROM vydany_liek
GROUP BY datum_vydania;

/* 5) klauzule GROUP BY a agregační funkce */
/* Kolik kusů jednotlivých léku vlastní firma dohromady(na všech pobočkách) */
SELECT L.nazov, SUM(mnozstvo)
FROM liek L, mnozstvo M
WHERE L.ean_lieku=M.ean_lieku
GROUP BY L.nazov;

/* 6) predikát EXISTS */
/* Které léky jsou na skladě jen na pobočce Bašty 413/2, Brno, 62100 */
SELECT L.nazov
FROM liek L, mnozstvo M, pobocka P
WHERE L.ean_lieku = M.ean_lieku AND M.id_pobocky=P.id_pobocky
AND adresa='Bašty 413/2, Brno, 62100'
AND NOT EXISTS 
    (SELECT * 
    FROM pobocka P, mnozstvo M
    WHERE M.id_pobocky=P.id_pobocky AND L.ean_lieku = M.ean_lieku
    AND adresa<>'Bašty 413/2, Brno, 62100');

/* 7) predikát IN s vnořeným selectem */
/* Kterých druhů léků je na pobočkách dohromady více než 50ks */
SELECT nazov
FROM liek
WHERE ean_lieku IN
    (SELECT L.ean_lieku
    FROM liek L, mnozstvo M
    WHERE L.ean_lieku=M.ean_lieku
    GROUP BY L.ean_lieku
    HAVING SUM(mnozstvo) > 50);


/* ********************** pokrocile objekty schematu databaze *********************** */

/* procedury */

-- procedura vypise kolko kusov lieku sa nachadza na danej pobocke spomedzi vsetkych
-- ak dany liek uz nie je nikde na sklade, upozorni na to
CREATE OR REPLACE PROCEDURE liek_na_sklade(arg_id_pobocky IN INT, arg_ean_lieku IN VARCHAR) AS
BEGIN
    DECLARE CURSOR cursor_mnozstvo_liekov IS
        SELECT M.id_pobocky, M.ean_lieku, M.mnozstvo
        FROM mnozstvo M;
    id_pobocky mnozstvo.id_pobocky%TYPE;
    ean_lieku  mnozstvo.ean_lieku%TYPE;
    pocet_ks   mnozstvo.mnozstvo%TYPE;
    pocet_ks_na_pobocke INT;
    celkovy_pocet_ks    INT;
    BEGIN
        celkovy_pocet_ks := 0;
        pocet_ks_na_pobocke := 0;
        OPEN cursor_mnozstvo_liekov;
        LOOP
            FETCH cursor_mnozstvo_liekov INTO id_pobocky, ean_lieku, pocet_ks;
            EXIT WHEN cursor_mnozstvo_liekov%NOTFOUND;
            IF arg_ean_lieku = ean_lieku THEN
                IF arg_id_pobocky = id_pobocky THEN
                    pocet_ks_na_pobocke := pocet_ks_na_pobocke + pocet_ks;
                END IF;
                celkovy_pocet_ks := celkovy_pocet_ks + pocet_ks;
            END IF;
        END LOOP;
        CLOSE cursor_mnozstvo_liekov;
        IF celkovy_pocet_ks = 0 THEN
            DBMS_OUTPUT.put_line('Liek ' || arg_ean_lieku || ' nie je na sklade' );
        ELSE
            DBMS_OUTPUT.put_line('Na pobočke (' || arg_id_pobocky || ') sa nachádza ' || pocet_ks_na_pobocke || ' z ' || celkovy_pocet_ks || ' ks');
        END IF;
    END;
END;

CALL liek_na_sklade(1, '8595116523847');
CALL liek_na_sklade(2, '8595116523847');



CREATE OR REPLACE PROCEDURE export_vykazov_pre_poistovnu (arg_kod_poistovne IN VARCHAR) AS
BEGIN
    DECLARE CURSOR cursor_lieky_na_poistovnu IS
        SELECT V.ean_lieku_na_predpis, V.id_vydaneho_lieku, V.datum_vydania, P.vyska_prispevku, P.kod_poistovne
        FROM vydany_liek V, vyska_prispevku P
        WHERE ( V.ean_lieku_na_predpis = P.ean_lieku ) AND ( V.kod_poistovne = P.kod_poistovne );
    ean_lieku           vydany_liek.ean_lieku_na_predpis%TYPE;
    id_vydaneho_lieku   vydany_liek.id_vydaneho_lieku%TYPE;
    datum_vydania       vydany_liek.datum_vydania%TYPE;
    vyska_prispevku     vyska_prispevku.vyska_prispevku%TYPE;
    kod_poistovne       vyska_prispevku.kod_poistovne%TYPE;
    pocet_liekov        INT;
    sucet_prispevku     NUMBER;
    tmp_vyska_prispevku NUMBER;
    tmp_ean_lieku       VARCHAR;
    BEGIN
        pocet_liekov := 0;
        sucet_prispevku := 0;
        tmp_vyska_prispevku := 0;
        tmp_ean_lieku := '';
        OPEN cursor_lieky_na_poistovnu;
        LOOP
            FETCH cursor_lieky_na_poistovnu INTO ean_lieku, id_vydaneho_lieku, datum_vydania, vyska_prispevku, kod_poistovne;
            EXIT WHEN cursor_lieky_na_poistovnu%NOTFOUND;
            IF arg_kod_poistovne = kod_poistovne THEN
                IF tmp_ean_lieku = ean_lieku THEN
                    tmp_vyska_prispevku := vyska_prispevku;
                    pocet_liekov := pocet_liekov + 1;
                    sucet_prispevku := sucet_prispevku + vyska_prispevku;
                ELSE
                    DBMS_OUTPUT.put_line('=> Z lieku typu ' || tmp_ean_lieku || ' s príspevkom vo výške' || tmp_vyska_prispevku || 'bolo vydaných' || pocet_liekov || 'ks; celková úhrada: ' || sucet_prispevku || ' Kč');
                    tmp_ean_lieku := ean_lieku;
                    pocet_liekov := 1;
                    sucet_prispevku := vyska_prispevku;
                    DBMS_OUTPUT.put_line( '================================================' );
                    DBMS_OUTPUT.put_line( 'EAN_LIEKU :   id_vydaneho_lieku  datum_vydania' );
                END IF;
                DBMS_OUTPUT.put_line( tmp_ean_lieku || ' :   ' || id_vydaneho_lieku || '  ' || datum_vydania );
            END IF;
        END LOOP;
        CLOSE cursor_lieky_na_poistovnu;
    END;
END;

CALL export_vykazov_pre_poistovnu ('111');
CALL export_vykazov_pre_poistovnu ('201');



/* EXPLAIN PLAN */
-- bez pouziti indexu
EXPLAIN PLAN FOR
SELECT L.nazov, SUM(mnozstvo)
FROM liek L, mnozstvo M
WHERE L.ean_lieku=M.ean_lieku
GROUP BY L.nazov;

SELECT plan_table_output FROM TABLE(dbms_xplan.display());

-- s pouzitim indexu
CREATE INDEX liek_index ON liek (ean_lieku, nazov, popis, cena);
CREATE INDEX mnozstvo_index ON mnozstvo (ean_lieku, id_pobocky, mnozstvo);

EXPLAIN PLAN FOR
SELECT L.nazov, SUM(mnozstvo)
FROM liek L, mnozstvo M
WHERE L.ean_lieku=M.ean_lieku
GROUP BY L.nazov;

SELECT plan_table_output FROM TABLE(dbms_xplan.display());

DROP INDEX liek_index;
DROP INDEX mnozstvo_index;





/* materializovany pohlad */

DROP MATERIALIZED VIEW vydany_na_pobocke;

-- log zmien v tabulkach materializovaneho pohladu -> umoznuje FAST REFRESH
CREATE MATERIALIZED VIEW LOG ON pobocka WITH PRIMARY KEY, ROWID;
CREATE MATERIALIZED VIEW LOG ON vydany_liek WITH PRIMARY KEY, ROWID;
CREATE MATERIALIZED VIEW LOG ON liek WITH PRIMARY KEY, ROWID;

-- vypise vydane lieky pre kazdu z pobociek
CREATE MATERIALIZED VIEW vydany_na_pobocke
NOLOGGING
CACHE
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
ENABLE QUERY REWRITE AS
    SELECT P.id_pobocky, P.adresa, L.nazov, L.ean_lieku, V.id_vydaneho_lieku, V.datum_vydania, P.ROWID AS rowid_pobocky, V.ROWID AS rowid_vyd_lieku, L.ROWID AS rowid_lieku
    FROM pobocka P, vydany_liek V, liek L                                                        -- alternativa k JOINu aby fungoval REFRESH ON COMMIT
    WHERE P.id_pobocky = V.id_pobocky AND ( V.ean_lieku_bez_predpisu = L.ean_lieku OR V.ean_lieku_na_predpis = L.ean_lieku);

-- select na vypis materializovaneho pohladu pred updatom
SELECT * FROM vydany_na_pobocke;

INSERT INTO vydany_liek VALUES (DEFAULT, TO_DATE('2021-06-08', 'YYYY-MM-DD'), '3664798033953', NULL, '111', 1);
INSERT INTO vydany_liek VALUES (DEFAULT, TO_DATE('2021-06-08', 'YYYY-MM-DD'), '8595116523847', NULL, '111', 1);
INSERT INTO vydany_liek VALUES (DEFAULT, TO_DATE('2021-06-12', 'YYYY-MM-DD'), '7612076354814', NULL, '111', 2);
INSERT INTO vydany_liek VALUES (DEFAULT, TO_DATE('2021-06-09', 'YYYY-MM-DD'), '7612076354814', NULL, '201', 1);
INSERT INTO vydany_liek VALUES (DEFAULT, TO_DATE('2021-06-12', 'YYYY-MM-DD'), '8595116523847', NULL, '201', 2);
INSERT INTO vydany_liek VALUES (DEFAULT, TO_DATE('2021-06-13', 'YYYY-MM-DD'), '8595116523847', NULL, '201', 2);

COMMIT;

SELECT adresa, nazov, ean_lieku, id_vydaneho_lieku, datum_vydania       -- prehladne zobrazenie, pretoze pri priebeznom refreshi to nejde napr. ani zoradit
FROM vydany_na_pobocke
ORDER BY id_pobocky ASC, datum_vydania, nazov;                          -- zoradi po skupinkach pobociek, a medzi nimi podla datumu a typu lieku



/* definicia pristupovych prav */

GRANT ALL ON liek               TO xklime47;
GRANT ALL ON liek_na_predpis    TO xklime47;
GRANT ALL ON liek_bez_predpisu  TO xklime47;
GRANT ALL ON liek_bez_predpisu  TO xklime47;
GRANT ALL ON pobocka            TO xklime47;
GRANT ALL ON poistovna          TO xklime47;
GRANT ALL ON mnozstvo           TO xklime47;
GRANT ALL ON vyska_prispevku    TO xklime47;
GRANT ALL ON vydany_liek        TO xklime47;

GRANT EXECUTE ON liek_na_sklade    TO xklime47;
-- GRANT EXECUTE ON procedure_2    TO xklime47;

GRANT ALL ON vydany_na_pobocke  TO xklime47;


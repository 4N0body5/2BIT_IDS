/* ********************************************************************************* */
/*                                                                                   */
/*   nazov projektu:     IDS - 3.cast; Zadanie c.33 -Lekarna                         */
/*   autori projektu:    Natalia Bubakova (xbubak01) a Alena Klimecka (xklime47)     */
/*   naposledy upravene: 16.4.2022                                                   */
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
/* ********************************************************************************* */

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
    kod_pobocky int not null references pobocka(id_pobocky)
);

insert into liek values ('8595116523847','Paralen 500', null, 50.00);
insert into liek values ('3664798033953', 'Ibalgin 400', null, 85.00);
insert into liek values ('7612076354814', 'EXCIPIAL U LIPOLOTIO', 'EXCIPIAL U LIPOLOTIO 40MG/ML ko�n� pod�n� emulze 200ML', 159.00);
insert into liek values ('8584055999424','Elocom', 'ELOCOM je kortiz�nov� hormon�lny liek ur�en� na aplik�ciu na ko�u.', 110.00);

insert into liek_bez_predpisu select ean_lieku from liek where nazov='Paralen 500';
insert into liek_bez_predpisu values ('3664798033953');
insert into liek_bez_predpisu values ('7612076354814');

insert into liek_na_predpis values ('7612076354814');
insert into liek_na_predpis values ('8584055999424');

insert into pobocka values (default, 'Ba�ty 413/2, Brno, 62100', '+420541226066');
insert into pobocka values (default, 'N�dra�n� 595, Brno, 60200', '+420542211283');

insert into mnozstvo values ('8595116523847', 1, 63);
insert into mnozstvo values ('8595116523847', 2, 55);
insert into mnozstvo values ('3664798033953', 1, 21);
insert into mnozstvo values ('3664798033953', 2, 13);
insert into mnozstvo values ('7612076354814', 2, 16);
insert into mnozstvo values ('8584055999424', 1, 8);

insert into poistovna values ('111', 'V�eobecn� zdravotn� poji��ovna', 'info@vzp.cz', '+420952222222');
insert into poistovna values ('201', 'Vojensk� zdravotn� poji��ovna', 'posta@vozp.cz', '+420222929199');

insert into vyska_prispevku values ('7612076354814', '111', 52.47, 106.53);
insert into vyska_prispevku values ('7612076354814', '201', 55.42, 103.58);
insert into vyska_prispevku values ('8584055999424', '111', 61.83, 48.17);
insert into vyska_prispevku values ('8584055999424', '201', 67.33, 42.67);

insert into vydany_liek values (default, to_date('2021-06-06', 'YYYY-MM-DD'), '3664798033953', null, null, 1);
insert into vydany_liek values (default, to_date('2021-06-09', 'YYYY-MM-DD'), null, '8584055999424', '111', 1);
insert into vydany_liek values (default, to_date('2020-06-09', 'YYYY-MM-DD'), null, '8584055999424', '111', 2);

/* ********* SELECT dotazy *********** */

/* 1) spojeni dvou tabulek */
/* Jak� je adresa pobo�ek, kter� vydali l�k dne 06.06.2021 */
SELECT P.adresa
FROM pobocka P, vydany_liek V
WHERE P.id_pobocky = V.kod_pobocky AND V.datum_vydania = to_date('2021-06-06', 'YYYY-MM-DD');

/* 2) spojeni dvou tabulek */
/* Kolik kus� l�ku s EAN ozna�en�m 3664798033953 m� pobo�ka N�dra�n� 595, Brno, 60200 */
SELECT mnozstvo
FROM pobocka NATURAL JOIN mnozstvo
WHERE ean_lieku = '3664798033953' AND adresa = 'N�dra�n� 595, Brno, 60200';

/* 3) spojeni t�� tabulek */
/* Jak� je v��e p��zp�vku poji��oven na l�k EXCIPIAL U LIPOLOTIO */
SELECT P.kod_poistovne, P.nazov, V.vyska_prispevku
FROM poistovna P, liek L, vyska_prispevku V
WHERE P.kod_poistovne = V.kod_poistovne AND V.ean_lieku = L.ean_lieku AND L.nazov = 'EXCIPIAL U LIPOLOTIO';

/* 4) klauzule GROUP BY a agrega�n� funkce */
/* Kolik l�k� bylo vyd�no v jak� dny */
SELECT datum_vydania, COUNT(*)
FROM vydany_liek
GROUP BY datum_vydania;

/* 5) klauzule GROUP BY a agrega�n� funkce */
/* Kolik kus� jednotliv�ch l�ku vlastn� firma dohromady(na v�ech pobo�k�ch) */
SELECT L.nazov, SUM(mnozstvo)
FROM liek L, mnozstvo M
WHERE L.ean_lieku=M.ean_lieku
GROUP BY L.nazov;

/* 6) predik�t EXISTS */
/* Kter� l�ky jsou na sklad� jen na pobo�ce Ba�ty 413/2, Brno, 62100 */
SELECT L.nazov
FROM liek L, mnozstvo M, pobocka P
WHERE L.ean_lieku = M.ean_lieku AND M.id_pobocky=P.id_pobocky
AND adresa='Ba�ty 413/2, Brno, 62100'
AND NOT EXISTS 
    (SELECT * 
    FROM pobocka P, mnozstvo M
    WHERE M.id_pobocky=P.id_pobocky AND L.ean_lieku = M.ean_lieku
    AND adresa<>'Ba�ty 413/2, Brno, 62100');

/* 7) predik�t IN s vno�en�m selectem */
/* Kter�ch druh� l�k� je na pobo�k�ch dohromady v�ce ne� 50ks */
SELECT nazov
FROM liek
WHERE ean_lieku IN
    (SELECT L.ean_lieku
    FROM liek L, mnozstvo M
    WHERE L.ean_lieku=M.ean_lieku
    GROUP BY L.ean_lieku
    HAVING SUM(mnozstvo) > 50);


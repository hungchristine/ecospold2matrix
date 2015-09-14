-- ==================================================
-- TEMPORARY TABLES TO FACILITATE INPUT OF DATA
-- ==================================================

DROP table if exists raw_recipe;

CREATE TABLE raw_recipe(
id           INTEGER NOT NULL PRIMARY KEY,
comp         TEXT,
subcomp      TEXT,
name        TEXT,
name2        TEXT,
cas          TEXT    CHECK (cas NOT LIKE '0%'),
tag          TEXT,
unit         TEXT,
impactId     TEXT,
factorValue  REAL,
substId      INTEGER,
UNIQUE(comp, subcomp, name, name2, cas, unit, impactId)
);

DROP TABLE IF EXISTS raw_ecoinvent;
CREATE TABLE raw_ecoinvent(
ecorawId    SERIAL  NOT NULL PRIMARY KEY,
substId     INTEGER,
name        TEXT    NOT NULL,
name2       TEXT    ,
tag         TEXT    DEFAULT NULL,
comp        TEXT    NOT NULL,
subcomp     TEXT    ,
unit        TEXT    ,
cas         text    CHECK (cas NOT LIKE '0%')
);


--=================================================
-- KEY TABLES
--=================================================

DROP TABLE IF EXISTS substances;
CREATE TABLE substances(
substId     INTEGER NOT NULL PRIMARY KEY,
formula     TEXT,
cas         text    CHECK (cas NOT LIKE '0%'),
tag         TEXT    DEFAULT NULL,
aName       text,
CONSTRAINT uniqueSubstanceCas UNIQUE(cas, tag),
	-- ensure no cas conflict
CONSTRAINT namePerSubstance UNIQUE(aName, tag)
	-- though mostly for readability, aName still used in matching
	-- ensure no name conflict
);

DROP TABLE IF EXISTS schemes;
CREATE TABLE schemes(
SchemeId    INTEGER     NOT NULL    PRIMARY KEY ,
name        TEXT        NOT NULL    UNIQUE
);

DROP TABLE IF EXISTS Names;
CREATE TABLE Names(
nameId      INTEGER NOT NULL    PRIMARY KEY,
name        TEXT    NOT NULL,
tag	    TEXT,
substId	    TEXT    REFERENCES substances,
UNIQUE(NAME, tag),  --enforce a many-to-1 relation between name and substid
UNIQUE(NAME, tag, substId)  --enforce a many-to-1 relation between name and substid
);

DROP TABLE IF EXISTS nameHasScheme;
CREATE TABLE nameHasScheme(
nameId      INTEGER NOT NULL    REFERENCES names,
schemeId    INTEGER NOT NULL    REFERENCES schemes,
UNIQUE(nameId, schemeId)
);

DROP TABLE IF EXISTS comp;
CREATE TABLE comp(
compName    TEXT    PRIMARY KEY
);

DROP TABLE IF EXISTS subcomp;
CREATE TABLE subcomp(
subcompName TEXT    PRIMARY KEY,
parentcomp  TEXT    REFERENCES comp(compName)
);

-- elementary flow tables (named observed flows for no good reason)
DROP TABLE IF EXISTS observedflows;
CREATE TABLE observedflows(
id          INTEGER     NOT NULL PRIMARY KEY,
elflow_id   integer     UNIQUE,
substId     INTEGER     NOT NULL REFERENCES substances,
comp        TEXT        NOT NULL references comp,
subcomp     TEXT        references subcomp,
ardaId      integer     UNIQUE,
CONSTRAINT uniqueFlow UNIQUE(elflow_id, substId, comp, subcomp)
);

drop table if exists old_labels;
create table old_labels(
oldid       INTEGER NOT NULL  primary key,
fullname    text,
ardaid      integer not null,
name        text not null,
dsid        integer not null,
infrastructure  text,
location    text,
comp        text,
subcomp     text,
unit        text ,
covered_before  boolean not null,
covered_new boolean default false
);

DROP TABLE IF EXISTS impacts;
CREATE TABLE impacts (
impactId        TEXT    PRIMARY KEY,
long_name       TEXT    ,
scope           text    ,
perspective     text    not null,
unit            TEXT    not null,
referenceSubstId    INTEGER --REFERENCES substances(substId)    
);

DROP TABLE IF EXISTS factors;
CREATE TABLE factors(
factorId    INTEGER     NOT NULL PRIMARY KEY,
substId     integer     NOT NULL REFERENCES substances,
comp        text        NOT NULL REFERENCES comp(compName),
subcomp     text                 REFERENCES subcomp(subcompName),
unit        text        NOT NULL,
impactId    TEXT        NOT NULL     REFERENCES impacts,
method      TEXT,
factorValue double precision    not null,
UNIQUE (substId, comp, subcomp, impactId,  method)
);

DROP TABLE IF EXISTS labels_ecoinvent;
CREATE TABLE labels_ecoinvent(
ecorawId    SERIAL  NOT NULL PRIMARY KEY,
substId     INTEGER REFERENCES substances,
name        TEXT    NOT NULL references names(name),
tag         TEXT    DEFAULT NULL,
comp        TEXT    NOT NULL references comp(compName),
subcomp     TEXT    references subcomp(subcompName),
formula     TEXT    ,
unit        TEXT    ,
cas         text    CHECK (cas NOT LIKE '0%'),
dsid        integer,
name2       TEXT    references names(name)
-- Cannot put uniqueness constraints, data in a mess
-- name and name2 cannot reference names(name) because no unique constraint
);


DROP TABLE IF EXISTS labels;
CREATE table labels(
labelId     INTEGER NOT NULL PRIMARY KEY,
substId     INTEGER,
comp        TEXT    references comp(compName),
subcomp     TEXT    references subcomp(subcompName),
name        TEXT,
name2       TEXT,
cas         text    CHECK (cas NOT LIKE '0%'),
tag         TEXT,
unit        TEXT
-- Cannot put uniqueness constraints, data in a mess
);

--==========================================
-- MATCHING ELEMENTARY FLOWS ANC CHAR FACTORS
--===========================================

-- Define the "default" subcompartment amongst all the
-- subcompartments of a parent compartment. Useful for
-- characterisation methods that do not define factors for the parent
-- compartment (i.e. no "unspecified" subcompartment).

DROP TABLE IF EXISTS fallback_sc;
CREATE TABLE fallback_sc(
comp    TEXT    not null    REFERENCES comp, 
subcomp TEXT    not null    REFERENCES subcomp,
method  TEXT
);

--  Table for matching the "observed" (best estimate) subcompartment
--  with the best fitting comp/subcompartment of characterisation
--  method

--  Kind of like the "proxy table" of
--  elementaryflow/characterisation factors. Could maybe find a
--  better name.

DROP TABLE IF EXISTS obs2char_subcomps;
CREATE TABLE obs2char_subcomps(
obs2charId  INTEGER NOT NULL    primary key,
comp        text    not null    ,
	--references comp(compName),--REFERENCES comp,
obs_sc      text    not null    ,
    --references subcomp(subcompName), -- observed subcomp
char_sc     text    not null    ,
	    --references subcomp(subcompName),
	    -- best match for a characterised subcomp
scheme      TEXT    ,
UNIQUE(comp, obs_sc, scheme)
);

DROP TABLE IF EXISTS obs2char;
CREATE TABLE obs2char(
obsflowId   INTEGER,
impactId    text    not null,
factorId    int not null,
factorValue double precision    not null,
scheme      TEXT,
UNIQUE(obsflowId, impactId, scheme)
);

--====================================
-- TEMPORARY TABLES
--====================================



-- DROP TABLE IF EXISTS synonyms;
-- CREATE TABLE synonyms(
--     rawId   INTEGER,
--     tag     TEXT,
--     name   TEXT,
--     name2   TEXT,
--     unit    text
-- );

-- DROP TABLE IF EXISTS tempNamesWithoutCas;
-- CREATE TABLE tempNamesWithoutCas(
--     rawId INTEGER,
--     tag TEXT,
--     name TEXT,
--     name2 TEXT,
--     unit    text
-- );

-- DROP TABLE IF EXISTS singles;
-- CREATE TABLE singles(
--     rawId   INTEGER,
--     tag TEXT,
--     name    TEXT,
--     unit    text
-- );



DROP Table IF EXISTS bad;
CREATE TABLE bad(
sparseId        INTEGER REFERENCES sparse_factors,
substId         INTEGER DEFAULT NULL ,
comp            TEXT    ,
subcomp         TEXT    ,
unit            TEXT    ,
factorValue double precision,
impactId    TEXT
);

DROP TABLE IF EXISTS sparse_factors;
CREATE TABLE sparse_factors(
sparseId        INTEGER  PRIMARY KEY NOT NULL,
substId         INTEGER     DEFAULT NULL ,
comp            TEXT    ,
subcomp         TEXT    ,
unit            TEXT    ,
factorValue     double precision,
impactId        TEXT
);


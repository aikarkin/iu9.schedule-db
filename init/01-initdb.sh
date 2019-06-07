#!/bin/bash

#!/bin/bash
set -e;

echo "logged as $(whoami)";
echo "";

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE bmstu_schedule WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';
    ALTER DATABASE bmstu_schedule OWNER TO admin;

    \connect bmstu_schedule

    CREATE TABLE "subject"
    (
      subject_id   SERIAL PRIMARY KEY,
      subject_name TEXT NOT NULL
    );

    CREATE TABLE class_type
    (
      "type_id"   SERIAL PRIMARY KEY,
      "type_name" TEXT NOT NULL,
      UNIQUE ("type_name")
    );

    CREATE TABLE classroom
    (
      room_id     SERIAL PRIMARY KEY,
      room_number VARCHAR(10) NOT NULL,
      capacity    INTEGER CHECK (capacity >= 0),
      UNIQUE (room_number)
    );

    CREATE TABLE lecturer
    (
      lecturer_id    SERIAL PRIMARY KEY,
      lecturer_email TEXT,
      first_name     TEXT NOT NULL,
      middle_name    TEXT NOT NULL,
      last_name      TEXT NOT NULL,
      edu_degree     TEXT
    );

    CREATE TABLE day_of_weak
    (
      weak_id     SERIAL PRIMARY KEY,
      short_title CHAR(3),
      full_title  CHAR(12) NOT NULL,
      UNIQUE (full_title),
      UNIQUE (short_title)
    );

    CREATE TABLE class_time
    (
      class_time_id SERIAL PRIMARY KEY,
      no_of_class   INTEGER NOT NULL,
      starts_at     time    NOT NULL,
      ends_at       time    NOT NULL,
      UNIQUE (starts_at, ends_at),
      CHECK (starts_at < ends_at)
    );


    CREATE TABLE term
    (
      term_id SERIAL PRIMARY KEY,
      term_no INTEGER NOT NULL CHECK (term_no > 0)
    );

    CREATE TABLE edu_degree
    (
      degree_id                 SERIAL PRIMARY KEY,
      degree_name               TEXT    NOT NULL,
      min_number_of_study_years INTEGER NOT NULL CHECK (min_number_of_study_years > 0),
      UNIQUE (degree_name)
    );

    CREATE TABLE faculty
    (
      faculty_id     SERIAL PRIMARY KEY,
      faculty_cipher CHAR(8),
      title          TEXT NOT NULL,
      UNIQUE (faculty_cipher)
    );

    CREATE TABLE department
    (
      department_id     SERIAL PRIMARY KEY,
      faculty_id        INTEGER REFERENCES faculty (faculty_id),
      department_number INTEGER NOT NULL CHECK (department_number > 0),
      title             TEXT    NULL
    );

    CREATE TABLE speciality
    (
      id        SERIAL PRIMARY KEY,
      code      CHAR(8) CHECK (char_length(code) = 8 AND code LIKE '%.%.%'),
      degree_id INTEGER REFERENCES edu_degree (degree_id),
      title     TEXT NOT NULL,
      UNIQUE (code)
    );

    CREATE TABLE specialization
    (
      id                   SERIAL PRIMARY KEY,
      speciality_id        INTEGER REFERENCES speciality (id),
      number_in_speciality INT,
      title                TEXT NOT NULL,
      UNIQUE (speciality_id, number_in_speciality)
    );


    CREATE TABLE department_to_specialization
    (
      id                SERIAL PRIMARY KEY,
      department_id     INTEGER REFERENCES department (department_id),
      specialization_id INTEGER REFERENCES specialization (id)
    );

    CREATE TABLE department_subject
    (
      id            SERIAL PRIMARY KEY,
      department_id INTEGER REFERENCES department (department_id),
      subject_id    INTEGER REFERENCES subject (subject_id),
      UNIQUE (department_id, subject_id)
    );

    CREATE TABLE lecturer_subject
    (
      id                       SERIAL PRIMARY KEY,
      lecturer_id              INTEGER REFERENCES lecturer (lecturer_id),
      subject_on_department_id INTEGER REFERENCES department_subject (id),
      class_type_id            INTEGER REFERENCES class_type (type_id),
      UNIQUE (lecturer_id, subject_on_department_id, class_type_id)
    );

    CREATE TABLE calendar
    (
      id              SERIAL PRIMARY KEY,
      dept_to_spec_id INTEGER REFERENCES department_to_specialization (id),
      start_year      INTEGER NOT NULL CHECK (start_year > 1900 AND start_year < 2100),
      UNIQUE (dept_to_spec_id, start_year)
    );


    CREATE TABLE study_group
    (
      group_id       SERIAL PRIMARY KEY,
      calendar_id    INTEGER REFERENCES calendar (id),
      term_id        INTEGER REFERENCES term (term_id),
      group_number   INTEGER NOT NULL CHECK (group_number > 0),
      students_count INTEGER,
      UNIQUE (calendar_id, term_id, group_number)
    );

    CREATE TABLE schedule_day
    (
      day_id   SERIAL PRIMARY KEY,
      weak_id  INTEGER REFERENCES day_of_weak (weak_id),
      group_id INTEGER REFERENCES study_group (group_id),
      UNIQUE (weak_id, group_id)
    );

    CREATE TABLE schedule_item
    (
      schedule_item_id SERIAL PRIMARY KEY,
      day_id           INTEGER REFERENCES schedule_day (day_id),
      class_time_id    INTEGER REFERENCES class_time (class_time_id),
      UNIQUE (day_id, class_time_id)
    );

    CREATE TABLE schedule_item_parity
    (
      schedule_item_parity_id SERIAL PRIMARY KEY,
      schedule_item_id        INTEGER REFERENCES schedule_item (schedule_item_id),
      day_parity              CHAR(5)
        CHECK (day_parity = 'ЧС' OR day_parity = 'ЗН' OR day_parity = 'ЧС/ЗН')
        DEFAULT 'ЧС/ЗН',
      classroom_id            INTEGER REFERENCES classroom (room_id),
      class_type_id           INTEGER REFERENCES class_type ("type_id"),
      lec_subj_id             INTEGER REFERENCES "lecturer_subject" (id),

      CONSTRAINT unq_cr UNIQUE (schedule_item_id, day_parity, classroom_id),
      CONSTRAINT unq_subj UNIQUE (schedule_item_id, day_parity, lec_subj_id),
      CONSTRAINT unq_cl_type UNIQUE (schedule_item_id, day_parity, class_type_id),
      CONSTRAINT unq_parity UNIQUE (schedule_item_id, day_parity)
    );


    CREATE TABLE calendar_item
    (
      calendar_item_id      SERIAL PRIMARY KEY,
      calendar_id           INTEGER REFERENCES calendar (id),
      department_subject_id INTEGER REFERENCES department_subject (id)
    );

    CREATE TABLE calendar_item_cell
    (
      cell_id          SERIAL PRIMARY KEY,
      calendar_item_id INTEGER REFERENCES calendar_item (calendar_item_id),
      term_id          INTEGER REFERENCES term (term_id),
      UNIQUE (calendar_item_id, term_id)
    );

    CREATE TABLE hours_per_class
    (
      hours_id         SERIAL PRIMARY KEY,
      calendar_cell_id INTEGER REFERENCES calendar_item_cell (cell_id),
      class_type_id    INTEGER REFERENCES class_type ("type_id"),
      no_of_hours      INTEGER NOT NULL CHECK (no_of_hours > 0),
      UNIQUE (calendar_cell_id, class_type_id)
    );
EOSQL
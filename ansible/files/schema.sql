-- schema.sql
-- Completely rebuilds the Tribal Enrollment Management System (TEMS) database.

-- Drop tables in reverse dependency order to avoid foreign key conflicts.
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS tribal_services CASCADE;
DROP TABLE IF EXISTS enrollment_status CASCADE;
DROP TABLE IF EXISTS members CASCADE;
DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS child_applications CASCADE;
DROP TABLE IF EXISTS adult_applications CASCADE;
DROP TABLE IF EXISTS users CASCADE;

---------------------------
-- 1) USERS TABLE
---------------------------
CREATE TABLE users (
    user_id       SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role          VARCHAR(20) NOT NULL DEFAULT 'Applicant',
    member_id     INTEGER,  -- Assigned later if already a member or upon approval
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

---------------------------
-- 2) ADULT APPLICATIONS TABLE
---------------------------
CREATE TABLE adult_applications (
    app_id                SERIAL PRIMARY KEY,
    user_id               INTEGER NOT NULL,
    mailing_address       VARCHAR(200),
    city                  VARCHAR(100),
    state                 VARCHAR(100),
    zip_code              VARCHAR(20),
    county                VARCHAR(100),
    spouse_name           VARCHAR(100),
    spouse_tribe          VARCHAR(100),
    birthdate             DATE,
    sex                   VARCHAR(10),
    ssn                   VARCHAR(20),
    marital_status        VARCHAR(20),
    member_of_other_tribe BOOLEAN NOT NULL DEFAULT FALSE,
    other_tribe_name      VARCHAR(150),
    family_in_sault_tribe BOOLEAN NOT NULL DEFAULT FALSE,
    family_name_rel       VARCHAR(150),
    phone_no              VARCHAR(20),
    citizenship           VARCHAR(50),
    children_info         TEXT,  -- Text summary of children if applicable
    status                VARCHAR(20) NOT NULL DEFAULT 'Pending',
    submitted_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_adult_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_adult_user ON adult_applications(user_id);
CREATE INDEX idx_adult_status ON adult_applications(status);

---------------------------
-- 3) CHILD APPLICATIONS TABLE
---------------------------
CREATE TABLE child_applications (
    child_app_id    SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL,   -- Parent/guardian who is applying
    child_name      VARCHAR(100) NOT NULL,
    child_birthdate DATE NOT NULL,
    child_sex       VARCHAR(10),
    child_other_tribe BOOLEAN NOT NULL DEFAULT FALSE,
    other_tribe_name VARCHAR(150),
    status          VARCHAR(20) NOT NULL DEFAULT 'Pending',
    submitted_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_child_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_child_user ON child_applications(user_id);
CREATE INDEX idx_child_status ON child_applications(status);

---------------------------
-- 4) DOCUMENTS TABLE
---------------------------
-- This table stores file references (e.g., MinIO object keys) for uploads.
CREATE TABLE documents (
    doc_id       SERIAL PRIMARY KEY,
    app_type     VARCHAR(10) NOT NULL,  -- 'adult' or 'child'
    app_id       INTEGER NOT NULL,      -- ID from adult_applications or child_applications
    doc_name     VARCHAR(255) NOT NULL,
    doc_path     VARCHAR(255) NOT NULL,
    uploaded_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_docs_app ON documents(app_type, app_id);

---------------------------
-- 5) MEMBERS TABLE
---------------------------
-- This table holds detailed membership records for approved members.
CREATE TABLE members (
    member_id           SERIAL PRIMARY KEY,
    user_id             INTEGER UNIQUE, -- Link to users table
    membership_status   VARCHAR(20) NOT NULL DEFAULT 'Active',
    expiration_date     DATE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_member_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

---------------------------
-- 6) ENROLLMENT STATUS TABLE
---------------------------
-- Tracks the outcome of an application.
CREATE TABLE enrollment_status (
    status_id    SERIAL PRIMARY KEY,
    app_id       INTEGER NOT NULL,  -- Reference to an application (adult or child)
    decision     VARCHAR(20) NOT NULL,  -- e.g., 'Approved', 'Denied', 'Pending'
    decision_date TIMESTAMP DEFAULT NOW(),
    comments     TEXT
);

---------------------------
-- 7) TRIBAL SERVICES TABLE
---------------------------
-- Lists services available to members.
CREATE TABLE tribal_services (
    service_id   SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    description  TEXT,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_services_name ON tribal_services(service_name);

---------------------------
-- 8) AUDIT LOGS TABLE
---------------------------
-- Logs system events, actions, and authentication attempts.
CREATE TABLE audit_logs (
    log_id       SERIAL PRIMARY KEY,
    user_id      INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    action       TEXT NOT NULL,
    log_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    ip_address   VARCHAR(50),
    details      JSONB
);

CREATE INDEX idx_audit_timestamp ON audit_logs(log_timestamp);

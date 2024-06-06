CREATE SCHEMA IF NOT EXISTS auth;

CREATE SEQUENCE IF NOT EXISTS auth.userid_seq;
CREATE SEQUENCE IF NOT EXISTS auth.roles_seq;

CREATE TABLE IF NOT EXISTS auth.users (
	id int4 DEFAULT NEXTVAL('auth.userid_seq') NOT NULL,
	display_name varchar(255) NOT NULL,
	email varchar(255) NULL,
    CONSTRAINT users_pk PRIMARY KEY(id)
);

CREATE TABLE IF NOT EXISTS auth.roles (
	id int4 DEFAULT NEXTVAL('auth.roles_seq') NOT NULL,
	role_name varchar(255) NOT NULL,
    CONSTRAINT roles_pk PRIMARY KEY(id)
);

CREATE TABLE IF NOT EXISTS auth.role_assignments (
    user_id int4 NOT NULL,
    role_id int4 NOT NULL,
    CONSTRAINT role_ass_pk PRIMARY KEY(user_id, role_id)
);

ALTER TABLE auth.role_assignments ADD CONSTRAINT role_ass_user_fk FOREIGN KEY (user_id) REFERENCES auth.users(id);
ALTER TABLE auth.role_assignments ADD CONSTRAINT role_ass_role_fk FOREIGN KEY (role_id) REFERENCES auth.roles(id);


CREATE TABLE IF NOT EXISTS auth.providers (
    id varchar(50) NOT NULL,
    app_id varchar(255) NULL,
    app_secret varchar(255) NULL,
    issuer_url varchar(1024) NULL,
    openid_info_url varchar (1024) NULL,
    auth_url varchar(1024) NULL,
    token_url varchar(1024) NULL,
    userinfo_url varchar(1024) NULL,
    CONSTRAINT provider_pk PRIMARY KEY(id)
);

CREATE TABLE IF NOT EXISTS auth.credentials (
    user_id int4 not null,
    login_name varchar(255) NOT NULL,
    provider varchar(50) NOT NULL,
    login_data varchar(1024) NULL,
    CONSTRAINT credentials_pk PRIMARY KEY(user_id, login_name, provider),
    CONSTRAINT credentials_provider_login_uniq UNIQUE (login_name, provider)
);
ALTER TABLE auth.credentials ADD CONSTRAINT credentials_users_fk FOREIGN KEY (user_id) REFERENCES auth.users(id);
ALTER TABLE auth.credentials ADD CONSTRAINT credentials_provider_fk FOREIGN KEY (provider) REFERENCES auth.providers(id);



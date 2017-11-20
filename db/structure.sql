--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: administrative_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE administrative_accounts (
    id integer NOT NULL,
    public_key character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: administrative_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE administrative_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: administrative_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE administrative_accounts_id_seq OWNED BY administrative_accounts.id;


--
-- Name: admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE admins (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admins_id_seq OWNED BY admins.id;


--
-- Name: auth_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE auth_tokens (
    id integer NOT NULL,
    user_id integer,
    value character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: auth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE auth_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE auth_tokens_id_seq OWNED BY auth_tokens.id;


--
-- Name: envelope_communities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE envelope_communities (
    id integer NOT NULL,
    name character varying NOT NULL,
    "default" boolean DEFAULT false NOT NULL,
    backup_item character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: envelope_communities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE envelope_communities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: envelope_communities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE envelope_communities_id_seq OWNED BY envelope_communities.id;


--
-- Name: envelope_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE envelope_transactions (
    id integer NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    envelope_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: envelope_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE envelope_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: envelope_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE envelope_transactions_id_seq OWNED BY envelope_transactions.id;


--
-- Name: envelopes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE envelopes (
    id integer NOT NULL,
    envelope_type integer DEFAULT 0 NOT NULL,
    envelope_version character varying NOT NULL,
    envelope_id character varying NOT NULL,
    resource text NOT NULL,
    resource_format integer DEFAULT 0 NOT NULL,
    resource_encoding integer DEFAULT 0 NOT NULL,
    resource_public_key text NOT NULL,
    node_headers text,
    node_headers_format integer DEFAULT 0,
    processed_resource jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    envelope_community_id integer NOT NULL,
    fts_tsearch text,
    fts_trigram text,
    fts_tsearch_tsv tsvector,
    resource_type character varying,
    organization_id uuid,
    publisher_id uuid
);


--
-- Name: envelopes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE envelopes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: envelopes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE envelopes_id_seq OWNED BY envelopes.id;


--
-- Name: json_schemas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE json_schemas (
    id integer NOT NULL,
    name character varying NOT NULL,
    schema jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: json_schemas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE json_schemas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: json_schemas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE json_schemas_id_seq OWNED BY json_schemas.id;


--
-- Name: key_pairs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE key_pairs (
    id integer NOT NULL,
    encrypted_private_key bytea NOT NULL,
    iv bytea NOT NULL,
    organization_publisher_id integer NOT NULL,
    public_key character varying NOT NULL,
    status integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: key_pairs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE key_pairs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: key_pairs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE key_pairs_id_seq OWNED BY key_pairs.id;


--
-- Name: organization_publishers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE organization_publishers (
    id integer NOT NULL,
    organization_id uuid NOT NULL,
    publisher_id uuid NOT NULL
);


--
-- Name: organization_publishers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE organization_publishers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_publishers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE organization_publishers_id_seq OWNED BY organization_publishers.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE organizations (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    admin_id integer NOT NULL,
    description character varying,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: publishers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE publishers (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    admin_id integer NOT NULL,
    contact_info character varying,
    description character varying,
    name character varying NOT NULL,
    super_publisher boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    admin_id integer,
    email character varying NOT NULL,
    publisher_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions (
    id integer NOT NULL,
    item_type character varying NOT NULL,
    item_id integer NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone,
    object_changes text
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: administrative_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY administrative_accounts ALTER COLUMN id SET DEFAULT nextval('administrative_accounts_id_seq'::regclass);


--
-- Name: admins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY admins ALTER COLUMN id SET DEFAULT nextval('admins_id_seq'::regclass);


--
-- Name: auth_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY auth_tokens ALTER COLUMN id SET DEFAULT nextval('auth_tokens_id_seq'::regclass);


--
-- Name: envelope_communities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY envelope_communities ALTER COLUMN id SET DEFAULT nextval('envelope_communities_id_seq'::regclass);


--
-- Name: envelope_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY envelope_transactions ALTER COLUMN id SET DEFAULT nextval('envelope_transactions_id_seq'::regclass);


--
-- Name: envelopes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY envelopes ALTER COLUMN id SET DEFAULT nextval('envelopes_id_seq'::regclass);


--
-- Name: json_schemas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY json_schemas ALTER COLUMN id SET DEFAULT nextval('json_schemas_id_seq'::regclass);


--
-- Name: key_pairs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY key_pairs ALTER COLUMN id SET DEFAULT nextval('key_pairs_id_seq'::regclass);


--
-- Name: organization_publishers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY organization_publishers ALTER COLUMN id SET DEFAULT nextval('organization_publishers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: administrative_accounts administrative_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY administrative_accounts
    ADD CONSTRAINT administrative_accounts_pkey PRIMARY KEY (id);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: auth_tokens auth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY auth_tokens
    ADD CONSTRAINT auth_tokens_pkey PRIMARY KEY (id);


--
-- Name: envelope_communities envelope_communities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY envelope_communities
    ADD CONSTRAINT envelope_communities_pkey PRIMARY KEY (id);


--
-- Name: envelope_transactions envelope_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY envelope_transactions
    ADD CONSTRAINT envelope_transactions_pkey PRIMARY KEY (id);


--
-- Name: envelopes envelopes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY envelopes
    ADD CONSTRAINT envelopes_pkey PRIMARY KEY (id);


--
-- Name: json_schemas json_schemas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY json_schemas
    ADD CONSTRAINT json_schemas_pkey PRIMARY KEY (id);


--
-- Name: key_pairs key_pairs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY key_pairs
    ADD CONSTRAINT key_pairs_pkey PRIMARY KEY (id);


--
-- Name: organization_publishers organization_publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY organization_publishers
    ADD CONSTRAINT organization_publishers_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: publishers publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY publishers
    ADD CONSTRAINT publishers_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: envelopes_fts_trigram_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX envelopes_fts_trigram_idx ON envelopes USING gin (fts_trigram gin_trgm_ops);


--
-- Name: envelopes_resources_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX envelopes_resources_id_idx ON envelopes USING btree (((processed_resource ->> '@id'::text)));


--
-- Name: index_administrative_accounts_on_public_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_administrative_accounts_on_public_key ON administrative_accounts USING btree (public_key);


--
-- Name: index_admins_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admins_on_name ON admins USING btree (name);


--
-- Name: index_auth_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auth_tokens_on_user_id ON auth_tokens USING btree (user_id);


--
-- Name: index_auth_tokens_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_auth_tokens_on_value ON auth_tokens USING btree (value);


--
-- Name: index_envelope_communities_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_envelope_communities_on_name ON envelope_communities USING btree (name);


--
-- Name: index_envelopes_on_envelope_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_envelopes_on_envelope_id ON envelopes USING btree (envelope_id);


--
-- Name: index_envelopes_on_envelope_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_envelope_type ON envelopes USING btree (envelope_type);


--
-- Name: index_envelopes_on_envelope_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_envelope_version ON envelopes USING btree (envelope_version);


--
-- Name: index_envelopes_on_fts_tsearch_tsv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_fts_tsearch_tsv ON envelopes USING gin (fts_tsearch_tsv);


--
-- Name: index_envelopes_on_processed_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_processed_resource ON envelopes USING gin (processed_resource);


--
-- Name: index_json_schemas_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_json_schemas_on_name ON json_schemas USING btree (name);


--
-- Name: index_key_pairs_on_public_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_key_pairs_on_public_key ON key_pairs USING btree (public_key);


--
-- Name: index_organization_publishers; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organization_publishers ON organization_publishers USING btree (organization_id, publisher_id);


--
-- Name: index_organizations_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_name ON organizations USING btree (lower((name)::text));


--
-- Name: index_publishers_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_publishers_on_name ON publishers USING btree (lower((name)::text));


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (lower((email)::text));


--
-- Name: index_users_on_publisher_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_publisher_id ON users USING btree (publisher_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_object; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_object ON versions USING gin (object);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: envelopes fts_tsvector_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER fts_tsvector_update BEFORE INSERT OR UPDATE ON envelopes FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger('fts_tsearch_tsv', 'pg_catalog.simple', 'fts_tsearch');


--
-- Name: auth_tokens fk_rails_0d66c22f4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY auth_tokens
    ADD CONSTRAINT fk_rails_0d66c22f4c FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: users fk_rails_1694bfe639; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_1694bfe639 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: organizations fk_rails_1bb60b936a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT fk_rails_1bb60b936a FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: envelopes fk_rails_4833726efb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY envelopes
    ADD CONSTRAINT fk_rails_4833726efb FOREIGN KEY (publisher_id) REFERENCES publishers(id);


--
-- Name: envelope_transactions fk_rails_5407a61089; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY envelope_transactions
    ADD CONSTRAINT fk_rails_5407a61089 FOREIGN KEY (envelope_id) REFERENCES envelopes(id);


--
-- Name: organization_publishers fk_rails_6bbeb2d16c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY organization_publishers
    ADD CONSTRAINT fk_rails_6bbeb2d16c FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;


--
-- Name: users fk_rails_9ef4d305d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_9ef4d305d6 FOREIGN KEY (publisher_id) REFERENCES publishers(id);


--
-- Name: envelopes fk_rails_b2db0aa0a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY envelopes
    ADD CONSTRAINT fk_rails_b2db0aa0a6 FOREIGN KEY (organization_id) REFERENCES organizations(id);


--
-- Name: publishers fk_rails_be0d340233; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY publishers
    ADD CONSTRAINT fk_rails_be0d340233 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: organization_publishers fk_rails_f1e2e64cfa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY organization_publishers
    ADD CONSTRAINT fk_rails_f1e2e64cfa FOREIGN KEY (publisher_id) REFERENCES publishers(id) ON DELETE CASCADE;


--
-- Name: key_pairs fk_rails_f92bbfc7f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY key_pairs
    ADD CONSTRAINT fk_rails_f92bbfc7f3 FOREIGN KEY (organization_publisher_id) REFERENCES organization_publishers(id);


--
-- Name: envelopes fk_rails_fbac8d1e0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY envelopes
    ADD CONSTRAINT fk_rails_fbac8d1e0a FOREIGN KEY (envelope_community_id) REFERENCES envelope_communities(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20160223171632');

INSERT INTO schema_migrations (version) VALUES ('20160407152817');

INSERT INTO schema_migrations (version) VALUES ('20160414152951');

INSERT INTO schema_migrations (version) VALUES ('20160505094815');

INSERT INTO schema_migrations (version) VALUES ('20160505095021');

INSERT INTO schema_migrations (version) VALUES ('20160524095936');

INSERT INTO schema_migrations (version) VALUES ('20160527073357');

INSERT INTO schema_migrations (version) VALUES ('20160824194535');

INSERT INTO schema_migrations (version) VALUES ('20160824224410');

INSERT INTO schema_migrations (version) VALUES ('20160824225705');

INSERT INTO schema_migrations (version) VALUES ('20160825034410');

INSERT INTO schema_migrations (version) VALUES ('20161101121532');

INSERT INTO schema_migrations (version) VALUES ('20161108105842');

INSERT INTO schema_migrations (version) VALUES ('20170312011508');

INSERT INTO schema_migrations (version) VALUES ('20170412045538');

INSERT INTO schema_migrations (version) VALUES ('20171101152316');

INSERT INTO schema_migrations (version) VALUES ('20171101161031');

INSERT INTO schema_migrations (version) VALUES ('20171101194114');

INSERT INTO schema_migrations (version) VALUES ('20171101194708');

INSERT INTO schema_migrations (version) VALUES ('20171101205513');

INSERT INTO schema_migrations (version) VALUES ('20171101211441');

INSERT INTO schema_migrations (version) VALUES ('20171104152617');

INSERT INTO schema_migrations (version) VALUES ('20171109230956');

INSERT INTO schema_migrations (version) VALUES ('20171113221325');


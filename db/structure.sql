--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.13
-- Dumped by pg_dump version 9.5.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
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


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: administrative_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.administrative_accounts (
    id integer NOT NULL,
    public_key character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: administrative_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.administrative_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: administrative_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.administrative_accounts_id_seq OWNED BY public.administrative_accounts.id;


--
-- Name: admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admins_id_seq OWNED BY public.admins.id;


--
-- Name: auth_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_tokens (
    id integer NOT NULL,
    user_id integer,
    value character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: auth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auth_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auth_tokens_id_seq OWNED BY public.auth_tokens.id;


--
-- Name: envelope_communities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envelope_communities (
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

CREATE SEQUENCE public.envelope_communities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: envelope_communities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.envelope_communities_id_seq OWNED BY public.envelope_communities.id;


--
-- Name: envelope_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envelope_transactions (
    id integer NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    envelope_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: envelope_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.envelope_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: envelope_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.envelope_transactions_id_seq OWNED BY public.envelope_transactions.id;


--
-- Name: envelopes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envelopes (
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
    publisher_id uuid,
    secondary_publisher_id uuid,
    lookup_id character varying
);


--
-- Name: envelopes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.envelopes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: envelopes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.envelopes_id_seq OWNED BY public.envelopes.id;


--
-- Name: json_schemas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.json_schemas (
    id integer NOT NULL,
    name character varying NOT NULL,
    schema jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: json_schemas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.json_schemas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: json_schemas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.json_schemas_id_seq OWNED BY public.json_schemas.id;


--
-- Name: key_pairs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.key_pairs (
    id integer NOT NULL,
    encrypted_private_key bytea NOT NULL,
    iv bytea NOT NULL,
    public_key character varying NOT NULL,
    status integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    organization_id uuid
);


--
-- Name: key_pairs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.key_pairs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: key_pairs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.key_pairs_id_seq OWNED BY public.key_pairs.id;


--
-- Name: organization_publishers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_publishers (
    id integer NOT NULL,
    organization_id uuid NOT NULL,
    publisher_id uuid NOT NULL
);


--
-- Name: organization_publishers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organization_publishers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_publishers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organization_publishers_id_seq OWNED BY public.organization_publishers.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    admin_id integer NOT NULL,
    description character varying,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    _ctid character varying NOT NULL
);


--
-- Name: publishers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.publishers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
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

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
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

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
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

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_accounts ALTER COLUMN id SET DEFAULT nextval('public.administrative_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins ALTER COLUMN id SET DEFAULT nextval('public.admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_tokens ALTER COLUMN id SET DEFAULT nextval('public.auth_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_communities ALTER COLUMN id SET DEFAULT nextval('public.envelope_communities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_transactions ALTER COLUMN id SET DEFAULT nextval('public.envelope_transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes ALTER COLUMN id SET DEFAULT nextval('public.envelopes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.json_schemas ALTER COLUMN id SET DEFAULT nextval('public.json_schemas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.key_pairs ALTER COLUMN id SET DEFAULT nextval('public.key_pairs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_publishers ALTER COLUMN id SET DEFAULT nextval('public.organization_publishers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: administrative_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_accounts
    ADD CONSTRAINT administrative_accounts_pkey PRIMARY KEY (id);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: auth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_tokens
    ADD CONSTRAINT auth_tokens_pkey PRIMARY KEY (id);


--
-- Name: envelope_communities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_communities
    ADD CONSTRAINT envelope_communities_pkey PRIMARY KEY (id);


--
-- Name: envelope_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_transactions
    ADD CONSTRAINT envelope_transactions_pkey PRIMARY KEY (id);


--
-- Name: envelopes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT envelopes_pkey PRIMARY KEY (id);


--
-- Name: json_schemas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.json_schemas
    ADD CONSTRAINT json_schemas_pkey PRIMARY KEY (id);


--
-- Name: key_pairs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.key_pairs
    ADD CONSTRAINT key_pairs_pkey PRIMARY KEY (id);


--
-- Name: organization_publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_publishers
    ADD CONSTRAINT organization_publishers_pkey PRIMARY KEY (id);


--
-- Name: organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publishers_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: envelopes_fts_trigram_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX envelopes_fts_trigram_idx ON public.envelopes USING gin (fts_trigram public.gin_trgm_ops);


--
-- Name: envelopes_lookup_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX envelopes_lookup_id_idx ON public.envelopes USING btree (lower((lookup_id)::text));


--
-- Name: envelopes_resources_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX envelopes_resources_id_idx ON public.envelopes USING btree (lower((processed_resource ->> '@id'::text)));


--
-- Name: index_administrative_accounts_on_public_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_administrative_accounts_on_public_key ON public.administrative_accounts USING btree (public_key);


--
-- Name: index_admins_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admins_on_name ON public.admins USING btree (name);


--
-- Name: index_auth_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auth_tokens_on_user_id ON public.auth_tokens USING btree (user_id);


--
-- Name: index_auth_tokens_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_auth_tokens_on_value ON public.auth_tokens USING btree (value);


--
-- Name: index_envelope_communities_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_envelope_communities_on_name ON public.envelope_communities USING btree (name);


--
-- Name: index_envelopes_on_envelope_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_envelopes_on_envelope_id ON public.envelopes USING btree (envelope_id);


--
-- Name: index_envelopes_on_envelope_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_envelope_type ON public.envelopes USING btree (envelope_type);


--
-- Name: index_envelopes_on_envelope_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_envelope_version ON public.envelopes USING btree (envelope_version);


--
-- Name: index_envelopes_on_fts_tsearch_tsv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_fts_tsearch_tsv ON public.envelopes USING gin (fts_tsearch_tsv);


--
-- Name: index_envelopes_on_processed_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_processed_resource ON public.envelopes USING gin (processed_resource);


--
-- Name: index_json_schemas_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_json_schemas_on_name ON public.json_schemas USING btree (name);


--
-- Name: index_key_pairs_on_public_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_key_pairs_on_public_key ON public.key_pairs USING btree (public_key);


--
-- Name: index_organization_publishers; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organization_publishers ON public.organization_publishers USING btree (organization_id, publisher_id);


--
-- Name: index_organizations_on__ctid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on__ctid ON public.organizations USING btree (_ctid);


--
-- Name: index_organizations_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_name ON public.organizations USING btree (lower((name)::text));


--
-- Name: index_publishers_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_publishers_on_name ON public.publishers USING btree (lower((name)::text));


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (lower((email)::text));


--
-- Name: index_users_on_publisher_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_publisher_id ON public.users USING btree (publisher_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_object; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_object ON public.versions USING gin (object);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: fts_tsvector_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER fts_tsvector_update BEFORE INSERT OR UPDATE ON public.envelopes FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger('fts_tsearch_tsv', 'pg_catalog.simple', 'fts_tsearch');


--
-- Name: fk_rails_0d66c22f4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_tokens
    ADD CONSTRAINT fk_rails_0d66c22f4c FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: fk_rails_1694bfe639; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_1694bfe639 FOREIGN KEY (admin_id) REFERENCES public.admins(id);


--
-- Name: fk_rails_1bb60b936a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT fk_rails_1bb60b936a FOREIGN KEY (admin_id) REFERENCES public.admins(id);


--
-- Name: fk_rails_4833726efb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT fk_rails_4833726efb FOREIGN KEY (publisher_id) REFERENCES public.publishers(id);


--
-- Name: fk_rails_5407a61089; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_transactions
    ADD CONSTRAINT fk_rails_5407a61089 FOREIGN KEY (envelope_id) REFERENCES public.envelopes(id);


--
-- Name: fk_rails_5d5c10d79f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT fk_rails_5d5c10d79f FOREIGN KEY (secondary_publisher_id) REFERENCES public.publishers(id);


--
-- Name: fk_rails_6964e51423; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.key_pairs
    ADD CONSTRAINT fk_rails_6964e51423 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: fk_rails_6bbeb2d16c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_publishers
    ADD CONSTRAINT fk_rails_6bbeb2d16c FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: fk_rails_9ef4d305d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_9ef4d305d6 FOREIGN KEY (publisher_id) REFERENCES public.publishers(id);


--
-- Name: fk_rails_b2db0aa0a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT fk_rails_b2db0aa0a6 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: fk_rails_be0d340233; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT fk_rails_be0d340233 FOREIGN KEY (admin_id) REFERENCES public.admins(id);


--
-- Name: fk_rails_f1e2e64cfa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_publishers
    ADD CONSTRAINT fk_rails_f1e2e64cfa FOREIGN KEY (publisher_id) REFERENCES public.publishers(id) ON DELETE CASCADE;


--
-- Name: fk_rails_fbac8d1e0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT fk_rails_fbac8d1e0a FOREIGN KEY (envelope_community_id) REFERENCES public.envelope_communities(id);


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

INSERT INTO schema_migrations (version) VALUES ('20171121222132');

INSERT INTO schema_migrations (version) VALUES ('20171215172051');

INSERT INTO schema_migrations (version) VALUES ('20180301172831');

INSERT INTO schema_migrations (version) VALUES ('20180622000243');

INSERT INTO schema_migrations (version) VALUES ('20180622205001');


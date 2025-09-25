SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


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


--
-- Name: ctdl_ts_rank(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ctdl_ts_rank(search_term text, content text) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE
  content_lower text;
  position_weight float;
  rank float := 0;
  search_term_lower text;
BEGIN
  content_lower := lower(content);
  search_term_lower := lower(search_term);

  -- Check for exact match
  IF content_lower = search_term_lower THEN
    rank := rank + 1.0;
  END IF;

  -- Check for partial match and calculate position weight
  IF content_lower LIKE '%' || search_term_lower || '%' THEN
    position_weight := 1.0 - (position(search_term_lower in content_lower) - 1.0) / length(content_lower)::float;
    rank := rank + 0.5 * position_weight;
  END IF;

  -- Check if search term is a substring of content
  IF position(search_term_lower in content_lower) > 0 THEN
    position_weight := 1.0 - (position(search_term_lower in content_lower) - 1.0) / length(content_lower)::float;
    rank := rank + 0.3 * position_weight;
  END IF;

  -- Check if content is a substring of search term
  IF position(content_lower in search_term_lower) > 0 THEN
    rank := rank + 0.2;
  END IF;

  RETURN rank;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

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
    AS integer
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
    AS integer
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
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


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
    AS integer
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
-- Name: description_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.description_sets (
    id integer NOT NULL,
    ceterms_ctid character varying NOT NULL,
    path character varying NOT NULL,
    uris character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    envelope_community_id integer,
    envelope_resource_id integer
);


--
-- Name: description_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.description_sets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: description_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.description_sets_id_seq OWNED BY public.description_sets.id;


--
-- Name: envelope_communities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envelope_communities (
    id integer NOT NULL,
    name character varying NOT NULL,
    "default" boolean DEFAULT false NOT NULL,
    backup_item character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    secured boolean DEFAULT false NOT NULL,
    secured_search boolean DEFAULT false NOT NULL,
    ocn_directory_id uuid,
    ocn_export_enabled boolean DEFAULT false NOT NULL,
    ocn_s3_bucket character varying
);


--
-- Name: envelope_communities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.envelope_communities_id_seq
    AS integer
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
-- Name: envelope_community_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envelope_community_configs (
    id bigint NOT NULL,
    description character varying NOT NULL,
    envelope_community_id bigint NOT NULL,
    payload jsonb DEFAULT '"{}"'::jsonb NOT NULL
);


--
-- Name: envelope_community_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.envelope_community_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: envelope_community_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.envelope_community_configs_id_seq OWNED BY public.envelope_community_configs.id;


--
-- Name: envelope_downloads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envelope_downloads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    envelope_community_id bigint NOT NULL,
    finished_at timestamp(6) without time zone,
    internal_error_backtrace character varying[] DEFAULT '{}'::character varying[],
    internal_error_message character varying,
    started_at timestamp(6) without time zone,
    url character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    enqueued_at timestamp(6) without time zone
);


--
-- Name: envelope_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envelope_resources (
    id integer NOT NULL,
    envelope_id integer NOT NULL,
    resource_id character varying NOT NULL,
    processed_resource jsonb NOT NULL,
    fts_tsearch text,
    fts_tsearch_tsv tsvector,
    fts_trigram text,
    envelope_type integer DEFAULT 0 NOT NULL,
    resource_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: envelope_resources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.envelope_resources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: envelope_resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.envelope_resources_id_seq OWNED BY public.envelope_resources.id;


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
    AS integer
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
    resource_format integer DEFAULT 0 NOT NULL,
    resource_encoding integer DEFAULT 0 NOT NULL,
    node_headers text,
    node_headers_format integer DEFAULT 0,
    processed_resource jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    envelope_community_id integer NOT NULL,
    resource_type character varying,
    organization_id uuid,
    publisher_id uuid,
    secondary_publisher_id uuid,
    top_level_object_ids text[] DEFAULT '{}'::text[],
    last_graph_indexed_at timestamp without time zone,
    envelope_ceterms_ctid character varying,
    envelope_ctdl_type character varying,
    purged_at timestamp without time zone,
    publishing_organization_id uuid,
    resource_publish_type character varying,
    last_verified_on date,
    publication_status integer DEFAULT 0 NOT NULL
);


--
-- Name: envelopes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.envelopes_id_seq
    AS integer
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
-- Name: indexed_envelope_resource_references; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.indexed_envelope_resource_references (
    id bigint NOT NULL,
    path character varying NOT NULL,
    resource_id bigint NOT NULL,
    resource_uri character varying NOT NULL,
    subresource_uri character varying NOT NULL
);


--
-- Name: indexed_envelope_resource_references_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.indexed_envelope_resource_references_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: indexed_envelope_resource_references_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.indexed_envelope_resource_references_id_seq OWNED BY public.indexed_envelope_resource_references.id;


--
-- Name: indexed_envelope_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.indexed_envelope_resources (
    id bigint NOT NULL,
    "@id" character varying NOT NULL,
    "@type" character varying NOT NULL,
    "ceterms:ctid" character varying,
    "search:recordCreated" timestamp without time zone NOT NULL,
    "search:recordOwnedBy" character varying,
    "search:recordPublishedBy" character varying,
    "search:recordUpdated" timestamp without time zone NOT NULL,
    envelope_community_id bigint NOT NULL,
    envelope_resource_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    payload jsonb DEFAULT '"{}"'::jsonb NOT NULL,
    public_record boolean DEFAULT true NOT NULL,
    "search:resourcePublishType" character varying,
    publication_status integer DEFAULT 0 NOT NULL
);


--
-- Name: indexed_envelope_resources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.indexed_envelope_resources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: indexed_envelope_resources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.indexed_envelope_resources_id_seq OWNED BY public.indexed_envelope_resources.id;


--
-- Name: json_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.json_contexts (
    id integer NOT NULL,
    url character varying NOT NULL,
    context jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: json_contexts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.json_contexts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: json_contexts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.json_contexts_id_seq OWNED BY public.json_contexts.id;


--
-- Name: json_schemas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.json_schemas (
    id integer NOT NULL,
    name character varying NOT NULL,
    schema jsonb DEFAULT '"{}"'::jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: json_schemas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.json_schemas_id_seq
    AS integer
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
    AS integer
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
    AS integer
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
-- Name: publish_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.publish_requests (
    id bigint NOT NULL,
    request_params text NOT NULL,
    envelope_id bigint,
    error jsonb,
    completed_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: publish_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.publish_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publish_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.publish_requests_id_seq OWNED BY public.publish_requests.id;


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
-- Name: query_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.query_logs (
    id bigint NOT NULL,
    engine character varying NOT NULL,
    started_at timestamp without time zone NOT NULL,
    completed_at timestamp without time zone,
    ctdl text,
    result text,
    query_logic text,
    query text,
    error text,
    options jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: query_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.query_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: query_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.query_logs_id_seq OWNED BY public.query_logs.id;


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
    AS integer
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
    object jsonb DEFAULT '"{}"'::jsonb,
    created_at timestamp without time zone,
    object_changes text,
    envelope_ceterms_ctid character varying,
    envelope_community_id bigint,
    publication_status integer DEFAULT 0 NOT NULL
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    AS integer
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
-- Name: administrative_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_accounts ALTER COLUMN id SET DEFAULT nextval('public.administrative_accounts_id_seq'::regclass);


--
-- Name: admins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins ALTER COLUMN id SET DEFAULT nextval('public.admins_id_seq'::regclass);


--
-- Name: auth_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_tokens ALTER COLUMN id SET DEFAULT nextval('public.auth_tokens_id_seq'::regclass);


--
-- Name: description_sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.description_sets ALTER COLUMN id SET DEFAULT nextval('public.description_sets_id_seq'::regclass);


--
-- Name: envelope_communities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_communities ALTER COLUMN id SET DEFAULT nextval('public.envelope_communities_id_seq'::regclass);


--
-- Name: envelope_community_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_community_configs ALTER COLUMN id SET DEFAULT nextval('public.envelope_community_configs_id_seq'::regclass);


--
-- Name: envelope_resources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_resources ALTER COLUMN id SET DEFAULT nextval('public.envelope_resources_id_seq'::regclass);


--
-- Name: envelope_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_transactions ALTER COLUMN id SET DEFAULT nextval('public.envelope_transactions_id_seq'::regclass);


--
-- Name: envelopes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes ALTER COLUMN id SET DEFAULT nextval('public.envelopes_id_seq'::regclass);


--
-- Name: indexed_envelope_resource_references id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resource_references ALTER COLUMN id SET DEFAULT nextval('public.indexed_envelope_resource_references_id_seq'::regclass);


--
-- Name: indexed_envelope_resources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resources ALTER COLUMN id SET DEFAULT nextval('public.indexed_envelope_resources_id_seq'::regclass);


--
-- Name: json_contexts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.json_contexts ALTER COLUMN id SET DEFAULT nextval('public.json_contexts_id_seq'::regclass);


--
-- Name: json_schemas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.json_schemas ALTER COLUMN id SET DEFAULT nextval('public.json_schemas_id_seq'::regclass);


--
-- Name: key_pairs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.key_pairs ALTER COLUMN id SET DEFAULT nextval('public.key_pairs_id_seq'::regclass);


--
-- Name: organization_publishers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_publishers ALTER COLUMN id SET DEFAULT nextval('public.organization_publishers_id_seq'::regclass);


--
-- Name: publish_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publish_requests ALTER COLUMN id SET DEFAULT nextval('public.publish_requests_id_seq'::regclass);


--
-- Name: query_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_logs ALTER COLUMN id SET DEFAULT nextval('public.query_logs_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: administrative_accounts administrative_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_accounts
    ADD CONSTRAINT administrative_accounts_pkey PRIMARY KEY (id);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: auth_tokens auth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_tokens
    ADD CONSTRAINT auth_tokens_pkey PRIMARY KEY (id);


--
-- Name: description_sets description_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.description_sets
    ADD CONSTRAINT description_sets_pkey PRIMARY KEY (id);


--
-- Name: envelope_communities envelope_communities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_communities
    ADD CONSTRAINT envelope_communities_pkey PRIMARY KEY (id);


--
-- Name: envelope_community_configs envelope_community_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_community_configs
    ADD CONSTRAINT envelope_community_configs_pkey PRIMARY KEY (id);


--
-- Name: envelope_downloads envelope_downloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_downloads
    ADD CONSTRAINT envelope_downloads_pkey PRIMARY KEY (id);


--
-- Name: envelope_resources envelope_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_resources
    ADD CONSTRAINT envelope_resources_pkey PRIMARY KEY (id);


--
-- Name: envelope_transactions envelope_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_transactions
    ADD CONSTRAINT envelope_transactions_pkey PRIMARY KEY (id);


--
-- Name: envelopes envelopes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT envelopes_pkey PRIMARY KEY (id);


--
-- Name: indexed_envelope_resource_references indexed_envelope_resource_references_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resource_references
    ADD CONSTRAINT indexed_envelope_resource_references_pkey PRIMARY KEY (id);


--
-- Name: indexed_envelope_resources indexed_envelope_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resources
    ADD CONSTRAINT indexed_envelope_resources_pkey PRIMARY KEY (id);


--
-- Name: json_contexts json_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.json_contexts
    ADD CONSTRAINT json_contexts_pkey PRIMARY KEY (id);


--
-- Name: json_schemas json_schemas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.json_schemas
    ADD CONSTRAINT json_schemas_pkey PRIMARY KEY (id);


--
-- Name: key_pairs key_pairs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.key_pairs
    ADD CONSTRAINT key_pairs_pkey PRIMARY KEY (id);


--
-- Name: organization_publishers organization_publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_publishers
    ADD CONSTRAINT organization_publishers_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: publish_requests publish_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publish_requests
    ADD CONSTRAINT publish_requests_pkey PRIMARY KEY (id);


--
-- Name: publishers publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publishers_pkey PRIMARY KEY (id);


--
-- Name: query_logs query_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_logs
    ADD CONSTRAINT query_logs_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: envelope_resources_fts_trigram_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX envelope_resources_fts_trigram_idx ON public.envelope_resources USING gin (fts_trigram public.gin_trgm_ops);


--
-- Name: envelopes_resources_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX envelopes_resources_id_idx ON public.envelopes USING btree (((processed_resource ->> '@id'::text)));


--
-- Name: i_ctdl_ceterms_ctid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX i_ctdl_ceterms_ctid ON public.indexed_envelope_resources USING btree (envelope_community_id, "ceterms:ctid");


--
-- Name: i_ctdl_ceterms_ctid_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_ctid_trgm ON public.indexed_envelope_resources USING gin ("ceterms:ctid" public.gin_trgm_ops);


--
-- Name: i_ctdl_envelope_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_envelope_resource_id ON public.indexed_envelope_resources USING btree (envelope_resource_id);


--
-- Name: i_ctdl_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX i_ctdl_id ON public.indexed_envelope_resources USING btree ("@id");


--
-- Name: i_ctdl_id_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_id_trgm ON public.indexed_envelope_resources USING gin ("@id" public.gin_trgm_ops);


--
-- Name: i_ctdl_public_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_public_record ON public.indexed_envelope_resources USING btree (public_record);


--
-- Name: i_ctdl_search_ownedBy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_search_ownedBy" ON public.indexed_envelope_resources USING btree ("search:recordOwnedBy");


--
-- Name: i_ctdl_search_publishedBy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_search_publishedBy" ON public.indexed_envelope_resources USING btree ("search:recordPublishedBy");


--
-- Name: i_ctdl_search_recordCreated_asc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_search_recordCreated_asc" ON public.indexed_envelope_resources USING btree ("search:recordCreated");


--
-- Name: i_ctdl_search_recordCreated_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_search_recordCreated_desc" ON public.indexed_envelope_resources USING btree ("search:recordCreated" DESC);


--
-- Name: i_ctdl_search_recordUpdated_asc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_search_recordUpdated_asc" ON public.indexed_envelope_resources USING btree ("search:recordUpdated");


--
-- Name: i_ctdl_search_recordUpdated_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_search_recordUpdated_desc" ON public.indexed_envelope_resources USING btree ("search:recordUpdated" DESC);


--
-- Name: i_ctdl_search_resourcePublishType; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_search_resourcePublishType" ON public.indexed_envelope_resources USING btree ("search:resourcePublishType");


--
-- Name: i_ctdl_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_type ON public.indexed_envelope_resources USING btree ("@type");


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
-- Name: index_description_sets; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_description_sets ON public.description_sets USING btree (ceterms_ctid, envelope_community_id, path);


--
-- Name: index_envelope_communities_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_envelope_communities_on_name ON public.envelope_communities USING btree (name);


--
-- Name: index_envelope_community_configs_on_envelope_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_community_configs_on_envelope_community_id ON public.envelope_community_configs USING btree (envelope_community_id);


--
-- Name: index_envelope_downloads_on_envelope_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_envelope_downloads_on_envelope_community_id ON public.envelope_downloads USING btree (envelope_community_id);


--
-- Name: index_envelope_resources_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_resources_on_created_at ON public.envelope_resources USING btree (created_at);


--
-- Name: index_envelope_resources_on_envelope_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_resources_on_envelope_id ON public.envelope_resources USING btree (envelope_id);


--
-- Name: index_envelope_resources_on_envelope_id_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_envelope_resources_on_envelope_id_and_resource_id ON public.envelope_resources USING btree (envelope_id, resource_id);


--
-- Name: index_envelope_resources_on_envelope_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_resources_on_envelope_type ON public.envelope_resources USING btree (envelope_type);


--
-- Name: index_envelope_resources_on_fts_tsearch_tsv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_resources_on_fts_tsearch_tsv ON public.envelope_resources USING gin (fts_tsearch_tsv);


--
-- Name: index_envelope_resources_on_processed_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_resources_on_processed_resource ON public.envelope_resources USING gin (processed_resource);


--
-- Name: index_envelope_resources_on_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_resources_on_resource_id ON public.envelope_resources USING btree (resource_id);


--
-- Name: index_envelope_resources_on_resource_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_resources_on_resource_type ON public.envelope_resources USING btree (resource_type);


--
-- Name: index_envelope_resources_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_resources_on_updated_at ON public.envelope_resources USING btree (updated_at);


--
-- Name: index_envelope_transactions_on_envelope_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_transactions_on_envelope_id ON public.envelope_transactions USING btree (envelope_id);


--
-- Name: index_envelopes_on_envelope_community_id_and_envelope_ceterms_c; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_envelopes_on_envelope_community_id_and_envelope_ceterms_c ON public.envelopes USING btree (envelope_community_id, lower((envelope_ceterms_ctid)::text)) WHERE (deleted_at IS NULL);


--
-- Name: index_envelopes_on_envelope_ctdl_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_envelope_ctdl_type ON public.envelopes USING btree (envelope_ctdl_type);


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
-- Name: index_envelopes_on_processed_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_processed_resource ON public.envelopes USING gin (processed_resource);


--
-- Name: index_envelopes_on_publication_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_publication_status ON public.envelopes USING btree (publication_status);


--
-- Name: index_envelopes_on_publishing_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_publishing_organization_id ON public.envelopes USING btree (publishing_organization_id);


--
-- Name: index_envelopes_on_purged_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_purged_at ON public.envelopes USING btree (purged_at);


--
-- Name: index_envelopes_on_resource_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_resource_type ON public.envelopes USING btree (resource_type);


--
-- Name: index_envelopes_on_top_level_object_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_top_level_object_ids ON public.envelopes USING gin (top_level_object_ids);


--
-- Name: index_indexed_envelope_resource_references; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_indexed_envelope_resource_references ON public.indexed_envelope_resource_references USING btree (path, resource_id, resource_uri, subresource_uri);


--
-- Name: index_indexed_envelope_resource_references_on_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_indexed_envelope_resource_references_on_resource_id ON public.indexed_envelope_resource_references USING btree (resource_id);


--
-- Name: index_indexed_envelope_resource_references_on_resource_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_indexed_envelope_resource_references_on_resource_uri ON public.indexed_envelope_resource_references USING btree (resource_uri);


--
-- Name: index_indexed_envelope_resource_references_on_subresource_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_indexed_envelope_resource_references_on_subresource_uri ON public.indexed_envelope_resource_references USING gin (subresource_uri public.gin_trgm_ops);


--
-- Name: index_indexed_envelope_resources_on_publication_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_indexed_envelope_resources_on_publication_status ON public.indexed_envelope_resources USING btree (publication_status);


--
-- Name: index_json_contexts_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_json_contexts_on_context ON public.json_contexts USING gin (context);


--
-- Name: index_json_contexts_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_json_contexts_on_url ON public.json_contexts USING btree (url);


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

CREATE INDEX index_organizations_on_name ON public.organizations USING btree (name);


--
-- Name: index_publish_requests_on_completed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_publish_requests_on_completed_at ON public.publish_requests USING btree (completed_at);


--
-- Name: index_publish_requests_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_publish_requests_on_created_at ON public.publish_requests USING btree (created_at);


--
-- Name: index_publish_requests_on_envelope_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_publish_requests_on_envelope_id ON public.publish_requests USING btree (envelope_id);


--
-- Name: index_publish_requests_on_error; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_publish_requests_on_error ON public.publish_requests USING btree (error);


--
-- Name: index_publish_requests_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_publish_requests_on_updated_at ON public.publish_requests USING btree (updated_at);


--
-- Name: index_publishers_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_publishers_on_name ON public.publishers USING btree (lower((name)::text));


--
-- Name: index_query_logs_on_completed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_query_logs_on_completed_at ON public.query_logs USING btree (completed_at);


--
-- Name: index_query_logs_on_engine; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_query_logs_on_engine ON public.query_logs USING btree (engine);


--
-- Name: index_query_logs_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_query_logs_on_started_at ON public.query_logs USING btree (started_at);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (lower((email)::text));


--
-- Name: index_users_on_publisher_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_publisher_id ON public.users USING btree (publisher_id);


--
-- Name: index_versions_on_envelope_ceterms_ctid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_envelope_ceterms_ctid ON public.versions USING btree (envelope_ceterms_ctid);


--
-- Name: index_versions_on_envelope_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_envelope_community_id ON public.versions USING btree (envelope_community_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_object; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_object ON public.versions USING gin (object);


--
-- Name: index_versions_on_publication_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_publication_status ON public.versions USING btree (publication_status);


--
-- Name: envelope_resources envelope_resources_fts_tsvector_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER envelope_resources_fts_tsvector_update BEFORE INSERT OR UPDATE ON public.envelope_resources FOR EACH ROW EXECUTE FUNCTION tsvector_update_trigger('fts_tsearch_tsv', 'pg_catalog.simple', 'fts_tsearch');


--
-- Name: indexed_envelope_resources fk_rails_00f5654608; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resources
    ADD CONSTRAINT fk_rails_00f5654608 FOREIGN KEY ("search:recordPublishedBy") REFERENCES public.organizations(_ctid) ON DELETE SET NULL;


--
-- Name: envelopes fk_rails_055928e3ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT fk_rails_055928e3ab FOREIGN KEY (publishing_organization_id) REFERENCES public.organizations(id);


--
-- Name: auth_tokens fk_rails_0d66c22f4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_tokens
    ADD CONSTRAINT fk_rails_0d66c22f4c FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users fk_rails_1694bfe639; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_1694bfe639 FOREIGN KEY (admin_id) REFERENCES public.admins(id);


--
-- Name: organizations fk_rails_1bb60b936a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT fk_rails_1bb60b936a FOREIGN KEY (admin_id) REFERENCES public.admins(id);


--
-- Name: envelope_community_configs fk_rails_27f72c55da; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_community_configs
    ADD CONSTRAINT fk_rails_27f72c55da FOREIGN KEY (envelope_community_id) REFERENCES public.envelope_communities(id);


--
-- Name: envelopes fk_rails_4833726efb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT fk_rails_4833726efb FOREIGN KEY (publisher_id) REFERENCES public.publishers(id);


--
-- Name: indexed_envelope_resources fk_rails_4edd5e87b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resources
    ADD CONSTRAINT fk_rails_4edd5e87b9 FOREIGN KEY ("search:recordOwnedBy") REFERENCES public.organizations(_ctid) ON DELETE SET NULL;


--
-- Name: envelope_transactions fk_rails_5407a61089; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_transactions
    ADD CONSTRAINT fk_rails_5407a61089 FOREIGN KEY (envelope_id) REFERENCES public.envelopes(id) ON DELETE CASCADE;


--
-- Name: envelopes fk_rails_5d5c10d79f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT fk_rails_5d5c10d79f FOREIGN KEY (secondary_publisher_id) REFERENCES public.publishers(id);


--
-- Name: key_pairs fk_rails_6964e51423; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.key_pairs
    ADD CONSTRAINT fk_rails_6964e51423 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: organization_publishers fk_rails_6bbeb2d16c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_publishers
    ADD CONSTRAINT fk_rails_6bbeb2d16c FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: versions fk_rails_8374d8f805; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT fk_rails_8374d8f805 FOREIGN KEY (envelope_community_id) REFERENCES public.envelope_communities(id) ON DELETE CASCADE;


--
-- Name: indexed_envelope_resources fk_rails_87012a3108; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resources
    ADD CONSTRAINT fk_rails_87012a3108 FOREIGN KEY (envelope_community_id) REFERENCES public.envelope_communities(id) ON DELETE CASCADE;


--
-- Name: indexed_envelope_resource_references fk_rails_9294385e86; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resource_references
    ADD CONSTRAINT fk_rails_9294385e86 FOREIGN KEY (resource_id) REFERENCES public.indexed_envelope_resources(id) ON DELETE CASCADE;


--
-- Name: users fk_rails_9ef4d305d6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_9ef4d305d6 FOREIGN KEY (publisher_id) REFERENCES public.publishers(id);


--
-- Name: envelopes fk_rails_b2db0aa0a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT fk_rails_b2db0aa0a6 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: publishers fk_rails_be0d340233; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT fk_rails_be0d340233 FOREIGN KEY (admin_id) REFERENCES public.admins(id);


--
-- Name: publish_requests fk_rails_c01765f016; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publish_requests
    ADD CONSTRAINT fk_rails_c01765f016 FOREIGN KEY (envelope_id) REFERENCES public.envelopes(id);


--
-- Name: indexed_envelope_resource_references fk_rails_ce18a72cd9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resource_references
    ADD CONSTRAINT fk_rails_ce18a72cd9 FOREIGN KEY (resource_uri) REFERENCES public.indexed_envelope_resources("@id") ON DELETE CASCADE;


--
-- Name: indexed_envelope_resources fk_rails_dbc7ed34a9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resources
    ADD CONSTRAINT fk_rails_dbc7ed34a9 FOREIGN KEY (envelope_resource_id) REFERENCES public.envelope_resources(id) ON DELETE CASCADE;


--
-- Name: envelope_resources fk_rails_e6f6323848; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelope_resources
    ADD CONSTRAINT fk_rails_e6f6323848 FOREIGN KEY (envelope_id) REFERENCES public.envelopes(id) ON DELETE CASCADE;


--
-- Name: organization_publishers fk_rails_f1e2e64cfa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_publishers
    ADD CONSTRAINT fk_rails_f1e2e64cfa FOREIGN KEY (publisher_id) REFERENCES public.publishers(id) ON DELETE CASCADE;


--
-- Name: envelopes fk_rails_fbac8d1e0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envelopes
    ADD CONSTRAINT fk_rails_fbac8d1e0a FOREIGN KEY (envelope_community_id) REFERENCES public.envelope_communities(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20250925025616'),
('20250922224518'),
('20250921174021'),
('20250902034147'),
('20250830180848'),
('20250829235024'),
('20250818021420'),
('20250815032532'),
('20250618195306'),
('20250618190719'),
('20250511180851'),
('20240916114729'),
('20240224174644'),
('20230703110903'),
('20230515091128'),
('20230126122421'),
('20220315190000'),
('20220315122626'),
('20220314181045'),
('20220113141414'),
('20220106130200'),
('20211207110948'),
('20210715141032'),
('20210624173908'),
('20210601020245'),
('20210513043719'),
('20210311135955'),
('20210121082610'),
('20201012074942'),
('20200922150449'),
('20200922150215'),
('20200813121714'),
('20200727085544'),
('20200601094240'),
('20191024081858'),
('20190919121231'),
('20190227225740'),
('20181121213645'),
('20181107021512'),
('20181001205658'),
('20180729125600'),
('20180727234351'),
('20180727204436'),
('20180725215953'),
('20180713130937'),
('20180301172831'),
('20171215172051'),
('20171121222132'),
('20171113221325'),
('20171109230956'),
('20171104152617'),
('20171101211441'),
('20171101205513'),
('20171101194708'),
('20171101194114'),
('20171101161031'),
('20171101152316'),
('20170412045538'),
('20170312011508'),
('20161108105842'),
('20161101121532'),
('20160825034410'),
('20160824225705'),
('20160824224410'),
('20160824194535'),
('20160527073357'),
('20160524095936'),
('20160505095021'),
('20160505094815'),
('20160414152951'),
('20160407152817'),
('20160223171632');


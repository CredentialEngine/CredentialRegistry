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
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
    secured_search boolean DEFAULT false NOT NULL
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
    resource_type character varying,
    organization_id uuid,
    publisher_id uuid,
    secondary_publisher_id uuid,
    top_level_object_ids text[] DEFAULT '{}'::text[],
    last_graph_indexed_at timestamp without time zone,
    envelope_ceterms_ctid character varying,
    envelope_ctdl_type character varying,
    publishing_organization_id uuid,
    purged_at timestamp without time zone
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
    envelope_resource_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    payload jsonb DEFAULT '"{}"'::jsonb NOT NULL,
    "ceasn:name" character varying,
    "ceasn:name_en_us" character varying,
    "ceasn:inLanguage" character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    "ceasn:description" character varying,
    "ceasn:description_en_us" character varying,
    "ceasn:publisherName" character varying,
    "ceasn:publisherName_en_us" character varying,
    "skos:prefLabel" character varying,
    "skos:prefLabel_en_us" character varying,
    "skos:definition" character varying,
    "skos:definition_en_us" character varying,
    "ceterms:name" character varying,
    "ceterms:name_en_us" character varying,
    "ceterms:description" character varying,
    "ceterms:description_en_us" character varying,
    "ceterms:requiredNumber" integer[] DEFAULT '{}'::integer[] NOT NULL,
    "ceterms:endDate" date[] DEFAULT '{}'::date[] NOT NULL,
    "ceterms:startDate" date[] DEFAULT '{}'::date[] NOT NULL,
    "ceterms:codedNotation" character varying,
    "schema:value" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "schema:description" character varying,
    "schema:description_en_us" character varying,
    "ceterms:targetNodeName" character varying,
    "ceterms:targetNodeName_en_us" character varying,
    "ceterms:weight" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "ceterms:targetNodeDescription" character varying,
    "ceterms:targetNodeDescription_en_us" character varying,
    "ceterms:learningMethodDescription" character varying,
    "ceterms:learningMethodDescription_en_us" character varying,
    "ceterms:dateEffective" date[] DEFAULT '{}'::date[] NOT NULL,
    "ceterms:expirationDate" date[] DEFAULT '{}'::date[] NOT NULL,
    "ceterms:condition" character varying,
    "ceterms:condition_en_us" character varying,
    "ceterms:price" numeric[] DEFAULT '{}'::numeric[] NOT NULL,
    "ceterms:currency" character varying,
    "ceterms:frameworkName" character varying,
    "ceterms:frameworkName_en_us" character varying,
    "ceterms:inLanguage" character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    "ceterms:email" character varying,
    "ceterms:postalCode" character varying,
    "ceterms:addressRegion" character varying,
    "ceterms:addressRegion_en_us" character varying,
    "ceterms:streetAddress" character varying,
    "ceterms:streetAddress_en_us" character varying,
    "ceterms:addressCountry" character varying,
    "ceterms:addressCountry_en_us" character varying,
    "ceterms:addressLocality" character varying,
    "ceterms:addressLocality_en_us" character varying,
    "ceterms:keyword" character varying,
    "ceterms:keyword_en_us" character varying,
    "ceasn:dateModified" timestamp without time zone[] DEFAULT '{}'::timestamp without time zone[] NOT NULL,
    "ceasn:codedNotation" character varying,
    "ceasn:competencyText" character varying,
    "ceasn:competencyText_en_us" character varying,
    "ceasn:competencyLabel" character varying,
    "ceasn:competencyLabel_en_us" character varying,
    "ceasn:competencyCategory" character varying,
    "ceasn:competencyCategory_en_us" character varying,
    "ceterms:description_en" character varying,
    "ceterms:latitude" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "ceterms:longitude" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "schema:maxValue" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "schema:minValue" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "ceterms:isProctored" boolean[] DEFAULT '{}'::boolean[] NOT NULL,
    "ceterms:assessmentOutput" character varying,
    "ceterms:assessmentOutput_en_us" character varying,
    "ceterms:hasGroupEvaluation" boolean[] DEFAULT '{}'::boolean[] NOT NULL,
    "ceterms:hasGroupParticipation" boolean[] DEFAULT '{}'::boolean[] NOT NULL,
    "ceterms:deliveryTypeDescription" character varying,
    "ceterms:deliveryTypeDescription_en_us" character varying,
    "ceterms:scoringMethodDescription" character varying,
    "ceterms:scoringMethodDescription_en_us" character varying,
    "ceterms:processStandardsDescription" character varying,
    "ceterms:processStandardsDescription_en_us" character varying,
    "ceterms:assessmentExampleDescription" character varying,
    "ceterms:assessmentExampleDescription_en_us" character varying,
    "ceterms:scoringMethodExampleDescription" character varying,
    "ceterms:scoringMethodExampleDescription_en_us" character varying,
    "schema:currency" character varying,
    "ceterms:fein" character varying,
    "ceterms:telephone" character varying,
    "ceterms:contactType" character varying,
    "ceterms:contactType_en_us" character varying,
    "ceterms:duns" character varying,
    "ceterms:opeID" character varying,
    "ceterms:foundingDate" character varying,
    "ceterms:processFrequency" character varying,
    "ceterms:processFrequency_en_us" character varying,
    "ceterms:transferValueStatementDescription" character varying,
    "ceterms:transferValueStatementDescription_en_us" character varying,
    "ceterms:ipedsID" character varying,
    "ceterms:globalJurisdiction" boolean[] DEFAULT '{}'::boolean[] NOT NULL,
    "ceterms:credentialId" character varying,
    "ceterms:alternateName" character varying,
    "ceterms:alternateName_en_us" character varying,
    "ceterms:assessmentMethodDescription" character varying,
    "ceterms:assessmentMethodDescription_en_us" character varying,
    "ceterms:exactDuration" character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    "ceterms:numberAwarded" integer[] DEFAULT '{}'::integer[] NOT NULL,
    "ceterms:demographicInformation" character varying,
    "ceterms:demographicInformation_en_us" character varying,
    "qdata:adjustment" character varying,
    "qdata:adjustment_en_us" character varying,
    "qdata:workTimeThreshold" character varying,
    "qdata:workTimeThreshold_en_us" character varying,
    "qdata:earningsDefinition" character varying,
    "qdata:earningsDefinition_en_us" character varying,
    "qdata:median" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "qdata:percentile10" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "qdata:percentile25" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "qdata:percentile75" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "qdata:percentile90" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "qdata:employmentDefinition" character varying,
    "qdata:employmentDefinition_en_us" character varying,
    "qdata:percentage" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "ceterms:medianEarnings" integer[] DEFAULT '{}'::integer[] NOT NULL,
    "ceterms:paymentPattern" character varying,
    "ceterms:paymentPattern_en_us" character varying,
    "ceterms:agentPurposeDescription" character varying,
    "ceterms:agentPurposeDescription_en_us" character varying,
    "ceterms:naics" character varying,
    "ceterms:missionAndGoalsStatementDescription" character varying,
    "ceterms:missionAndGoalsStatementDescription_en_us" character varying,
    "ceterms:experience" character varying,
    "ceasn:dateCreated" date[] DEFAULT '{}'::date[] NOT NULL,
    "ceasn:publisherName_en" character varying,
    "ceterms:name_fr" character varying,
    "ceterms:description_fr" character varying,
    "ceterms:submissionOfDescription" character varying,
    "ceterms:submissionOfDescription_en_us" character varying,
    "ceterms:minimumAge" integer[] DEFAULT '{}'::integer[] NOT NULL,
    "ceterms:maximumDuration" character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    "ceterms:minimumDuration" character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    "ceterms:postReceiptMonths" integer[] DEFAULT '{}'::integer[] NOT NULL,
    "ceterms:verificationMethodDescription" character varying,
    "ceterms:verificationMethodDescription_en_us" character varying,
    "ceasn:conceptKeyword" character varying,
    "ceasn:conceptKeyword_en_us" character varying,
    "ceterms:condition_es" character varying,
    "ceterms:description_es" character varying,
    "ceterms:revocationCriteriaDescription" character varying,
    "ceterms:revocationCriteriaDescription_en_us" character varying,
    "ceterms:identifierValueCode" character varying,
    "ceterms:processMethodDescription" character varying,
    "ceterms:processMethodDescription_en_us" character varying,
    "ceterms:identifierTypeName" character varying,
    "ceterms:identifierTypeName_en_us" character varying,
    "ceterms:addressRegion_es" character varying,
    "ceterms:streetAddress_es" character varying,
    "ceterms:addressCountry_es" character varying,
    "ceterms:addressLocality_es" character varying,
    "ceterms:frameworkName_es" character varying,
    "ceterms:targetNodeName_es" character varying,
    "ceterms:name_nl" character varying,
    "ceterms:description_nl" character varying,
    "ceterms:frameworkName_nl" character varying,
    "ceterms:targetNodeName_nl" character varying,
    "ceterms:name_es" character varying,
    "ceterms:yearsOfExperience" double precision[] DEFAULT '{}'::double precision[] NOT NULL,
    "ceterms:postOfficeBoxNumber" character varying,
    "ceterms:isicV4" character varying,
    "ceterms:renewalFrequency" character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    "ceterms:creditUnitTypeDescription" character varying,
    "ceterms:creditUnitTypeDescription_en_us" character varying,
    "ceterms:frameworkName_fr" character varying,
    "ceterms:targetNodeName_fr" character varying,
    "ceasn:name_en" character varying,
    "ceasn:competencyText_fr" character varying,
    "ceterms:faxNumber" character varying,
    "ceterms:leiCode" character varying,
    "ceterms:holderMustAuthorize" boolean[] DEFAULT '{}'::boolean[] NOT NULL,
    "ceterms:name_en" character varying,
    "schema:description_en" character varying,
    "ceasn:comment" character varying,
    "ceasn:comment_en_us" character varying,
    "ceterms:lowEarnings" integer[] DEFAULT '{}'::integer[] NOT NULL,
    "ceterms:highEarnings" integer[] DEFAULT '{}'::integer[] NOT NULL,
    "search:recordUpdated" timestamp without time zone,
    "search:recordCreated" timestamp without time zone,
    "search:recordOwnedBy" character varying,
    "search:recordPublishedBy" character varying,
    "ceasn:listID" character varying,
    envelope_community_id bigint,
    public_record boolean DEFAULT true NOT NULL
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
-- Name: i_ctdl_ceasn_codedNotation_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_codedNotation_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:codedNotation")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_codedNotation_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_codedNotation_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:codedNotation" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_comment_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_comment_en_us_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:comment_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_comment_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_comment_en_us_trgm ON public.indexed_envelope_resources USING gin ("ceasn:comment_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_comment_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_comment_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:comment")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_comment_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_comment_trgm ON public.indexed_envelope_resources USING gin ("ceasn:comment" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_competencyCategory_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyCategory_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:competencyCategory_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_competencyCategory_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyCategory_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:competencyCategory_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_competencyCategory_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyCategory_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:competencyCategory")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_competencyCategory_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyCategory_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:competencyCategory" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_competencyLabel_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyLabel_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:competencyLabel_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_competencyLabel_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyLabel_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:competencyLabel_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_competencyLabel_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyLabel_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:competencyLabel")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_competencyLabel_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyLabel_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:competencyLabel" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_competencyText_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyText_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:competencyText_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_competencyText_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyText_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:competencyText_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_competencyText_fr_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyText_fr_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('french'::regconfig, translate(("ceasn:competencyText_fr")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_competencyText_fr_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyText_fr_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:competencyText_fr" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_competencyText_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyText_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:competencyText")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_competencyText_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_competencyText_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:competencyText" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_conceptKeyword_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_conceptKeyword_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:conceptKeyword_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_conceptKeyword_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_conceptKeyword_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:conceptKeyword_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_conceptKeyword_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_conceptKeyword_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:conceptKeyword")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_conceptKeyword_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_conceptKeyword_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:conceptKeyword" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_dateCreated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_dateCreated" ON public.indexed_envelope_resources USING gin ("ceasn:dateCreated");


--
-- Name: i_ctdl_ceasn_dateModified; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_dateModified" ON public.indexed_envelope_resources USING gin ("ceasn:dateModified");


--
-- Name: i_ctdl_ceasn_description_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_description_en_us_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:description_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_description_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_description_en_us_trgm ON public.indexed_envelope_resources USING gin ("ceasn:description_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_description_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_description_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:description")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_description_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_description_trgm ON public.indexed_envelope_resources USING gin ("ceasn:description" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_inLanguage; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_inLanguage" ON public.indexed_envelope_resources USING gin ("ceasn:inLanguage");


--
-- Name: i_ctdl_ceasn_listID_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_listID_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:listID")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_listID_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_listID_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:listID" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_name_en_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_name_en_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:name_en")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_name_en_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_name_en_trgm ON public.indexed_envelope_resources USING gin ("ceasn:name_en" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_name_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_name_en_us_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:name_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_name_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_name_en_us_trgm ON public.indexed_envelope_resources USING gin ("ceasn:name_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_name_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_name_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:name")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceasn_name_trgm ON public.indexed_envelope_resources USING gin ("ceasn:name" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_publisherName_en_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_publisherName_en_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:publisherName_en")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_publisherName_en_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_publisherName_en_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:publisherName_en" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_publisherName_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_publisherName_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:publisherName_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_publisherName_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_publisherName_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:publisherName_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceasn_publisherName_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_publisherName_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceasn:publisherName")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceasn_publisherName_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceasn_publisherName_trgm" ON public.indexed_envelope_resources USING gin ("ceasn:publisherName" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_addressCountry_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressCountry_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:addressCountry_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_addressCountry_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressCountry_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:addressCountry_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_addressCountry_es_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressCountry_es_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('spanish'::regconfig, translate(("ceterms:addressCountry_es")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_addressCountry_es_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressCountry_es_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:addressCountry_es" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_addressCountry_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressCountry_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:addressCountry")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_addressCountry_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressCountry_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:addressCountry" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_addressLocality_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressLocality_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:addressLocality_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_addressLocality_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressLocality_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:addressLocality_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_addressLocality_es_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressLocality_es_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('spanish'::regconfig, translate(("ceterms:addressLocality_es")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_addressLocality_es_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressLocality_es_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:addressLocality_es" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_addressLocality_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressLocality_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:addressLocality")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_addressLocality_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressLocality_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:addressLocality" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_addressRegion_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressRegion_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:addressRegion_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_addressRegion_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressRegion_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:addressRegion_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_addressRegion_es_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressRegion_es_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('spanish'::regconfig, translate(("ceterms:addressRegion_es")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_addressRegion_es_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressRegion_es_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:addressRegion_es" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_addressRegion_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressRegion_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:addressRegion")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_addressRegion_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_addressRegion_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:addressRegion" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_agentPurposeDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_agentPurposeDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:agentPurposeDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_agentPurposeDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_agentPurposeDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:agentPurposeDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_agentPurposeDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_agentPurposeDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:agentPurposeDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_agentPurposeDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_agentPurposeDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:agentPurposeDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_alternateName_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_alternateName_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:alternateName_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_alternateName_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_alternateName_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:alternateName_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_alternateName_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_alternateName_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:alternateName")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_alternateName_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_alternateName_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:alternateName" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_assessmentExampleDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentExampleDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:assessmentExampleDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_assessmentExampleDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentExampleDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:assessmentExampleDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_assessmentExampleDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentExampleDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:assessmentExampleDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_assessmentExampleDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentExampleDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:assessmentExampleDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_assessmentMethodDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentMethodDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:assessmentMethodDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_assessmentMethodDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentMethodDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:assessmentMethodDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_assessmentMethodDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentMethodDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:assessmentMethodDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_assessmentMethodDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentMethodDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:assessmentMethodDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_assessmentOutput_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentOutput_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:assessmentOutput_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_assessmentOutput_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentOutput_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:assessmentOutput_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_assessmentOutput_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentOutput_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:assessmentOutput")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_assessmentOutput_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_assessmentOutput_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:assessmentOutput" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_codedNotation_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_codedNotation_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:codedNotation")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_codedNotation_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_codedNotation_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:codedNotation" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_condition_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_condition_en_us_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:condition_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_condition_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_condition_en_us_trgm ON public.indexed_envelope_resources USING gin ("ceterms:condition_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_condition_es_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_condition_es_fts ON public.indexed_envelope_resources USING gin (to_tsvector('spanish'::regconfig, translate(("ceterms:condition_es")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_condition_es_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_condition_es_trgm ON public.indexed_envelope_resources USING gin ("ceterms:condition_es" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_condition_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_condition_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:condition")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_condition_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_condition_trgm ON public.indexed_envelope_resources USING gin ("ceterms:condition" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_contactType_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_contactType_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:contactType_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_contactType_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_contactType_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:contactType_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_contactType_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_contactType_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:contactType")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_contactType_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_contactType_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:contactType" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_credentialId_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_credentialId_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:credentialId")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_credentialId_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_credentialId_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:credentialId" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_creditUnitTypeDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_creditUnitTypeDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:creditUnitTypeDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_creditUnitTypeDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_creditUnitTypeDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:creditUnitTypeDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_creditUnitTypeDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_creditUnitTypeDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:creditUnitTypeDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_creditUnitTypeDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_creditUnitTypeDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:creditUnitTypeDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_ctid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX i_ctdl_ceterms_ctid ON public.indexed_envelope_resources USING btree (envelope_community_id, "ceterms:ctid");


--
-- Name: i_ctdl_ceterms_ctid_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_ctid_trgm ON public.indexed_envelope_resources USING gin ("ceterms:ctid" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_currency_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_currency_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:currency")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_currency_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_currency_trgm ON public.indexed_envelope_resources USING gin ("ceterms:currency" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_dateEffective; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_dateEffective" ON public.indexed_envelope_resources USING gin ("ceterms:dateEffective");


--
-- Name: i_ctdl_ceterms_deliveryTypeDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_deliveryTypeDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:deliveryTypeDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_deliveryTypeDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_deliveryTypeDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:deliveryTypeDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_deliveryTypeDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_deliveryTypeDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:deliveryTypeDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_deliveryTypeDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_deliveryTypeDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:deliveryTypeDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_demographicInformation_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_demographicInformation_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:demographicInformation_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_demographicInformation_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_demographicInformation_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:demographicInformation_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_demographicInformation_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_demographicInformation_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:demographicInformation")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_demographicInformation_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_demographicInformation_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:demographicInformation" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_description_en_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_en_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:description_en")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_description_en_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_en_trgm ON public.indexed_envelope_resources USING gin ("ceterms:description_en" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_description_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_en_us_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:description_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_description_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_en_us_trgm ON public.indexed_envelope_resources USING gin ("ceterms:description_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_description_es_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_es_fts ON public.indexed_envelope_resources USING gin (to_tsvector('spanish'::regconfig, translate(("ceterms:description_es")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_description_es_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_es_trgm ON public.indexed_envelope_resources USING gin ("ceterms:description_es" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_description_fr_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_fr_fts ON public.indexed_envelope_resources USING gin (to_tsvector('french'::regconfig, translate(("ceterms:description_fr")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_description_fr_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_fr_trgm ON public.indexed_envelope_resources USING gin ("ceterms:description_fr" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_description_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:description")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_description_nl_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_nl_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:description_nl")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_description_nl_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_nl_trgm ON public.indexed_envelope_resources USING gin ("ceterms:description_nl" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_description_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_description_trgm ON public.indexed_envelope_resources USING gin ("ceterms:description" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_duns_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_duns_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:duns")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_duns_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_duns_trgm ON public.indexed_envelope_resources USING gin ("ceterms:duns" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_email_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_email_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:email")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_email_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_email_trgm ON public.indexed_envelope_resources USING gin ("ceterms:email" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_endDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_endDate" ON public.indexed_envelope_resources USING gin ("ceterms:endDate");


--
-- Name: i_ctdl_ceterms_exactDuration; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_exactDuration" ON public.indexed_envelope_resources USING gin ("ceterms:exactDuration");


--
-- Name: i_ctdl_ceterms_experience_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_experience_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:experience")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_experience_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_experience_trgm ON public.indexed_envelope_resources USING gin ("ceterms:experience" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_expirationDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_expirationDate" ON public.indexed_envelope_resources USING gin ("ceterms:expirationDate");


--
-- Name: i_ctdl_ceterms_faxNumber_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_faxNumber_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:faxNumber")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_faxNumber_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_faxNumber_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:faxNumber" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_fein_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_fein_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:fein")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_fein_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_fein_trgm ON public.indexed_envelope_resources USING gin ("ceterms:fein" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_foundingDate_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_foundingDate_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:foundingDate")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_foundingDate_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_foundingDate_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:foundingDate" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_frameworkName_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_frameworkName_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:frameworkName_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_frameworkName_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_frameworkName_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:frameworkName_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_frameworkName_es_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_frameworkName_es_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('spanish'::regconfig, translate(("ceterms:frameworkName_es")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_frameworkName_es_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_frameworkName_es_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:frameworkName_es" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_frameworkName_fr_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_frameworkName_fr_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('french'::regconfig, translate(("ceterms:frameworkName_fr")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_frameworkName_fr_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_frameworkName_fr_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:frameworkName_fr" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_frameworkName_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_frameworkName_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:frameworkName")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_frameworkName_nl_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_frameworkName_nl_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:frameworkName_nl")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_frameworkName_nl_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_frameworkName_nl_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:frameworkName_nl" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_frameworkName_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_frameworkName_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:frameworkName" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_globalJurisdiction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_globalJurisdiction" ON public.indexed_envelope_resources USING gin ("ceterms:globalJurisdiction");


--
-- Name: i_ctdl_ceterms_hasGroupEvaluation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_hasGroupEvaluation" ON public.indexed_envelope_resources USING gin ("ceterms:hasGroupEvaluation");


--
-- Name: i_ctdl_ceterms_hasGroupParticipation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_hasGroupParticipation" ON public.indexed_envelope_resources USING gin ("ceterms:hasGroupParticipation");


--
-- Name: i_ctdl_ceterms_highEarnings; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_highEarnings" ON public.indexed_envelope_resources USING gin ("ceterms:highEarnings");


--
-- Name: i_ctdl_ceterms_holderMustAuthorize; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_holderMustAuthorize" ON public.indexed_envelope_resources USING gin ("ceterms:holderMustAuthorize");


--
-- Name: i_ctdl_ceterms_identifierTypeName_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_identifierTypeName_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:identifierTypeName_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_identifierTypeName_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_identifierTypeName_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:identifierTypeName_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_identifierTypeName_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_identifierTypeName_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:identifierTypeName")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_identifierTypeName_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_identifierTypeName_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:identifierTypeName" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_identifierValueCode_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_identifierValueCode_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:identifierValueCode")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_identifierValueCode_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_identifierValueCode_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:identifierValueCode" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_inLanguage; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_inLanguage" ON public.indexed_envelope_resources USING gin ("ceterms:inLanguage");


--
-- Name: i_ctdl_ceterms_ipedsID_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_ipedsID_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:ipedsID")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_ipedsID_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_ipedsID_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:ipedsID" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_isProctored; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_isProctored" ON public.indexed_envelope_resources USING gin ("ceterms:isProctored");


--
-- Name: i_ctdl_ceterms_isicV4_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_isicV4_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:isicV4")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_isicV4_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_isicV4_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:isicV4" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_keyword_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_keyword_en_us_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:keyword_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_keyword_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_keyword_en_us_trgm ON public.indexed_envelope_resources USING gin ("ceterms:keyword_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_keyword_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_keyword_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:keyword")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_keyword_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_keyword_trgm ON public.indexed_envelope_resources USING gin ("ceterms:keyword" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_latitude; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_latitude ON public.indexed_envelope_resources USING gin ("ceterms:latitude");


--
-- Name: i_ctdl_ceterms_learningMethodDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_learningMethodDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:learningMethodDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_learningMethodDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_learningMethodDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:learningMethodDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_learningMethodDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_learningMethodDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:learningMethodDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_learningMethodDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_learningMethodDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:learningMethodDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_leiCode_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_leiCode_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:leiCode")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_leiCode_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_leiCode_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:leiCode" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_longitude; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_longitude ON public.indexed_envelope_resources USING gin ("ceterms:longitude");


--
-- Name: i_ctdl_ceterms_lowEarnings; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_lowEarnings" ON public.indexed_envelope_resources USING gin ("ceterms:lowEarnings");


--
-- Name: i_ctdl_ceterms_maximumDuration; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_maximumDuration" ON public.indexed_envelope_resources USING gin ("ceterms:maximumDuration");


--
-- Name: i_ctdl_ceterms_medianEarnings; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_medianEarnings" ON public.indexed_envelope_resources USING gin ("ceterms:medianEarnings");


--
-- Name: i_ctdl_ceterms_minimumAge; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_minimumAge" ON public.indexed_envelope_resources USING gin ("ceterms:minimumAge");


--
-- Name: i_ctdl_ceterms_minimumDuration; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_minimumDuration" ON public.indexed_envelope_resources USING gin ("ceterms:minimumDuration");


--
-- Name: i_ctdl_ceterms_missionAndGoalsStatementDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_missionAndGoalsStatementDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:missionAndGoalsStatementDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_missionAndGoalsStatementDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_missionAndGoalsStatementDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:missionAndGoalsStatementDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_missionAndGoalsStatementDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_missionAndGoalsStatementDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:missionAndGoalsStatementDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_missionAndGoalsStatementDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_missionAndGoalsStatementDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:missionAndGoalsStatementDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_naics_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_naics_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:naics")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_naics_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_naics_trgm ON public.indexed_envelope_resources USING gin ("ceterms:naics" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_name_en_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_en_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:name_en")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_name_en_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_en_trgm ON public.indexed_envelope_resources USING gin ("ceterms:name_en" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_name_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_en_us_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:name_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_name_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_en_us_trgm ON public.indexed_envelope_resources USING gin ("ceterms:name_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_name_es_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_es_fts ON public.indexed_envelope_resources USING gin (to_tsvector('spanish'::regconfig, translate(("ceterms:name_es")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_name_es_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_es_trgm ON public.indexed_envelope_resources USING gin ("ceterms:name_es" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_name_fr_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_fr_fts ON public.indexed_envelope_resources USING gin (to_tsvector('french'::regconfig, translate(("ceterms:name_fr")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_name_fr_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_fr_trgm ON public.indexed_envelope_resources USING gin ("ceterms:name_fr" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_name_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:name")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_name_nl_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_nl_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:name_nl")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_name_nl_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_nl_trgm ON public.indexed_envelope_resources USING gin ("ceterms:name_nl" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_name_trgm ON public.indexed_envelope_resources USING gin ("ceterms:name" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_numberAwarded; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_numberAwarded" ON public.indexed_envelope_resources USING gin ("ceterms:numberAwarded");


--
-- Name: i_ctdl_ceterms_opeID_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_opeID_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:opeID")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_opeID_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_opeID_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:opeID" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_paymentPattern_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_paymentPattern_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:paymentPattern_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_paymentPattern_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_paymentPattern_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:paymentPattern_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_paymentPattern_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_paymentPattern_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:paymentPattern")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_paymentPattern_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_paymentPattern_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:paymentPattern" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_postOfficeBoxNumber_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_postOfficeBoxNumber_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:postOfficeBoxNumber")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_postOfficeBoxNumber_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_postOfficeBoxNumber_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:postOfficeBoxNumber" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_postReceiptMonths; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_postReceiptMonths" ON public.indexed_envelope_resources USING gin ("ceterms:postReceiptMonths");


--
-- Name: i_ctdl_ceterms_postalCode_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_postalCode_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:postalCode")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_postalCode_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_postalCode_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:postalCode" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_price ON public.indexed_envelope_resources USING gin ("ceterms:price");


--
-- Name: i_ctdl_ceterms_processFrequency_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processFrequency_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:processFrequency_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_processFrequency_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processFrequency_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:processFrequency_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_processFrequency_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processFrequency_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:processFrequency")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_processFrequency_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processFrequency_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:processFrequency" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_processMethodDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processMethodDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:processMethodDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_processMethodDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processMethodDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:processMethodDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_processMethodDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processMethodDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:processMethodDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_processMethodDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processMethodDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:processMethodDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_processStandardsDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processStandardsDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:processStandardsDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_processStandardsDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processStandardsDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:processStandardsDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_processStandardsDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processStandardsDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:processStandardsDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_processStandardsDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_processStandardsDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:processStandardsDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_renewalFrequency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_renewalFrequency" ON public.indexed_envelope_resources USING gin ("ceterms:renewalFrequency");


--
-- Name: i_ctdl_ceterms_requiredNumber; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_requiredNumber" ON public.indexed_envelope_resources USING gin ("ceterms:requiredNumber");


--
-- Name: i_ctdl_ceterms_revocationCriteriaDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_revocationCriteriaDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:revocationCriteriaDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_revocationCriteriaDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_revocationCriteriaDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:revocationCriteriaDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_revocationCriteriaDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_revocationCriteriaDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:revocationCriteriaDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_revocationCriteriaDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_revocationCriteriaDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:revocationCriteriaDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_scoringMethodDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_scoringMethodDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:scoringMethodDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_scoringMethodDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_scoringMethodDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:scoringMethodDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_scoringMethodDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_scoringMethodDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:scoringMethodDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_scoringMethodDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_scoringMethodDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:scoringMethodDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_scoringMethodExampleDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_scoringMethodExampleDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:scoringMethodExampleDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_scoringMethodExampleDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_scoringMethodExampleDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:scoringMethodExampleDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_scoringMethodExampleDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_scoringMethodExampleDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:scoringMethodExampleDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_scoringMethodExampleDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_scoringMethodExampleDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:scoringMethodExampleDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_startDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_startDate" ON public.indexed_envelope_resources USING gin ("ceterms:startDate");


--
-- Name: i_ctdl_ceterms_streetAddress_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_streetAddress_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:streetAddress_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_streetAddress_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_streetAddress_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:streetAddress_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_streetAddress_es_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_streetAddress_es_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('spanish'::regconfig, translate(("ceterms:streetAddress_es")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_streetAddress_es_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_streetAddress_es_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:streetAddress_es" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_streetAddress_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_streetAddress_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:streetAddress")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_streetAddress_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_streetAddress_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:streetAddress" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_submissionOfDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_submissionOfDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:submissionOfDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_submissionOfDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_submissionOfDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:submissionOfDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_submissionOfDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_submissionOfDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:submissionOfDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_submissionOfDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_submissionOfDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:submissionOfDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_targetNodeDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:targetNodeDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_targetNodeDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:targetNodeDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_targetNodeDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:targetNodeDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_targetNodeDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:targetNodeDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_targetNodeName_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeName_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:targetNodeName_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_targetNodeName_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeName_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:targetNodeName_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_targetNodeName_es_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeName_es_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('spanish'::regconfig, translate(("ceterms:targetNodeName_es")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_targetNodeName_es_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeName_es_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:targetNodeName_es" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_targetNodeName_fr_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeName_fr_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('french'::regconfig, translate(("ceterms:targetNodeName_fr")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_targetNodeName_fr_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeName_fr_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:targetNodeName_fr" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_targetNodeName_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeName_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:targetNodeName")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_targetNodeName_nl_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeName_nl_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:targetNodeName_nl")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_targetNodeName_nl_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeName_nl_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:targetNodeName_nl" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_targetNodeName_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_targetNodeName_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:targetNodeName" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_telephone_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_telephone_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:telephone")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_telephone_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_telephone_trgm ON public.indexed_envelope_resources USING gin ("ceterms:telephone" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_transferValueStatementDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_transferValueStatementDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:transferValueStatementDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_transferValueStatementDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_transferValueStatementDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:transferValueStatementDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_transferValueStatementDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_transferValueStatementDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:transferValueStatementDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_transferValueStatementDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_transferValueStatementDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:transferValueStatementDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_verificationMethodDescription_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_verificationMethodDescription_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:verificationMethodDescription_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_verificationMethodDescription_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_verificationMethodDescription_en_us_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:verificationMethodDescription_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_verificationMethodDescription_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_verificationMethodDescription_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("ceterms:verificationMethodDescription")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_ceterms_verificationMethodDescription_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_verificationMethodDescription_trgm" ON public.indexed_envelope_resources USING gin ("ceterms:verificationMethodDescription" public.gin_trgm_ops);


--
-- Name: i_ctdl_ceterms_weight; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_ceterms_weight ON public.indexed_envelope_resources USING gin ("ceterms:weight");


--
-- Name: i_ctdl_ceterms_yearsOfExperience; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_ceterms_yearsOfExperience" ON public.indexed_envelope_resources USING gin ("ceterms:yearsOfExperience");


--
-- Name: i_ctdl_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX i_ctdl_id ON public.indexed_envelope_resources USING btree ("@id");


--
-- Name: i_ctdl_id_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_id_trgm ON public.indexed_envelope_resources USING gin ("@id" public.gin_trgm_ops);


--
-- Name: i_ctdl_qdata_adjustment_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_qdata_adjustment_en_us_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("qdata:adjustment_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_qdata_adjustment_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_qdata_adjustment_en_us_trgm ON public.indexed_envelope_resources USING gin ("qdata:adjustment_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_qdata_adjustment_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_qdata_adjustment_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("qdata:adjustment")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_qdata_adjustment_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_qdata_adjustment_trgm ON public.indexed_envelope_resources USING gin ("qdata:adjustment" public.gin_trgm_ops);


--
-- Name: i_ctdl_qdata_earningsDefinition_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_earningsDefinition_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("qdata:earningsDefinition_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_qdata_earningsDefinition_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_earningsDefinition_en_us_trgm" ON public.indexed_envelope_resources USING gin ("qdata:earningsDefinition_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_qdata_earningsDefinition_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_earningsDefinition_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("qdata:earningsDefinition")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_qdata_earningsDefinition_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_earningsDefinition_trgm" ON public.indexed_envelope_resources USING gin ("qdata:earningsDefinition" public.gin_trgm_ops);


--
-- Name: i_ctdl_qdata_employmentDefinition_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_employmentDefinition_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("qdata:employmentDefinition_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_qdata_employmentDefinition_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_employmentDefinition_en_us_trgm" ON public.indexed_envelope_resources USING gin ("qdata:employmentDefinition_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_qdata_employmentDefinition_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_employmentDefinition_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("qdata:employmentDefinition")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_qdata_employmentDefinition_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_employmentDefinition_trgm" ON public.indexed_envelope_resources USING gin ("qdata:employmentDefinition" public.gin_trgm_ops);


--
-- Name: i_ctdl_qdata_median; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_qdata_median ON public.indexed_envelope_resources USING gin ("qdata:median");


--
-- Name: i_ctdl_qdata_percentage; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_qdata_percentage ON public.indexed_envelope_resources USING gin ("qdata:percentage");


--
-- Name: i_ctdl_qdata_percentile10; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_qdata_percentile10 ON public.indexed_envelope_resources USING gin ("qdata:percentile10");


--
-- Name: i_ctdl_qdata_percentile25; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_qdata_percentile25 ON public.indexed_envelope_resources USING gin ("qdata:percentile25");


--
-- Name: i_ctdl_qdata_percentile75; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_qdata_percentile75 ON public.indexed_envelope_resources USING gin ("qdata:percentile75");


--
-- Name: i_ctdl_qdata_percentile90; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_qdata_percentile90 ON public.indexed_envelope_resources USING gin ("qdata:percentile90");


--
-- Name: i_ctdl_qdata_workTimeThreshold_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_workTimeThreshold_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("qdata:workTimeThreshold_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_qdata_workTimeThreshold_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_workTimeThreshold_en_us_trgm" ON public.indexed_envelope_resources USING gin ("qdata:workTimeThreshold_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_qdata_workTimeThreshold_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_workTimeThreshold_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("qdata:workTimeThreshold")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_qdata_workTimeThreshold_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_qdata_workTimeThreshold_trgm" ON public.indexed_envelope_resources USING gin ("qdata:workTimeThreshold" public.gin_trgm_ops);


--
-- Name: i_ctdl_schema_currency_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_schema_currency_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("schema:currency")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_schema_currency_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_schema_currency_trgm ON public.indexed_envelope_resources USING gin ("schema:currency" public.gin_trgm_ops);


--
-- Name: i_ctdl_schema_description_en_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_schema_description_en_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("schema:description_en")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_schema_description_en_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_schema_description_en_trgm ON public.indexed_envelope_resources USING gin ("schema:description_en" public.gin_trgm_ops);


--
-- Name: i_ctdl_schema_description_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_schema_description_en_us_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("schema:description_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_schema_description_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_schema_description_en_us_trgm ON public.indexed_envelope_resources USING gin ("schema:description_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_schema_description_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_schema_description_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("schema:description")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_schema_description_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_schema_description_trgm ON public.indexed_envelope_resources USING gin ("schema:description" public.gin_trgm_ops);


--
-- Name: i_ctdl_schema_maxValue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_schema_maxValue" ON public.indexed_envelope_resources USING gin ("schema:maxValue");


--
-- Name: i_ctdl_schema_minValue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_schema_minValue" ON public.indexed_envelope_resources USING gin ("schema:minValue");


--
-- Name: i_ctdl_schema_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_schema_value ON public.indexed_envelope_resources USING gin ("schema:value");


--
-- Name: i_ctdl_skos_definition_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_skos_definition_en_us_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("skos:definition_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_skos_definition_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_skos_definition_en_us_trgm ON public.indexed_envelope_resources USING gin ("skos:definition_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_skos_definition_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_skos_definition_fts ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("skos:definition")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_skos_definition_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX i_ctdl_skos_definition_trgm ON public.indexed_envelope_resources USING gin ("skos:definition" public.gin_trgm_ops);


--
-- Name: i_ctdl_skos_prefLabel_en_us_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_skos_prefLabel_en_us_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("skos:prefLabel_en_us")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_skos_prefLabel_en_us_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_skos_prefLabel_en_us_trgm" ON public.indexed_envelope_resources USING gin ("skos:prefLabel_en_us" public.gin_trgm_ops);


--
-- Name: i_ctdl_skos_prefLabel_fts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_skos_prefLabel_fts" ON public.indexed_envelope_resources USING gin (to_tsvector('english'::regconfig, translate(("skos:prefLabel")::text, '/.'::text, ' '::text)));


--
-- Name: i_ctdl_skos_prefLabel_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "i_ctdl_skos_prefLabel_trgm" ON public.indexed_envelope_resources USING gin ("skos:prefLabel" public.gin_trgm_ops);


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
-- Name: index_description_sets_on_ceterms_ctid_and_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_description_sets_on_ceterms_ctid_and_path ON public.description_sets USING btree (ceterms_ctid, path);


--
-- Name: index_envelope_communities_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_envelope_communities_on_name ON public.envelope_communities USING btree (name);


--
-- Name: index_envelope_community_configs_on_envelope_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_community_configs_on_envelope_community_id ON public.envelope_community_configs USING btree (envelope_community_id);


--
-- Name: index_envelope_resources_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_resources_on_created_at ON public.envelope_resources USING btree (created_at);


--
-- Name: index_envelope_resources_on_envelope_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelope_resources_on_envelope_id ON public.envelope_resources USING btree (envelope_id);


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
-- Name: index_envelopes_on_publishing_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_publishing_organization_id ON public.envelopes USING btree (publishing_organization_id);


--
-- Name: index_envelopes_on_purged_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_envelopes_on_purged_at ON public.envelopes USING btree (purged_at);


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
-- Name: index_indexed_envelope_resources_on_envelope_community_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_indexed_envelope_resources_on_envelope_community_id ON public.indexed_envelope_resources USING btree (envelope_community_id);


--
-- Name: index_indexed_envelope_resources_on_envelope_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_indexed_envelope_resources_on_envelope_resource_id ON public.indexed_envelope_resources USING btree (envelope_resource_id);


--
-- Name: index_indexed_envelope_resources_on_public_record; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_indexed_envelope_resources_on_public_record ON public.indexed_envelope_resources USING btree (public_record);


--
-- Name: index_indexed_envelope_resources_on_search:recordCreated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_indexed_envelope_resources_on_search:recordCreated" ON public.indexed_envelope_resources USING btree ("search:recordCreated");


--
-- Name: index_indexed_envelope_resources_on_search:recordOwnedBy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_indexed_envelope_resources_on_search:recordOwnedBy" ON public.indexed_envelope_resources USING btree ("search:recordOwnedBy");


--
-- Name: index_indexed_envelope_resources_on_search:recordPublishedBy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_indexed_envelope_resources_on_search:recordPublishedBy" ON public.indexed_envelope_resources USING btree ("search:recordPublishedBy");


--
-- Name: index_indexed_envelope_resources_on_search:recordUpdated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_indexed_envelope_resources_on_search:recordUpdated" ON public.indexed_envelope_resources USING btree ("search:recordUpdated");


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
-- Name: envelope_resources envelope_resources_fts_tsvector_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER envelope_resources_fts_tsvector_update BEFORE INSERT OR UPDATE ON public.envelope_resources FOR EACH ROW EXECUTE FUNCTION tsvector_update_trigger('fts_tsearch_tsv', 'pg_catalog.simple', 'fts_tsearch');


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
-- Name: indexed_envelope_resources fk_rails_c60fb7e0b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resources
    ADD CONSTRAINT fk_rails_c60fb7e0b6 FOREIGN KEY ("search:recordOwnedBy") REFERENCES public.organizations(_ctid) ON DELETE SET NULL;


--
-- Name: indexed_envelope_resources fk_rails_c8621e74fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indexed_envelope_resources
    ADD CONSTRAINT fk_rails_c8621e74fd FOREIGN KEY ("search:recordPublishedBy") REFERENCES public.organizations(_ctid) ON DELETE SET NULL;


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
('20160223171632'),
('20160407152817'),
('20160414152951'),
('20160505094815'),
('20160505095021'),
('20160524095936'),
('20160527073357'),
('20160824194535'),
('20160824224410'),
('20160824225705'),
('20160825034410'),
('20161101121532'),
('20161108105842'),
('20170312011508'),
('20170412045538'),
('20171101152316'),
('20171101161031'),
('20171101194114'),
('20171101194708'),
('20171101205513'),
('20171101211441'),
('20171104152617'),
('20171109230956'),
('20171113221325'),
('20171121222132'),
('20171215172051'),
('20180301172831'),
('20180713130937'),
('20180725215953'),
('20180727204436'),
('20180727234351'),
('20180729125600'),
('20181001205658'),
('20181107021512'),
('20181121213645'),
('20190227225740'),
('20190919121231'),
('20191024081858'),
('20200601094240'),
('20200727085544'),
('20200813121714'),
('20200922150215'),
('20200922150449'),
('20201012074942'),
('20210121082610'),
('20210311135955'),
('20210513043719'),
('20210601020245'),
('20210624173908'),
('20210715141032'),
('20211207110948'),
('20220106130200'),
('20220113141414'),
('20220314181045');



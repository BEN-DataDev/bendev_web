


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


CREATE SCHEMA IF NOT EXISTS "data_abs";


ALTER SCHEMA "data_abs" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "data_gsa";


ALTER SCHEMA "data_gsa" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "data_ssnsw";


ALTER SCHEMA "data_ssnsw" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgsodium";






CREATE SCHEMA IF NOT EXISTS "projects";


ALTER SCHEMA "projects" OWNER TO "postgres";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "http" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgrouting" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "postgis_raster" WITH SCHEMA "extensions";






CREATE SCHEMA IF NOT EXISTS "topology";
CREATE EXTENSION IF NOT EXISTS "postgis_topology" WITH SCHEMA "topology";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."role_name" AS ENUM (
    'owner',
    'admin',
    'editor',
    'gis',
    'viewer',
    'moderator',
    'member',
    'system_admin',
    'system_moderator'
);


ALTER TYPE "public"."role_name" OWNER TO "postgres";


CREATE TYPE "public"."role_type" AS ENUM (
    'project',
    'community',
    'global'
);


ALTER TYPE "public"."role_type" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_entity_id"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.role_type = 'project' THEN
        IF NOT EXISTS(SELECT 1 FROM public.projects WHERE id = NEW.entity_id) THEN
            RAISE EXCEPTION 'Invalid project_id';
        END IF;
    ELSIF NEW.role_type = 'community' THEN
        IF NOT EXISTS(SELECT 1 FROM public.community WHERE id = NEW.entity_id) THEN
            RAISE EXCEPTION 'Invalid community_id';
        END IF;
    ELSIF NEW.role_type = 'global' THEN
        IF NEW.entity_id IS NOT NULL THEN
            RAISE EXCEPTION 'Global role should not have an entity_id';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_entity_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."custom_access_token_hook"("event" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
declare
  claims jsonb;
  user_roles jsonb;
begin
  -- Fetch the user roles from the user_roles table
  select jsonb_agg(
    jsonb_build_object(
      'role_type', role_type,
      'role_name', role_name,
      'entity_id', entity_id
    )
  )
  into user_roles
  from public.user_roles
  where user_id = (event->>'user_id')::uuid;

  claims := event->'claims';

  if user_roles is not null then
    -- Set the claim with the array of user roles
    claims := jsonb_set(claims, '{user_roles}', user_roles);
  else
    claims := jsonb_set(claims, '{user_roles}', '[]'::jsonb);
  end if;

  -- Update the 'claims' object in the original event
  event := jsonb_set(event, '{claims}', claims);

  -- Return the modified event
  return event;
end;
$$;


ALTER FUNCTION "public"."custom_access_token_hook"("event" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_orphaned_user_roles"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    DELETE FROM public.user_roles
    WHERE entity_id = OLD.id AND 
          ((TG_TABLE_NAME = 'projects' AND role_type = 'project') OR
           (TG_TABLE_NAME = 'community' AND role_type = 'community'));
    RETURN OLD;
END;
$$;


ALTER FUNCTION "public"."delete_orphaned_user_roles"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dev_download_crownlands"("use_get" boolean DEFAULT false, "delay_seconds" integer DEFAULT 2) RETURNS json
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    var_coordinates json;
    var_response text;
    var_geojson json;
    var_crownlands_response text;
    var_total_count integer;
    var_offset integer := 0;
    var_batch_size integer := 2000;
    var_base_url text;
    var_query_url text;
    var_count_url text;
    var_url text;
    var_features_count integer;
    var_retry_count integer := 0;
    var_max_retries integer := 3;
BEGIN
    -- Get LGA boundaries
    SELECT content INTO var_response
    FROM http_post(
      'https://portal.spatial.nsw.gov.au/server/rest/services/NSW_Administrative_Boundaries_Theme/FeatureServer/8/query',
      'where=lganame%3D%27SNOWY+VALLEYS%27&f=geojson',
      'application/x-www-form-urlencoded'
    ) AS lgs_response;

    SELECT (var_response::json)->'features'->0->'geometry'->'coordinates' INTO var_coordinates;

    -- Prepare base URL for Crown Land queries
    var_base_url := 'https://mapprod3.environment.nsw.gov.au/arcgis/rest/services/ePlanning/Planning_Portal_Crown_Land/MapServer//258/query';
    var_count_url :='geometry=' || urlencode('{"rings":' || var_coordinates::text || '}') ||
               '&geometryType=esriGeometryPolygon&inSR=4283&spatialRel=esriSpatialRelIntersects&returnCountOnly=true&f=geojson';

    -- Get total count
    SELECT content::json->>'count' INTO var_total_count
    FROM http_post(var_base_url, var_count_url, 'application/x-www-form-urlencoded');

    RAISE LOG 'Total count of Crown Land features: %', var_total_count;

    -- Truncate the target table if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'data_ssnsw' AND table_name = 'crownlands_json') THEN
        EXECUTE 'TRUNCATE TABLE data_ssnsw.crownlands_json';
    END IF;

    -- Create the table if it doesn't exist
    EXECUTE '
    CREATE TABLE IF NOT EXISTS data_ssnsw.crownlands_json (
        id serial PRIMARY KEY,
        feature jsonb
    )';

    -- Start a transaction
    BEGIN
        -- Fetch and insert data in batches
        WHILE var_offset < var_total_count LOOP
            RAISE LOG 'var_batch_size % var_offset %', var_batch_size, var_offset;
            
            var_query_url := 'geometry=' || urlencode('{"rings":' || var_coordinates::text || '}') ||
                   '&geometryType=esriGeometryPolygon&inSR=4283&spatialRel=esriSpatialRelIntersects&outSR=7844&outFields=*' ||
                   '&resultRecordCount=' || var_batch_size || '&resultOffset=' || var_offset || '&f=geojson';

            RAISE LOG 'var_query_url:: %', right(var_query_url, 100);
                   
            -- Retry logic
            <<retry_loop>>
            WHILE var_retry_count < var_max_retries LOOP
                BEGIN
                    -- Use either GET or POST based on the input parameter
                    IF use_get THEN
                        SELECT content INTO var_crownlands_response
                        FROM http_get(var_base_url || '?' || var_query_url);
                    ELSE
                        SELECT content INTO var_crownlands_response
                        FROM http_post(var_base_url, var_query_url, 'application/x-www-form-urlencoded');
                    END IF;

                    IF var_crownlands_response IS NULL THEN
                        RAISE EXCEPTION 'Crown Land HTTP request returned NULL';
                    END IF;

                    -- If successful, exit the retry loop
                    EXIT retry_loop;
                EXCEPTION
                    WHEN OTHERS THEN
                        var_retry_count := var_retry_count + 1;
                        IF var_retry_count >= var_max_retries THEN
                            RAISE;
                        END IF;
                        PERFORM pg_sleep(power(2, var_retry_count)); -- Exponential backoff
                END;
            END LOOP retry_loop;

            -- Reset retry count
            var_retry_count := 0;

            -- Count the number of features in this batch
            SELECT json_array_length(var_crownlands_response::json->'features') INTO var_features_count;
            
            RAISE LOG 'Batch starting at offset % returned % features', var_offset, var_features_count;
            
            -- Bulk insert the batch into the table
            INSERT INTO data_ssnsw.crownlands_json (feature)
            SELECT json_array_elements(var_crownlands_response::json->'features');

            RAISE LOG 'Inserted % records in this batch', 
                (SELECT count(*) FROM data_ssnsw.crownlands_json) - 
                (SELECT count(*) FROM data_ssnsw.crownlands_json WHERE id < (SELECT max(id) FROM data_ssnsw.crownlands_json) - var_features_count + 1);

            var_offset := var_offset + var_batch_size;
            
            RAISE LOG 'Processed % out of % records', LEAST(var_offset, var_total_count), var_total_count;
            
            -- Add delay between requests
            PERFORM pg_sleep(delay_seconds);
        END LOOP;

        -- Commit the transaction
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END;

    -- Return a summary of the operation
    RETURN json_build_object(
        'status', 'success',
        'total_records', var_total_count,
        'records_processed', (SELECT count(*) FROM data_ssnsw.crownlands_json)
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error in Crown Land data processing: %', SQLERRM;
        RETURN json_build_object('error', SQLERRM);
END;
$$;


ALTER FUNCTION "public"."dev_download_crownlands"("use_get" boolean, "delay_seconds" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."dev_process_downloads"("use_get" boolean DEFAULT false, "delay_seconds" integer DEFAULT 2) RETURNS json
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    var_coordinates json;
    var_response text;
    var_geojson json;
    var_crownlands_response text;
    var_total_count integer;
    var_offset integer := 0;
    var_batch_size integer := 2000;
    var_base_url text;
    var_query_url text;
    var_count_url text;
    var_url text;
    var_features_count integer;
    var_retry_count integer := 0;
    var_max_retries integer := 3;
BEGIN
    -- Get LGA boundaries
    SELECT content INTO var_response
    FROM http_post(
      'https://portal.spatial.nsw.gov.au/server/rest/services/NSW_Administrative_Boundaries_Theme/FeatureServer/8/query',
      'where=lganame%3D%27SNOWY+VALLEYS%27&f=geojson',
      'application/x-www-form-urlencoded'
    ) AS lgs_response;

    SELECT (var_response::json)->'features'->0->'geometry'->'coordinates' INTO var_coordinates;

    -- Prepare base URL for Crown Land queries
    var_base_url := 'https://mapprod3.environment.nsw.gov.au/arcgis/rest/services/ePlanning/Planning_Portal_Crown_Land/MapServer//258/query';
    var_count_url :='geometry=' || urlencode('{"rings":' || var_coordinates::text || '}') ||
               '&geometryType=esriGeometryPolygon&inSR=4283&spatialRel=esriSpatialRelIntersects&returnCountOnly=true&f=geojson';

    -- Get total count
    SELECT content::json->>'count' INTO var_total_count
    FROM http_post(var_base_url, var_count_url, 'application/x-www-form-urlencoded');

    RAISE LOG 'Total count of Crown Land features: %', var_total_count;

    -- Truncate the target table if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'data_ssnsw' AND table_name = 'crownlands_json') THEN
        EXECUTE 'TRUNCATE TABLE data_ssnsw.crownlands_json';
    END IF;

    -- Create the table if it doesn't exist
    EXECUTE '
    CREATE TABLE IF NOT EXISTS data_ssnsw.crownlands_json (
        id serial PRIMARY KEY,
        feature jsonb
    )';

    -- Fetch and insert data in batches
    WHILE var_offset < var_total_count LOOP
        RAISE LOG 'var_batch_size % var_offset %', var_batch_size, var_offset;
        
        var_query_url := 'geometry=' || urlencode('{"rings":' || var_coordinates::text || '}') ||
               '&geometryType=esriGeometryPolygon&inSR=4283&spatialRel=esriSpatialRelIntersects&outSR=7844&outFields=*' ||
               '&resultRecordCount=' || var_batch_size || '&resultOffset=' || var_offset || '&f=geojson';

        RAISE LOG 'var_query_url:: %', right(var_query_url, 100);
               
        -- Retry logic
        <<retry_loop>>
        WHILE var_retry_count < var_max_retries LOOP
            BEGIN
                -- Use either GET or POST based on the input parameter
                IF use_get THEN
                    SELECT content INTO var_crownlands_response
                    FROM http_get(var_base_url || '?' || var_query_url);
                ELSE
                    SELECT content INTO var_crownlands_response
                    FROM http_post(var_base_url, var_query_url, 'application/x-www-form-urlencoded');
                END IF;

                IF var_crownlands_response IS NULL THEN
                    RAISE EXCEPTION 'Crown Land HTTP request returned NULL';
                END IF;

                -- If successful, exit the retry loop
                EXIT retry_loop;
            EXCEPTION
                WHEN OTHERS THEN
                    var_retry_count := var_retry_count + 1;
                    IF var_retry_count >= var_max_retries THEN
                        RAISE;
                    END IF;
                    PERFORM pg_sleep(power(2, var_retry_count)); -- Exponential backoff
            END;
        END LOOP retry_loop;

        -- Reset retry count
        var_retry_count := 0;

        -- Count the number of features in this batch
        SELECT json_array_length(var_crownlands_response::json->'features') INTO var_features_count;
        
        RAISE LOG 'Batch starting at offset % returned % features', var_offset, var_features_count;
        
        -- Bulk insert the batch into the table
        INSERT INTO data_ssnsw.crownlands_json (feature)
        SELECT json_array_elements(var_crownlands_response::json->'features');

        RAISE LOG 'Inserted % records in this batch', 
            (SELECT count(*) FROM data_ssnsw.crownlands_json) - 
            (SELECT count(*) FROM data_ssnsw.crownlands_json WHERE id < (SELECT max(id) FROM data_ssnsw.crownlands_json) - var_features_count + 1);

        var_offset := var_offset + var_batch_size;
        
        RAISE LOG 'Processed % out of % records', LEAST(var_offset, var_total_count), var_total_count;
        
        -- Add delay between requests
        PERFORM pg_sleep(delay_seconds);
    END LOOP;

    -- Return a summary of the operation
    RETURN json_build_object(
        'status', 'success',
        'total_records', var_total_count,
        'records_processed', (SELECT count(*) FROM data_ssnsw.crownlands_json)
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error in Crown Land data processing: %', SQLERRM;
        RETURN json_build_object('error', SQLERRM);
END;
$$;


ALTER FUNCTION "public"."dev_process_downloads"("use_get" boolean, "delay_seconds" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_communities_with_transformed_extent"() RETURNS TABLE("id" "uuid", "extent" "extensions"."geometry", "extent_center" numeric[], "extent_bounds" numeric[], "name" "text", "contactinfo" "jsonb", "communityinfo" "jsonb", "created_at" timestamp with time zone, "last_updated" timestamp with time zone, "public" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        ST_Transform(c.extent::geometry, 4326) AS extent,
        ARRAY[
            ST_Y(ST_Centroid(ST_Transform(c.extent::geometry, 4326))),
            ST_X(ST_Centroid(ST_Transform(c.extent::geometry, 4326)))
        ]::numeric[] AS extent_center,
        ARRAY[
            ARRAY[
                ST_YMin(ST_Envelope(ST_Transform(c.extent::geometry, 4326))),
                ST_XMin(ST_Envelope(ST_Transform(c.extent::geometry, 4326)))
            ]::numeric[],
            ARRAY[
                ST_YMax(ST_Envelope(ST_Transform(c.extent::geometry, 4326))),
                ST_XMax(ST_Envelope(ST_Transform(c.extent::geometry, 4326)))
            ]::numeric[]
        ]::numeric[][] AS extent_bounds,
        c.name,
        c.contactinfo,
        c.communityinfo,
        c.created_at,
        c.last_updated,
        c.public
    FROM 
        public.community c;
END;
$$;


ALTER FUNCTION "public"."get_communities_with_transformed_extent"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_community_with_transformed_extent"() RETURNS TABLE("id" "uuid", "extent" "extensions"."geometry", "name" "text", "contactinfo" "jsonb", "communityinfo" "jsonb", "created_at" timestamp with time zone, "last_updated" timestamp with time zone, "public" boolean)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        ST_Transform(c.extent::geometry, 4326) AS extent,
        c.name,
        c.contactinfo,
        c.communityinfo,
        c.created_at,
        c.last_updated,
        c.public
    FROM 
        public.community c;
END;
$$;


ALTER FUNCTION "public"."get_community_with_transformed_extent"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_roles"("user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', ur.id,
            'role_type', ur.role_type,
            'role_name', ur.role_name,
            'entity_id', ur.entity_id,
            'entity_name', CASE 
                WHEN ur.role_type = 'project' THEN p.projectname
                WHEN ur.role_type = 'community' THEN c.name
                ELSE 'Global'
            END,
            'created_at', ur.created_at,
            'last_updated', ur.last_updated
        )
    ) INTO result
    FROM public.user_roles ur
    LEFT JOIN public.projects p ON ur.entity_id = p.id AND ur.role_type = 'project'
    LEFT JOIN public.community c ON ur.entity_id = c.id AND ur.role_type = 'community'
    WHERE ur.user_id = get_user_roles.user_id;

    RETURN COALESCE(result, '[]'::JSONB);
END;
$$;


ALTER FUNCTION "public"."get_user_roles"("user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  raw_meta json;
  firstname TEXT;
  lastname TEXT;
  avatar_path TEXT;
BEGIN
  raw_meta := NEW.raw_user_meta_data;
  
  -- Handle name fields
  IF raw_meta->>'name' IS NOT NULL THEN
    firstname := split_part(raw_meta->>'name', ' ', 1);
    lastname := split_part(raw_meta->>'name', ' ', 2);
  ELSE
    firstname := raw_meta->>'firstName';
    lastname := raw_meta->>'lastName';
  END IF;
  
  -- Handle avatar path
  IF raw_meta->>'picture' IS NOT NULL THEN
    avatar_path := raw_meta->>'picture';
  ELSIF raw_meta->>'avatar_url' IS NOT NULL THEN
    avatar_path := raw_meta->>'avatar_url';
  END IF;
  
  -- Insert or update the userprofile
  INSERT INTO public.userprofile (id, firstname, lastname, avatar_path)
  VALUES (NEW.id, firstname, lastname, avatar_path)
  ON CONFLICT (id) DO UPDATE
  SET firstname = EXCLUDED.firstname,
      lastname = EXCLUDED.lastname,
      avatar_path = EXCLUDED.avatar_path;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."health_check"() RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
    result json;
begin
    -- Update last_check timestamp
    insert into public.health_status (last_check)
    values (now())
    on conflict (id)
    do update set last_check = now()
    returning json_build_object(
        'status', 'healthy',
        'timestamp', last_check
    ) into result;
    
    return result;
end;
$$;


ALTER FUNCTION "public"."health_check"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."remove_user_from_community"("p_userid" "uuid", "p_communityid" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    DELETE FROM public.communities_users
    WHERE userid = p_userid AND communityid = p_communityid;
END;
$$;


ALTER FUNCTION "public"."remove_user_from_community"("p_userid" "uuid", "p_communityid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."remove_user_from_project"("p_userid" "uuid", "p_projectid" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    DELETE FROM public.projects_users
    WHERE userid = p_userid AND projectid = p_projectid;
END;
$$;


ALTER FUNCTION "public"."remove_user_from_project"("p_userid" "uuid", "p_projectid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_existing_users"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_record RECORD;
  raw_meta json;
  firstname TEXT;
  lastname TEXT;
  avatar_path TEXT;
BEGIN
  FOR user_record IN SELECT * FROM auth.users WHERE confirmed_at IS NOT NULL LOOP
    raw_meta := user_record.raw_user_meta_data;
    
    -- Handle name fields
    IF raw_meta->>'name' IS NOT NULL THEN
      firstname := split_part(raw_meta->>'name', ' ', 1);
      lastname := split_part(raw_meta->>'name', ' ', 2);
    ELSE
      firstname := raw_meta->>'firstName';
      lastname := raw_meta->>'lastName';
    END IF;
    
    -- Handle avatar path
    IF raw_meta->>'picture' IS NOT NULL THEN
      avatar_path := raw_meta->>'picture';
    ELSIF raw_meta->>'avatar_url' IS NOT NULL THEN
      avatar_path := raw_meta->>'avatar_url';
    END IF;
    
    -- Insert or update the userprofile
    INSERT INTO public.userprofile (id, firstname, lastname, avatar_path)
    VALUES (user_record.id, firstname, lastname, avatar_path)
    ON CONFLICT (id) DO UPDATE
    SET firstname = EXCLUDED.firstname,
        lastname = EXCLUDED.lastname,
        avatar_path = EXCLUDED.avatar_path;
    
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."sync_existing_users"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_last_updated"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$BEGIN 
    NEW.last_updated  = now() AT TIME ZONE 'utc';   
RETURN NEW;
END;$$;


ALTER FUNCTION "public"."update_last_updated"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_user_role"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.role_type = 'project' THEN
        IF NOT EXISTS(SELECT 1 FROM public.projects WHERE id = NEW.entity_id) THEN
            RAISE EXCEPTION 'Invalid project_id';
        END IF;
    ELSIF NEW.role_type = 'community' THEN
        IF NOT EXISTS(SELECT 1 FROM public.community WHERE id = NEW.entity_id) THEN
            RAISE EXCEPTION 'Invalid community_id';
        END IF;
    ELSIF NEW.role_type = 'global' AND NEW.entity_id IS NOT NULL THEN
        RAISE EXCEPTION 'Global role should not have an entity_id';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_user_role"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "data_ssnsw"."crownenclosurepermits" (
    "id" integer NOT NULL,
    "fid" double precision,
    "cadid" double precision,
    "crownlregno" character varying(10),
    "crownaccountid" double precision,
    "classsubtype_desc" character varying(180),
    "crownaccounttype_desc" character varying(128),
    "definitiontype" character varying(40),
    "lotnumber" character varying(6),
    "sectionnumber" character varying(3),
    "plantype" character varying(1),
    "planno" character varying(8),
    "createdate" timestamp with time zone,
    "modifieddate" timestamp with time zone,
    "lreg_no" character varying(255),
    "office" character varying(60),
    "account_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "tenure_type" character varying(4000),
    "tenure_sub_type" character varying(4000),
    "account_class" character varying(4000),
    "purpose" character varying(4000),
    "geom" "extensions"."geometry"(MultiPolygon,7855)
);


ALTER TABLE "data_ssnsw"."crownenclosurepermits" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "data_ssnsw"."crownenclosurepermits_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "data_ssnsw"."crownenclosurepermits_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "data_ssnsw"."crownenclosurepermits_id_seq" OWNED BY "data_ssnsw"."crownenclosurepermits"."id";



CREATE TABLE IF NOT EXISTS "data_ssnsw"."crownlands" (
    "id" integer NOT NULL,
    "fid" double precision,
    "cadid" double precision,
    "createdate" timestamp with time zone,
    "modifieddate" timestamp with time zone,
    "crownlandstatustype" integer,
    "classsubtype" double precision,
    "disposalstatus" integer,
    "startdate" timestamp with time zone,
    "enddate" timestamp with time zone,
    "lastupdate" timestamp with time zone,
    "packetid" double precision,
    "isprocessed" character varying(1),
    "recordstatus" character varying(32),
    "area_h" double precision,
    "geom" "extensions"."geometry"(MultiPolygon,7855)
);


ALTER TABLE "data_ssnsw"."crownlands" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "data_ssnsw"."crownlands_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "data_ssnsw"."crownlands_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "data_ssnsw"."crownlands_id_seq" OWNED BY "data_ssnsw"."crownlands"."id";



CREATE TABLE IF NOT EXISTS "data_ssnsw"."crownlands_json" (
    "id" integer NOT NULL,
    "feature" "jsonb"
);


ALTER TABLE "data_ssnsw"."crownlands_json" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "data_ssnsw"."crownlands_json_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "data_ssnsw"."crownlands_json_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "data_ssnsw"."crownlands_json_id_seq" OWNED BY "data_ssnsw"."crownlands_json"."id";



CREATE TABLE IF NOT EXISTS "data_ssnsw"."crownleases" (
    "id" integer NOT NULL,
    "fid" double precision,
    "cadid" double precision,
    "crownlregno" character varying(10),
    "crownaccountid" double precision,
    "classsubtype_desc" character varying(180),
    "crownaccounttype_desc" character varying(128),
    "definitiontype" character varying(40),
    "lotnumber" character varying(6),
    "sectionnumber" character varying(3),
    "plantype" character varying(1),
    "planno" character varying(8),
    "createdate" timestamp with time zone,
    "modifieddate" timestamp with time zone,
    "lreg_no" character varying(255),
    "office" character varying(60),
    "account_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "tenure_type" character varying(4000),
    "tenure_sub_type" character varying(4000),
    "account_class" character varying(4000),
    "purpose" character varying(4000),
    "geom" "extensions"."geometry"(MultiPolygon,7855)
);


ALTER TABLE "data_ssnsw"."crownleases" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "data_ssnsw"."crownleases_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "data_ssnsw"."crownleases_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "data_ssnsw"."crownleases_id_seq" OWNED BY "data_ssnsw"."crownleases"."id";



CREATE TABLE IF NOT EXISTS "data_ssnsw"."crownlicenses" (
    "id" integer NOT NULL,
    "fid" double precision,
    "cadid" double precision,
    "crownlregno" character varying(10),
    "crownaccountid" double precision,
    "classsubtype_desc" character varying(180),
    "crownaccounttype_desc" character varying(128),
    "definitiontype" character varying(40),
    "lotnumber" character varying(6),
    "sectionnumber" character varying(3),
    "plantype" character varying(1),
    "planno" character varying(8),
    "createdate" timestamp with time zone,
    "modifieddate" timestamp with time zone,
    "lreg_no" character varying(255),
    "office" character varying(4000),
    "account_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "tenure_type" character varying(4000),
    "tenure_sub_type" character varying(4000),
    "account_class" character varying(4000),
    "purpose" character varying(4000),
    "geom" "extensions"."geometry"(MultiPolygon,7855)
);


ALTER TABLE "data_ssnsw"."crownlicenses" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "data_ssnsw"."crownlicenses_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "data_ssnsw"."crownlicenses_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "data_ssnsw"."crownlicenses_id_seq" OWNED BY "data_ssnsw"."crownlicenses"."id";



CREATE TABLE IF NOT EXISTS "data_ssnsw"."crownreserves" (
    "id" integer NOT NULL,
    "fid" double precision,
    "cadid" double precision,
    "crownlregno" character varying(10),
    "crownaccountid" double precision,
    "classsubtype_desc" character varying(180),
    "definitiontype" character varying(40),
    "lotnumber" character varying(6),
    "sectionnumber" character varying(3),
    "plantype" character varying(1),
    "planno" character varying(8),
    "crownclasssubtype_desc" character varying(180),
    "crownlandstatustype_desc" character varying(128),
    "createdate" timestamp with time zone,
    "modifieddate" timestamp with time zone,
    "lreg_no" character varying(255),
    "reserve_no" character varying(10),
    "reserve_type" character varying(160),
    "suburb" character varying(255),
    "reserve_name" character varying(255),
    "status" character varying(40),
    "office" character varying(60),
    "management_type" character varying(160),
    "manager" character varying(1600),
    "trust_management_type" character varying(160),
    "trust_manager" character varying(1600),
    "purpose" character varying(4000),
    "additional_purpose" character varying(4000),
    "lots" character varying(4000),
    "gazetted_date" timestamp with time zone,
    "geom" "extensions"."geometry"(MultiPolygon,7855)
);


ALTER TABLE "data_ssnsw"."crownreserves" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "data_ssnsw"."crownreserves_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "data_ssnsw"."crownreserves_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "data_ssnsw"."crownreserves_id_seq" OWNED BY "data_ssnsw"."crownreserves"."id";



CREATE TABLE IF NOT EXISTS "projects"."crown_reserves_batlow" (
    "id" integer NOT NULL,
    "objectid" bigint,
    "cadid" bigint,
    "crownlregno" character varying(10),
    "crownaccountid" bigint,
    "classsubtype_desc" character varying(180),
    "definitiontype" character varying(40),
    "lotnumber" character varying(6),
    "sectionnumber" character varying(3),
    "plantype" character varying(1),
    "planno" character varying(8),
    "crownclasssubtype_desc" character varying(180),
    "crownlandstatustype_desc" character varying(128),
    "createdate" timestamp with time zone,
    "modifieddate" timestamp with time zone,
    "lreg_no" character varying(255),
    "reserve_no" character varying(10),
    "reserve_type" character varying(160),
    "suburb" character varying(255),
    "reserve_name" character varying(255),
    "status" character varying(40),
    "office" character varying(60),
    "management_type" character varying(160),
    "manager" character varying(1600),
    "trust_management_type" character varying(160),
    "trust_manager" character varying(1600),
    "purpose" character varying(4000),
    "additional_purpose" character varying(4000),
    "lots" character varying(4000),
    "gazetted_date" timestamp with time zone,
    "shape.starea()" double precision,
    "shape.stlength()" double precision,
    "geom" "extensions"."geometry"(MultiSurface,7855)
);


ALTER TABLE "projects"."crown_reserves_batlow" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "projects"."crown_reserves_batlow_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "projects"."crown_reserves_batlow_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "projects"."crown_reserves_batlow_id_seq" OWNED BY "projects"."crown_reserves_batlow"."id";



CREATE TABLE IF NOT EXISTS "public"."comments" (
    "id" bigint NOT NULL,
    "comment" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "project_id" "uuid" NOT NULL,
    "user_id" "uuid" DEFAULT "auth"."uid"() NOT NULL,
    "last_updated" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL
);


ALTER TABLE "public"."comments" OWNER TO "postgres";


COMMENT ON TABLE "public"."comments" IS 'Comments made by users on projects';



ALTER TABLE "public"."comments" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."comments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."communities_projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "community_id" "uuid" NOT NULL,
    "project_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "last_updated" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL
);


ALTER TABLE "public"."communities_projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."communities_users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "community_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "last_updated" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL
);


ALTER TABLE "public"."communities_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."community" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "extent" "extensions"."geometry" NOT NULL,
    "name" "text" NOT NULL,
    "contactinfo" "jsonb",
    "communityinfo" "jsonb",
    "created_at" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "last_updated" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "public" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."community" OWNER TO "postgres";


COMMENT ON TABLE "public"."community" IS 'Spatial extent of community';



CREATE TABLE IF NOT EXISTS "public"."health_status" (
    "id" integer DEFAULT 1 NOT NULL,
    "last_check" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "single_row" CHECK (("id" = 1))
);


ALTER TABLE "public"."health_status" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."keepalive" (
    "id" integer NOT NULL,
    "last_ping" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."keepalive" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."keepalive_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."keepalive_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."keepalive_id_seq" OWNED BY "public"."keepalive"."id";



CREATE TABLE IF NOT EXISTS "public"."projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "projectname" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "last_updated" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "projectinfo" "jsonb",
    "public" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."projects" OWNER TO "postgres";


COMMENT ON TABLE "public"."projects" IS 'Projects';



CREATE TABLE IF NOT EXISTS "public"."projects_tables" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "schema_name" "text" DEFAULT 'projects'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "project_id" "uuid" NOT NULL,
    "last_updated" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "table_name" "text" NOT NULL,
    "tableid" bigint NOT NULL,
    CONSTRAINT "projects_tables_schema_name_check" CHECK (("schema_name" = 'projects'::"text"))
);


ALTER TABLE "public"."projects_tables" OWNER TO "postgres";


ALTER TABLE "public"."projects_tables" ALTER COLUMN "tableid" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."projects_tables_tableid_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."projects_users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "project_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "last_updated" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL
);


ALTER TABLE "public"."projects_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role_type" "public"."role_type" NOT NULL,
    "role_name" "public"."role_name" NOT NULL,
    "entity_id" "uuid",
    "created_at" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "last_updated" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    CONSTRAINT "check_global_role" CHECK ((("role_type" <> 'global'::"public"."role_type") OR ("entity_id" IS NULL)))
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."userprofile" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "firstname" "text" NOT NULL,
    "profile_picture" "bytea",
    "bio" "text",
    "lastname" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "last_updated" timestamp with time zone DEFAULT ("now"() AT TIME ZONE 'utc'::"text") NOT NULL,
    "avatar_path" "text"
);


ALTER TABLE "public"."userprofile" OWNER TO "postgres";


ALTER TABLE ONLY "data_ssnsw"."crownenclosurepermits" ALTER COLUMN "id" SET DEFAULT "nextval"('"data_ssnsw"."crownenclosurepermits_id_seq"'::"regclass");



ALTER TABLE ONLY "data_ssnsw"."crownlands" ALTER COLUMN "id" SET DEFAULT "nextval"('"data_ssnsw"."crownlands_id_seq"'::"regclass");



ALTER TABLE ONLY "data_ssnsw"."crownlands_json" ALTER COLUMN "id" SET DEFAULT "nextval"('"data_ssnsw"."crownlands_json_id_seq"'::"regclass");



ALTER TABLE ONLY "data_ssnsw"."crownleases" ALTER COLUMN "id" SET DEFAULT "nextval"('"data_ssnsw"."crownleases_id_seq"'::"regclass");



ALTER TABLE ONLY "data_ssnsw"."crownlicenses" ALTER COLUMN "id" SET DEFAULT "nextval"('"data_ssnsw"."crownlicenses_id_seq"'::"regclass");



ALTER TABLE ONLY "data_ssnsw"."crownreserves" ALTER COLUMN "id" SET DEFAULT "nextval"('"data_ssnsw"."crownreserves_id_seq"'::"regclass");



ALTER TABLE ONLY "projects"."crown_reserves_batlow" ALTER COLUMN "id" SET DEFAULT "nextval"('"projects"."crown_reserves_batlow_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."keepalive" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."keepalive_id_seq"'::"regclass");



ALTER TABLE ONLY "data_ssnsw"."crownenclosurepermits"
    ADD CONSTRAINT "crownenclosurepermits_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "data_ssnsw"."crownlands_json"
    ADD CONSTRAINT "crownlands_json_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "data_ssnsw"."crownlands"
    ADD CONSTRAINT "crownlands_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "data_ssnsw"."crownleases"
    ADD CONSTRAINT "crownleases_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "data_ssnsw"."crownlicenses"
    ADD CONSTRAINT "crownlicenses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "data_ssnsw"."crownreserves"
    ADD CONSTRAINT "crownreserves_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "projects"."crown_reserves_batlow"
    ADD CONSTRAINT "crown_reserves_batlow_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pkey_1" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."communities_users"
    ADD CONSTRAINT "communities_users_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."communities_users"
    ADD CONSTRAINT "communities_users_unique" UNIQUE ("user_id", "community_id");



ALTER TABLE ONLY "public"."community"
    ADD CONSTRAINT "community_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."communities_projects"
    ADD CONSTRAINT "community_project_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."health_status"
    ADD CONSTRAINT "health_status_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."keepalive"
    ADD CONSTRAINT "keepalive_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."projects_tables"
    ADD CONSTRAINT "projects_tables_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."projects_users"
    ADD CONSTRAINT "projects_users_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."projects_users"
    ADD CONSTRAINT "projects_users_unique" UNIQUE ("user_id", "project_id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_unique" UNIQUE ("user_id", "role_type", "entity_id", "role_name");



ALTER TABLE ONLY "public"."userprofile"
    ADD CONSTRAINT "userprofile_pk" PRIMARY KEY ("id");



CREATE INDEX "crownenclosurepermits_geom_geom_idx" ON "data_ssnsw"."crownenclosurepermits" USING "gist" ("geom");



CREATE INDEX "crownlands_geom_geom_idx" ON "data_ssnsw"."crownlands" USING "gist" ("geom");



CREATE INDEX "crownleases_geom_geom_idx" ON "data_ssnsw"."crownleases" USING "gist" ("geom");



CREATE INDEX "crownlicenses_geom_geom_idx" ON "data_ssnsw"."crownlicenses" USING "gist" ("geom");



CREATE INDEX "crownreserves_geom_geom_idx" ON "data_ssnsw"."crownreserves" USING "gist" ("geom");



CREATE INDEX "crown_reserves_batlow_geom_geom_idx" ON "projects"."crown_reserves_batlow" USING "gist" ("geom");



CREATE INDEX "idx_comments_project_id" ON "public"."comments" USING "btree" ("project_id");



CREATE INDEX "idx_comments_user_id" ON "public"."comments" USING "btree" ("user_id");



CREATE INDEX "idx_communities_projects_community_id" ON "public"."communities_projects" USING "btree" ("community_id");



CREATE INDEX "idx_communities_projects_project_id" ON "public"."communities_projects" USING "btree" ("project_id");



CREATE INDEX "idx_communities_users_community_id" ON "public"."communities_users" USING "btree" ("community_id");



CREATE INDEX "idx_communities_users_user_id" ON "public"."communities_users" USING "btree" ("user_id");



CREATE INDEX "idx_projects_tables_project_id" ON "public"."projects_tables" USING "btree" ("project_id");



CREATE INDEX "idx_projects_users_project_id" ON "public"."projects_users" USING "btree" ("project_id");



CREATE INDEX "idx_projects_users_user_id" ON "public"."projects_users" USING "btree" ("user_id");



CREATE INDEX "idx_user_roles_user_id" ON "public"."user_roles" USING "btree" ("user_id");



CREATE OR REPLACE TRIGGER "check_entity_id_trigger" BEFORE INSERT OR UPDATE ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."check_entity_id"();



CREATE OR REPLACE TRIGGER "delete_orphaned_user_roles_community" AFTER DELETE ON "public"."community" FOR EACH ROW EXECUTE FUNCTION "public"."delete_orphaned_user_roles"();



CREATE OR REPLACE TRIGGER "delete_orphaned_user_roles_projects" AFTER DELETE ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."delete_orphaned_user_roles"();



CREATE OR REPLACE TRIGGER "set_last_updated" BEFORE INSERT OR UPDATE ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_last_updated"();



CREATE OR REPLACE TRIGGER "set_last_updated" BEFORE INSERT OR UPDATE ON "public"."communities_projects" FOR EACH ROW EXECUTE FUNCTION "public"."update_last_updated"();



CREATE OR REPLACE TRIGGER "set_last_updated" BEFORE UPDATE ON "public"."communities_users" FOR EACH ROW EXECUTE FUNCTION "public"."update_last_updated"();



CREATE OR REPLACE TRIGGER "set_last_updated" BEFORE INSERT OR UPDATE ON "public"."community" FOR EACH ROW EXECUTE FUNCTION "public"."update_last_updated"();



CREATE OR REPLACE TRIGGER "set_last_updated" BEFORE INSERT OR UPDATE ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."update_last_updated"();



CREATE OR REPLACE TRIGGER "set_last_updated" BEFORE INSERT OR UPDATE ON "public"."projects_tables" FOR EACH ROW EXECUTE FUNCTION "public"."update_last_updated"();



CREATE OR REPLACE TRIGGER "set_last_updated" BEFORE UPDATE ON "public"."projects_users" FOR EACH ROW EXECUTE FUNCTION "public"."update_last_updated"();



CREATE OR REPLACE TRIGGER "set_last_updated" BEFORE UPDATE ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."update_last_updated"();



CREATE OR REPLACE TRIGGER "set_last_updated" BEFORE INSERT OR UPDATE ON "public"."userprofile" FOR EACH ROW EXECUTE FUNCTION "public"."update_last_updated"();



CREATE OR REPLACE TRIGGER "validate_user_role_insert" BEFORE INSERT ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."validate_user_role"();



CREATE OR REPLACE TRIGGER "validate_user_role_update" BEFORE UPDATE ON "public"."user_roles" FOR EACH ROW EXECUTE FUNCTION "public"."validate_user_role"();



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_projectid_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_userid_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."userprofile"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."communities_projects"
    ADD CONSTRAINT "communities_projects_communityid_fkey" FOREIGN KEY ("community_id") REFERENCES "public"."community"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."communities_projects"
    ADD CONSTRAINT "communities_projects_projectid_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."communities_users"
    ADD CONSTRAINT "communities_users_community_fk" FOREIGN KEY ("community_id") REFERENCES "public"."community"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."communities_users"
    ADD CONSTRAINT "communities_users_user_fk" FOREIGN KEY ("user_id") REFERENCES "public"."userprofile"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."projects_tables"
    ADD CONSTRAINT "projects_tables_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."projects_users"
    ADD CONSTRAINT "projects_users_project_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."projects_users"
    ADD CONSTRAINT "projects_users_user_fk" FOREIGN KEY ("user_id") REFERENCES "public"."userprofile"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_fk" FOREIGN KEY ("user_id") REFERENCES "public"."userprofile"("id") ON DELETE CASCADE;



CREATE POLICY "Allow auth admin to read user roles" ON "public"."user_roles" FOR SELECT TO "supabase_auth_admin" USING (true);





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";
GRANT USAGE ON SCHEMA "public" TO "supabase_auth_admin";





















































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;













































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;

























































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;





















SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;



SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;










































SET SESSION AUTHORIZATION "postgres";
RESET SESSION AUTHORIZATION;















GRANT ALL ON FUNCTION "public"."check_entity_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_entity_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_entity_id"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."custom_access_token_hook"("event" "jsonb") TO "supabase_auth_admin";



GRANT ALL ON FUNCTION "public"."delete_orphaned_user_roles"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_orphaned_user_roles"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_orphaned_user_roles"() TO "service_role";



GRANT ALL ON FUNCTION "public"."dev_download_crownlands"("use_get" boolean, "delay_seconds" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."dev_download_crownlands"("use_get" boolean, "delay_seconds" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."dev_download_crownlands"("use_get" boolean, "delay_seconds" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."dev_process_downloads"("use_get" boolean, "delay_seconds" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."dev_process_downloads"("use_get" boolean, "delay_seconds" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."dev_process_downloads"("use_get" boolean, "delay_seconds" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_communities_with_transformed_extent"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_communities_with_transformed_extent"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_communities_with_transformed_extent"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_community_with_transformed_extent"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_community_with_transformed_extent"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_community_with_transformed_extent"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_roles"("user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_roles"("user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_roles"("user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."health_check"() TO "anon";
GRANT ALL ON FUNCTION "public"."health_check"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."health_check"() TO "service_role";



GRANT ALL ON FUNCTION "public"."remove_user_from_community"("p_userid" "uuid", "p_communityid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."remove_user_from_community"("p_userid" "uuid", "p_communityid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."remove_user_from_community"("p_userid" "uuid", "p_communityid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."remove_user_from_project"("p_userid" "uuid", "p_projectid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."remove_user_from_project"("p_userid" "uuid", "p_projectid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."remove_user_from_project"("p_userid" "uuid", "p_projectid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_existing_users"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_existing_users"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_existing_users"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_last_updated"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_last_updated"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_last_updated"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_user_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_user_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_user_role"() TO "service_role";






























































































































GRANT ALL ON TABLE "public"."comments" TO "anon";
GRANT ALL ON TABLE "public"."comments" TO "authenticated";
GRANT ALL ON TABLE "public"."comments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."comments_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."communities_projects" TO "anon";
GRANT ALL ON TABLE "public"."communities_projects" TO "authenticated";
GRANT ALL ON TABLE "public"."communities_projects" TO "service_role";



GRANT ALL ON TABLE "public"."communities_users" TO "anon";
GRANT ALL ON TABLE "public"."communities_users" TO "authenticated";
GRANT ALL ON TABLE "public"."communities_users" TO "service_role";



GRANT ALL ON TABLE "public"."community" TO "anon";
GRANT ALL ON TABLE "public"."community" TO "authenticated";
GRANT ALL ON TABLE "public"."community" TO "service_role";



GRANT ALL ON TABLE "public"."health_status" TO "anon";
GRANT ALL ON TABLE "public"."health_status" TO "authenticated";
GRANT ALL ON TABLE "public"."health_status" TO "service_role";



GRANT ALL ON TABLE "public"."keepalive" TO "anon";
GRANT ALL ON TABLE "public"."keepalive" TO "authenticated";
GRANT ALL ON TABLE "public"."keepalive" TO "service_role";



GRANT ALL ON SEQUENCE "public"."keepalive_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."keepalive_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."keepalive_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."projects" TO "anon";
GRANT ALL ON TABLE "public"."projects" TO "authenticated";
GRANT ALL ON TABLE "public"."projects" TO "service_role";



GRANT ALL ON TABLE "public"."projects_tables" TO "anon";
GRANT ALL ON TABLE "public"."projects_tables" TO "authenticated";
GRANT ALL ON TABLE "public"."projects_tables" TO "service_role";



GRANT ALL ON SEQUENCE "public"."projects_tables_tableid_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."projects_tables_tableid_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."projects_tables_tableid_seq" TO "service_role";



GRANT ALL ON TABLE "public"."projects_users" TO "anon";
GRANT ALL ON TABLE "public"."projects_users" TO "authenticated";
GRANT ALL ON TABLE "public"."projects_users" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "anon";
GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";
GRANT ALL ON TABLE "public"."user_roles" TO "supabase_auth_admin";



GRANT ALL ON TABLE "public"."userprofile" TO "anon";
GRANT ALL ON TABLE "public"."userprofile" TO "authenticated";
GRANT ALL ON TABLE "public"."userprofile" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";
































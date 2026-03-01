-- Migration: Add trigger to create user profile and assign default role on signup
-- This ensures all new users get:
-- 1. A userprofile entry
-- 2. A default 'member' role with 'global' scope

-- Update the handle_new_user function to also create a default role
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
    firstname := COALESCE(raw_meta->>'firstName', 'User');
    lastname := COALESCE(raw_meta->>'lastName', '');
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

  -- Assign default global 'member' role to the new user
  -- Only insert if the role doesn't already exist
  INSERT INTO public.user_roles (user_id, role_type, role_name, entity_id)
  VALUES (NEW.id, 'global', 'member', NULL)
  ON CONFLICT (user_id, role_type, entity_id, role_name) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Create trigger on auth.users to call handle_new_user when a new user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Backfill: Add default 'member' role to existing users who don't have any global role
-- This ensures existing users are also covered
INSERT INTO public.user_roles (user_id, role_type, role_name, entity_id)
SELECT up.id, 'global'::public.role_type, 'member'::public.role_name, NULL
FROM public.userprofile up
WHERE NOT EXISTS (
  SELECT 1
  FROM public.user_roles ur
  WHERE ur.user_id = up.id
    AND ur.role_type = 'global'
)
ON CONFLICT (user_id, role_type, entity_id, role_name) DO NOTHING;

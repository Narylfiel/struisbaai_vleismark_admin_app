CREATE OR REPLACE FUNCTION public.sync_staff_to_profiles()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- On INSERT: Create matching record in profiles
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO profiles (id, full_name, role, pin_hash, is_active, active)
    VALUES (NEW.id, NEW.full_name, NEW.role, NEW.pin_hash, NEW.is_active, NEW.is_active)
    ON CONFLICT (id) DO UPDATE
    SET 
      full_name = EXCLUDED.full_name,
      role = EXCLUDED.role,
      pin_hash = EXCLUDED.pin_hash,
      is_active = EXCLUDED.is_active,
      active = EXCLUDED.active;
    RETURN NEW;
  END IF;

  -- On UPDATE: Sync changes to profiles
  IF (TG_OP = 'UPDATE') THEN
    UPDATE profiles
    SET 
      full_name = NEW.full_name,
      role = NEW.role,
      is_active = NEW.is_active,
      active = NEW.is_active,
      pin_hash = NEW.pin_hash
    WHERE id = NEW.id;
    RETURN NEW;
  END IF;

  -- On DELETE: Mark as inactive in profiles (never actually delete)
  IF (TG_OP = 'DELETE') THEN
    UPDATE profiles
    SET is_active = false, active = false
    WHERE id = OLD.id;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$function$;

CREATE TRIGGER trg_sync_staff_to_profiles AFTER INSERT OR DELETE OR UPDATE ON staff_profiles FOR EACH ROW EXECUTE FUNCTION sync_staff_to_profiles();

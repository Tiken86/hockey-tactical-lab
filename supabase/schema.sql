-- =====================================================================
-- Hockey Tactical Lab — esquema Supabase (seminario)
-- Proyecto: Tecnocampus (ref hucsouzfffhqlrogyxwn)
--
-- Modelo de seguridad: la app es estatica y publica (GitHub Pages), la
-- anon key queda expuesta. Por eso las tablas son PRIVADAS (RLS deny-all
-- + revoke) y TODO acceso pasa por funciones RPC SECURITY DEFINER.
--
-- Los secretos (clave de profesor y codigo de clase) NO estan en este
-- archivo: se insertan aparte con `crypt(...)` (ver README de setup).
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- TABLAS
-- ---------------------------------------------------------------------
create table if not exists public.seminario_proyectos (
    id            uuid primary key default gen_random_uuid(),
    codigo        text not null unique,
    nombre_grupo  text not null,
    data          jsonb not null default '{}'::jsonb,
    entregado     boolean not null default false,
    entregado_at  timestamptz,
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now()
);

create index if not exists seminario_proyectos_updated_idx
    on public.seminario_proyectos (updated_at desc);

create table if not exists public.seminario_config (
    clave  text primary key,   -- 'profesor_hash' | 'codigo_clase'
    valor  text not null        -- hash bcrypt (crypt/gen_salt('bf'))
);

-- ---------------------------------------------------------------------
-- RLS: deny-all a anon (sin politicas) + revoke de privilegios de tabla
-- ---------------------------------------------------------------------
alter table public.seminario_proyectos enable row level security;
alter table public.seminario_config    enable row level security;

revoke all on public.seminario_proyectos from anon, authenticated, public;
revoke all on public.seminario_config    from anon, authenticated, public;

-- ---------------------------------------------------------------------
-- GENERADOR DE CODIGO (8 chars, alfabeto sin ambiguos)
-- ---------------------------------------------------------------------
create or replace function public._gen_codigo()
returns text
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
    alfabeto constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    res text := '';
    i int;
begin
    for i in 1..8 loop
        res := res || substr(alfabeto, 1 + floor(random()*length(alfabeto))::int, 1);
    end loop;
    return res;
end;
$$;
revoke all on function public._gen_codigo() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- crear_grupo: valida codigo de clase, genera codigo unico, inserta
-- ---------------------------------------------------------------------
create or replace function public.crear_grupo(p_nombre text, p_codigo_clase text)
returns text
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
    v_hash text;
    v_codigo text;
    v_intentos int := 0;
begin
    if p_nombre is null or length(btrim(p_nombre)) = 0 then
        raise exception 'NOMBRE_VACIO';
    end if;
    if length(btrim(p_nombre)) > 120 then
        raise exception 'NOMBRE_LARGO';
    end if;

    select valor into v_hash from public.seminario_config where clave = 'codigo_clase';
    if v_hash is null or crypt(upper(btrim(p_codigo_clase)), v_hash) <> v_hash then
        raise exception 'CLASE_INVALIDA';
    end if;

    loop
        v_intentos := v_intentos + 1;
        v_codigo := public._gen_codigo();
        begin
            insert into public.seminario_proyectos (codigo, nombre_grupo, data)
            values (
                v_codigo,
                btrim(p_nombre),
                jsonb_build_object(
                    'groupName', btrim(p_nombre),
                    'momentId', '',
                    'members', '[]'::jsonb,
                    'customBehaviors', '[]'::jsonb,
                    'analysis', '[]'::jsonb,
                    'tasks', jsonb_build_object(
                        'DIRIGIDA', null, 'ESTRUCTURADA', null,
                        'ESPECIAL', null, 'COMPETITIVA', null)
                )
            );
            return v_codigo;
        exception when unique_violation then
            if v_intentos >= 5 then raise exception 'NO_CODIGO'; end if;
        end;
    end loop;
end;
$$;

-- ---------------------------------------------------------------------
-- cargar_grupo: devuelve la fila de un codigo (0 filas = invalido)
-- ---------------------------------------------------------------------
create or replace function public.cargar_grupo(p_codigo text)
returns table (nombre_grupo text, data jsonb, entregado boolean, updated_at timestamptz)
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
begin
    return query
    select sp.nombre_grupo, sp.data, sp.entregado, sp.updated_at
    from public.seminario_proyectos sp
    where sp.codigo = upper(btrim(p_codigo));
end;
$$;

-- ---------------------------------------------------------------------
-- guardar_grupo: persiste data (rechaza si entregado o payload grande)
-- ---------------------------------------------------------------------
create or replace function public.guardar_grupo(p_codigo text, p_data jsonb)
returns timestamptz
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
    v_ts timestamptz;
    v_entregado boolean;
begin
    if octet_length(p_data::text) > 4000000 then
        raise exception 'PAYLOAD_GRANDE';
    end if;

    select entregado into v_entregado
    from public.seminario_proyectos
    where codigo = upper(btrim(p_codigo)) for update;

    if not found then raise exception 'CODIGO_INVALIDO'; end if;
    if v_entregado then raise exception 'YA_ENTREGADO'; end if;

    update public.seminario_proyectos
       set data = p_data, updated_at = now()
     where codigo = upper(btrim(p_codigo))
    returning updated_at into v_ts;

    return v_ts;
end;
$$;

-- ---------------------------------------------------------------------
-- entregar_grupo: marca entregado
-- ---------------------------------------------------------------------
create or replace function public.entregar_grupo(p_codigo text)
returns timestamptz
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare v_ts timestamptz;
begin
    update public.seminario_proyectos
       set entregado = true, entregado_at = now(), updated_at = now()
     where codigo = upper(btrim(p_codigo)) and entregado = false
    returning entregado_at into v_ts;
    if not found then raise exception 'NO_ENTREGABLE'; end if;
    return v_ts;
end;
$$;

-- ---------------------------------------------------------------------
-- profesor_listar: valida clave (bcrypt) y lista todos los grupos
-- ---------------------------------------------------------------------
create or replace function public.profesor_listar(p_clave text)
returns table (codigo text, nombre_grupo text, entregado boolean,
               entregado_at timestamptz, updated_at timestamptz)
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare v_hash text;
begin
    select valor into v_hash from public.seminario_config where clave = 'profesor_hash';
    if v_hash is null or crypt(p_clave, v_hash) <> v_hash then
        raise exception 'CLAVE_INVALIDA';
    end if;

    return query
    select sp.codigo, sp.nombre_grupo, sp.entregado, sp.entregado_at, sp.updated_at
    from public.seminario_proyectos sp
    order by sp.updated_at desc;
end;
$$;

-- ---------------------------------------------------------------------
-- profesor_obtener: valida clave y devuelve data completa de un grupo
-- ---------------------------------------------------------------------
create or replace function public.profesor_obtener(p_clave text, p_codigo text)
returns table (codigo text, nombre_grupo text, data jsonb,
               entregado boolean, entregado_at timestamptz, updated_at timestamptz)
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare v_hash text;
begin
    select valor into v_hash from public.seminario_config where clave = 'profesor_hash';
    if v_hash is null or crypt(p_clave, v_hash) <> v_hash then
        raise exception 'CLAVE_INVALIDA';
    end if;

    return query
    select sp.codigo, sp.nombre_grupo, sp.data, sp.entregado, sp.entregado_at, sp.updated_at
    from public.seminario_proyectos sp
    where sp.codigo = upper(btrim(p_codigo));
end;
$$;

-- ---------------------------------------------------------------------
-- GRANTS: solo execute a anon, solo lo necesario
-- ---------------------------------------------------------------------
revoke all on function public.crear_grupo(text, text)      from public;
revoke all on function public.cargar_grupo(text)           from public;
revoke all on function public.guardar_grupo(text, jsonb)   from public;
revoke all on function public.entregar_grupo(text)         from public;
revoke all on function public.profesor_listar(text)        from public;
revoke all on function public.profesor_obtener(text, text) from public;

grant execute on function public.crear_grupo(text, text)      to anon;
grant execute on function public.cargar_grupo(text)           to anon;
grant execute on function public.guardar_grupo(text, jsonb)   to anon;
grant execute on function public.entregar_grupo(text)         to anon;
grant execute on function public.profesor_listar(text)        to anon;
grant execute on function public.profesor_obtener(text, text) to anon;

-- ---------------------------------------------------------------------
-- CONFIG (secretos) — ejecutar APARTE, no versionar valores reales:
--
--   insert into public.seminario_config (clave, valor) values
--     ('codigo_clase',  crypt('HOCKEY26', gen_salt('bf'))),
--     ('profesor_hash', crypt('<CLAVE_PROFESOR>', gen_salt('bf')))
--   on conflict (clave) do update set valor = excluded.valor;
-- ---------------------------------------------------------------------

create or replace function public.administrar_turno_caja(
  p_cajero_id uuid, p_abrir boolean, p_monto numeric, p_turno_id bigint default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_turno_id bigint;
begin
  if not public.es_administrador_activo() then
    raise exception 'Solo Administración puede abrir o cerrar turnos.';
  end if;
  if not exists (
    select 1 from public.usuarios
    where id = p_cajero_id and activo and rol = 'CAJERO'
  ) then
    raise exception 'Selecciona un cajero activo.';
  end if;
  if p_abrir is null or p_monto is null
     or p_monto::text in ('NaN', 'Infinity', '-Infinity')
     or p_monto < 0 or scale(p_monto) > 2 then
    raise exception 'Ingresa un importe válido de hasta dos decimales.';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended('luxury:turno:' || p_cajero_id::text, 0)
  );
  if p_abrir then
    if exists (
      select 1 from public.turnos_caja
      where cajero_id = p_cajero_id and cerrado_en is null
    ) then
      return;
    end if;
    insert into public.turnos_caja (cajero_id, monto_apertura)
    values (p_cajero_id, p_monto)
    returning id into v_turno_id;
  else
    update public.turnos_caja
    set cerrado_en = now(), monto_cierre = p_monto
    where id = p_turno_id and cajero_id = p_cajero_id and cerrado_en is null
    returning id into v_turno_id;
    if v_turno_id is null then
      raise exception 'El turno cambió. Consulta su estado antes de volver a cerrar.';
    end if;
  end if;

  insert into public.auditoria_movimientos
    (actor_id, actor_rol, accion, entidad, entidad_id)
  values (
    auth.uid(), 'ADMINISTRADOR',
    case when p_abrir then 'Abrir turno de caja' else 'Cerrar turno de caja' end,
    'turnos_caja', v_turno_id::text
  );
end;
$$;

revoke all on function public.administrar_turno_caja(uuid, boolean, numeric, bigint)
  from public, anon, authenticated;
grant execute on function public.administrar_turno_caja(uuid, boolean, numeric, bigint)
  to authenticated;

alter table public.turnos_caja enable row level security;
revoke insert, update, delete on public.turnos_caja from public, anon, authenticated;
drop policy if exists turnos_lectura_administracion on public.turnos_caja;
create policy turnos_lectura_administracion on public.turnos_caja
  for select to authenticated using (public.es_administrador_activo());

create or replace function public.validar_turno_diario_al_cobrar()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cajero uuid := auth.uid();
  v_inicio timestamptz := date_trunc('day', now() at time zone 'America/Lima')
    at time zone 'America/Lima';
begin
  if new.monto > 0 and exists (
    select 1 from public.usuarios
    where id = v_cajero and activo and rol = 'CAJERO'
  ) then
    perform 1 from public.turnos_caja
    where cajero_id = v_cajero and cerrado_en is null
      and abierto_en >= v_inicio and abierto_en <= now()
    for share;
    if not found then
      raise exception 'Administración debe abrir el turno de caja de hoy.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists validar_turno_diario_al_cobrar on public.pagos;
create trigger validar_turno_diario_al_cobrar
before insert on public.pagos
for each row execute function public.validar_turno_diario_al_cobrar();
revoke all on function public.validar_turno_diario_al_cobrar()
  from public, anon, authenticated;

create or replace function public.obtener_turno_caja_actual()
returns table (
  id bigint,
  cajero_id uuid,
  monto_apertura numeric,
  monto_cierre numeric,
  abierto_en timestamptz,
  cerrado_en timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_inicio timestamptz := date_trunc('day', now() at time zone 'America/Lima')
    at time zone 'America/Lima';
begin
  if not exists (
    select 1
    from public.usuarios u
    where u.id = auth.uid() and u.activo and u.rol = 'CAJERO'
  ) then
    raise exception 'Solo un cajero activo puede consultar su turno.';
  end if;

  return query
  select t.id, t.cajero_id, t.monto_apertura, t.monto_cierre,
         t.abierto_en, t.cerrado_en
  from public.turnos_caja t
  where t.cajero_id = auth.uid()
    and t.cerrado_en is null
    and t.abierto_en >= v_inicio
    and t.abierto_en <= now()
  order by t.abierto_en desc
  limit 1;
end;
$$;

revoke all on function public.obtener_turno_caja_actual()
  from public, anon, authenticated;
grant execute on function public.obtener_turno_caja_actual()
  to authenticated;

create or replace function public.validar_alta_pedido_mesa()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.mesa_id is null or new.retirada_en is not null then
    return new;
  end if;

  perform 1
  from public.mesas m
  where m.id = new.mesa_id and m.activa
  for update;
  if not found then
    raise sqlstate 'PT409' using message = 'La mesa ya no está disponible.';
  end if;

  if exists (
    select 1
    from public.pedidos p
    where p.mesa_id = new.mesa_id
      and p.retirada_en is null
      and p.estado not in ('PAGADO', 'CANCELADO')
      and (
        p.estado = 'POR_COBRAR'
        or exists (select 1 from public.pagos a where a.pedido_id = p.id)
      )
  ) then
    raise sqlstate 'PT409' using message = 'La mesa ya está en cobro y no admite más pedidos.';
  end if;

  if new.pedido_padre_id is not null then
    if not exists (
      select 1
      from public.pedidos p
      where p.id = new.pedido_padre_id
        and p.mesa_id = new.mesa_id
        and p.retirada_en is null
        and p.estado not in ('POR_COBRAR', 'PAGADO', 'CANCELADO')
        and not exists (
          select 1 from public.pagos a where a.pedido_id = p.id
        )
    ) then
      raise sqlstate 'PT409' using message = 'El pedido principal ya no admite consumos.';
    end if;
  elsif exists (
    select 1
    from public.pedidos p
    where p.mesa_id = new.mesa_id
      and p.retirada_en is null
      and p.estado not in ('PAGADO', 'CANCELADO')
  ) then
    raise sqlstate 'PT409' using message = 'Agrega el consumo al pedido abierto de esta mesa.';
  end if;
  return new;
end;
$$;

drop trigger if exists validar_alta_pedido_mesa on public.pedidos;
create trigger validar_alta_pedido_mesa
before insert on public.pedidos
for each row execute function public.validar_alta_pedido_mesa();

revoke all on function public.validar_alta_pedido_mesa()
  from public, anon, authenticated;

notify pgrst, 'reload schema';

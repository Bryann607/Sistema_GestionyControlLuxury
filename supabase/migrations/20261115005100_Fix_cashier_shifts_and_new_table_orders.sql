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

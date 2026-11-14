-- Ejecutar en Supabase SQL editor después de verificar la tabla usuarios.
-- Esta migración NO modifica pedidos de mesa ni movimientos de caja existentes.
create table if not exists public.pedidos_externos (
  id text primary key,
  modalidad text not null check (modalidad in ('DELIVERY','PARA_LLEVAR')),
  cliente text not null,
  telefono text not null,
  direccion text not null default '',
  items jsonb not null check (jsonb_typeof(items) = 'array'),
  total numeric(12,2) not null check (total >= 0),
  estado text not null default 'PENDIENTE' check (estado in ('PENDIENTE','PREPARANDO','LISTO','ENTREGADO','CANCELADO')),
  creado_en timestamptz not null default now(),
  creado_por uuid not null default auth.uid()
);
create index if not exists pedidos_externos_fecha_idx on public.pedidos_externos(creado_en desc);
alter table public.pedidos_externos enable row level security;

drop policy if exists "Personal activo consulta pedidos externos" on public.pedidos_externos;
create policy "Personal activo consulta pedidos externos"
on public.pedidos_externos for select to authenticated
using (exists (select 1 from public.usuarios u where u.id = auth.uid() and u.activo = true));

drop policy if exists "Atencion crea pedidos externos" on public.pedidos_externos;
create policy "Atencion crea pedidos externos"
on public.pedidos_externos for insert to authenticated
with check (
  creado_por = auth.uid() and estado = 'PENDIENTE' and
  exists (select 1 from public.usuarios u where u.id = auth.uid()
    and u.activo = true and (
      (u.rol in ('ADMINISTRADOR','GERENTE','CAJERO') and modalidad in ('DELIVERY','PARA_LLEVAR')) or
      (u.rol = 'MESERO' and modalidad = 'PARA_LLEVAR')
    ))
);

-- Restringe actualizaciones según funciones y sin permitir cambios en los importes.
-- La aplicación usa la acción para pasar de pendiente a preparando, listo o entregado.
create or replace function public.actualizar_estado_pedido_externo(p_id text, p_estado text)
returns void language plpgsql security definer set search_path = public as $$
declare v_estado text; v_rol text;
begin
  select rol into v_rol from public.usuarios where id = auth.uid() and activo = true;
  if v_rol is null then raise exception 'Usuario sin acceso'; end if;
  select estado into v_estado from public.pedidos_externos where id = p_id for update;
  if not found then raise exception 'Pedido inexistente'; end if;
  if not (
    (v_estado = 'PENDIENTE' and p_estado = 'PREPARANDO' and v_rol in ('ADMINISTRADOR','COCINERO','JEFE_COCINA')) or
    (v_estado = 'PREPARANDO' and p_estado = 'LISTO' and v_rol in ('ADMINISTRADOR','COCINERO','JEFE_COCINA')) or
    (v_estado = 'LISTO' and p_estado = 'ENTREGADO' and v_rol in ('ADMINISTRADOR','MESERO','CAJERO'))
  ) then raise exception 'Transición no autorizada'; end if;
  update public.pedidos_externos set estado = p_estado where id = p_id;
end; $$;
revoke all on function public.actualizar_estado_pedido_externo(text,text) from public;
grant execute on function public.actualizar_estado_pedido_externo(text,text) to authenticated;

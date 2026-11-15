-- Ejecutar en Supabase SQL Editor DESPUÉS de las migraciones anteriores.
-- No borra registros. Aplica permisos también en la base de datos.
-- El mesero solo consulta PARA_LLEVAR; Cocina puede ver ambas modalidades.
drop policy if exists "Personal activo consulta pedidos externos" on public.pedidos_externos;
create policy "Personal activo consulta pedidos externos"
on public.pedidos_externos for select to authenticated
using (
  exists (
    select 1 from public.usuarios u
    where u.id = auth.uid() and u.activo = true
      and (u.rol <> 'MESERO' or pedidos_externos.modalidad = 'PARA_LLEVAR')
  )
);

-- Restricción de transiciones: el mesero jamás entrega un pedido Delivery.
create or replace function public.actualizar_estado_pedido_externo(p_id text, p_estado text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_estado text;
  v_rol text;
  v_modalidad text;
begin
  select u.rol into v_rol
  from public.usuarios u where u.id = auth.uid() and u.activo = true;
  if v_rol is null then raise exception 'Usuario sin acceso' using errcode='42501'; end if;

  select estado, modalidad into v_estado, v_modalidad
  from public.pedidos_externos where id = p_id for update;
  if not found then raise exception 'Pedido inexistente'; end if;

  if not (
    (v_estado = 'PENDIENTE' and p_estado = 'PREPARANDO'
      and v_rol in ('ADMINISTRADOR','COCINERO','JEFE_COCINA')) or
    (v_estado = 'PREPARANDO' and p_estado = 'LISTO'
      and v_rol in ('ADMINISTRADOR','COCINERO','JEFE_COCINA')) or
    (v_estado = 'LISTO' and p_estado = 'ENTREGADO'
      and (v_rol in ('ADMINISTRADOR','CAJERO')
        or (v_rol = 'MESERO' and v_modalidad = 'PARA_LLEVAR')))
  ) then
    raise exception 'Transición no autorizada' using errcode='42501';
  end if;
  update public.pedidos_externos set estado = p_estado where id = p_id;
end; $$;
revoke all on function public.actualizar_estado_pedido_externo(text,text) from public;
grant execute on function public.actualizar_estado_pedido_externo(text,text) to authenticated;

-- Aplicar si la tabla pedidos_externos ya existe.
-- Esta política restringe DELIVERY al cajero y supervisores.
-- No borra pedidos ni modifica cobros.
drop policy if exists "Atencion crea pedidos externos" on public.pedidos_externos;
create policy "Atencion crea pedidos externos"
on public.pedidos_externos for insert to authenticated
with check (
  creado_por = auth.uid() and estado = 'PENDIENTE' and
  (
    (modalidad = 'DELIVERY' and nullif(btrim(direccion), '') is not null) or
    (modalidad = 'PARA_LLEVAR')
  ) and
  exists (select 1 from public.usuarios u where u.id = auth.uid()
    and u.activo = true and (
      (u.rol in ('ADMINISTRADOR','GERENTE','CAJERO') and modalidad in ('DELIVERY','PARA_LLEVAR')) or
      (u.rol = 'MESERO' and modalidad = 'PARA_LLEVAR')
    ))
);

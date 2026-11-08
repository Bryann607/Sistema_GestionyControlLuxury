// Supabase Edge Function: deploy with JWT verification enabled.
// Secrets SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected by Supabase.
import { createClient } from 'npm:@supabase/supabase-js@2';

const headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};
const json = (status: number, body: unknown) => new Response(JSON.stringify(body), { status, headers });
const roles = new Set(['ADMINISTRADOR','GERENTE','COCINERO','JEFE_COCINA','MESERO','CAJERO']);

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers });
  if (req.method !== 'POST') return json(405, { error: 'Método no permitido' });
  const token = req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) return json(401, { error: 'Sesión requerida' });
  const url = Deno.env.get('SUPABASE_URL');
  const secret = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !secret) return json(500, { error: 'Falta configuración segura en Supabase' });
  const admin = createClient(url, secret, {auth: {autoRefreshToken:false,persistSession:false}});
  const { data: auth, error: authError } = await admin.auth.getUser(token);
  if (authError || !auth.user) return json(401, { error: 'Sesión inválida' });
  const { data: requester, error: profileError } = await admin.from('usuarios')
    .select('rol,activo').eq('id', auth.user.id).single();
  if (profileError || requester?.activo !== true || requester?.rol !== 'ADMINISTRADOR')
    return json(403, { error: 'Solo administración puede gestionar usuarios' });
  try {
    const body = await req.json();
    const action = String(body.action || '');
    const userId = String(body.userId || '');
    const password = String(body.password || '');
    if (action === 'create' || action === 'update') {
      const name = String(body.name || '').trim();
      const email = String(body.email || '').trim().toLowerCase();
      const role = String(body.role || '');
      if (!name || !/^\S+@\S+\.\S+$/.test(email) || !roles.has(role))
        return json(400, {error: 'Nombre, correo o rol inválido'});
      if (action === 'create') {
        if (password.length < 8) return json(400, { error: 'Mínimo 8 caracteres' });
        const {data, error} = await admin.auth.admin.createUser({
          email, password, email_confirm: true, user_metadata: {name},
        });
        if (error || !data.user) return json(400, {error: error?.message || 'No se pudo crear el usuario'});
        const {error: dbError} = await admin.from('usuarios').insert({
          id: data.user.id, nombre_completo: name, correo: email, rol: role, activo: true,
        });
        if (dbError) {
          await admin.auth.admin.deleteUser(data.user.id);
          return json(400, {error: 'No se pudo crear el perfil: ' + dbError.message});
        }
        // Notificar con un enlace de recuperación, nunca con la contraseña temporal.
        const {error: mailError} = await admin.auth.resetPasswordForEmail(email);
        return json(200, {ok:true, userId:data.user.id, emailSent:!mailError,
          warning:mailError ? 'Cuenta creada. Configura SMTP para enviar el enlace de acceso.' : null});
      }
      if (!userId) return json(400, {error:'Falta identificador de usuario'});
      if (userId === auth.user.id && role !== 'ADMINISTRADOR')
        return json(400, {error:'No puedes quitarte el rol de administrador'});
      const {error: authUpdateError} = await admin.auth.admin.updateUserById(userId, {
        email, user_metadata: {name},
      });
      if (authUpdateError) return json(400, {error:authUpdateError.message});
      const {error: dbError} = await admin.from('usuarios').update({
        nombre_completo:name,correo:email,rol:role,
      }).eq('id',userId);
      if (dbError) return json(400,{error:'Auth actualizado pero falló perfil: '+dbError.message});
      return json(200,{ok:true});
    }
    if (action === 'reset') {
      if (!userId) return json(400, {error:'Selecciona un usuario'});
      // Resolve email on the server: the caller cannot redirect recovery to another address.
      const {data: employee, error: employeeError} = await admin.from('usuarios')
        .select('correo,activo').eq('id', userId).single();
      if (employeeError || !employee || employee.activo !== true || !employee.correo)
        return json(404, {error:'No se encontró una cuenta activa con correo registrado'});
      const {error: mailError} = await admin.auth.resetPasswordForEmail(employee.correo);
      if (mailError) return json(502, {error:'No se pudo enviar el correo: ' + mailError.message});
      return json(200, {ok:true, emailSent:true});
    }
    return json(400,{error:'Acción desconocida'});
  } catch (error) { return json(500,{error: error instanceof Error ? error.message : 'Error inesperado'}); }
});

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/widgets/luxury_feedback.dart';

/// El nombre, cargo, DNI y estado vienen de usuarios (solo lectura).
/// Los datos de contacto opcionales se guardan en los metadatos privados
/// del usuario autenticado, sin añadir columnas ni relajar permisos SQL.
class LuxuryProfileDialog extends StatefulWidget {
  const LuxuryProfileDialog({super.key, required this.store});
  final RestaurantStore store;

  @override
  State<LuxuryProfileDialog> createState() => _LuxuryProfileDialogState();
}

class _LuxuryProfileDialogState extends State<LuxuryProfileDialog> {
  late Future<Map<String, dynamic>> _future;
  late final TextEditingController _area;
  late final TextEditingController _personalEmail;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _photoUrl;
  bool editing = false;
  bool saving = false;

  RestaurantStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    final meta = store.client?.auth.currentUser?.userMetadata ?? {};
    String get(String key) => meta[key]?.toString() ?? '';
    _area = TextEditingController(text: get('luxury_area'));
    _personalEmail = TextEditingController(text: get('luxury_personal_email'));
    _phone = TextEditingController(text: get('luxury_phone'));
    _address = TextEditingController(text: get('luxury_address'));
    _photoUrl = TextEditingController(text: get('luxury_photo_url'));
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    if (store.client == null || store.userId == null) return {};
    final row = await store.client!
        .from('usuarios').select().eq('id', store.userId!).maybeSingle();
    return row == null ? {} : Map<String, dynamic>.from(row);
  }

  @override
  void dispose() {
    _area.dispose();
    _personalEmail.dispose();
    _phone.dispose();
    _address.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  String _field(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final text = row[key]?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return 'No registrado';
  }

  bool _isValidPhotoUrl(String value) {
    if (value.isEmpty) return true;
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.hasAuthority;
  }

  Future<void> _save() async {
    if (saving || store.client == null) return;
    final personalEmail = _personalEmail.text.trim();
    final phone = _phone.text.trim();
    final photo = _photoUrl.text.trim();
    if (personalEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(personalEmail)) {
      LuxuryFeedback.error(context, 'Ingresa un correo personal válido.');
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^\d{9}$').hasMatch(phone)) {
      LuxuryFeedback.error(context, 'El celular debe contener exactamente 9 dígitos.');
      return;
    }
    if (!_isValidPhotoUrl(photo)) {
      LuxuryFeedback.error(context, 'La fotografía debe tener una URL pública HTTPS.');
      return;
    }
    setState(() => saving = true);
    try {
      await store.client!.auth.updateUser(UserAttributes(data: {
        'luxury_area': _area.text.trim(),
        'luxury_personal_email': personalEmail,
        'luxury_phone': phone,
        'luxury_address': _address.text.trim(),
        'luxury_photo_url': photo,
      }));
      if (!mounted) return;
      setState(() => editing = false);
      await LuxuryFeedback.success(context, title: 'Perfil actualizado',
        message: 'Tus datos de contacto personales se guardaron correctamente.');
    } catch (_) {
      if (mounted) {
        LuxuryFeedback.error(context,
            'No se pudo guardar tu perfil. Comprueba tu conexión e inténtalo nuevamente.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _line(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: const Color(0xFF97683F)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFF77706A), fontSize: 12)),
        const SizedBox(height: 3),
        SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ])),
    ]),
  );

  Widget _editable(TextEditingController controller, String label,
      IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    if (!editing) {
      return _line(icon, label,
          controller.text.trim().isEmpty ? 'No registrado' : controller.text.trim());
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(controller: controller, keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon))),
    );
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540, maxHeight: 750),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final name = _field(data, ['nombre_completo']) == 'No registrado'
              ? store.displayName : _field(data, ['nombre_completo']);
          final photo = _photoUrl.text.trim().isNotEmpty
              ? _photoUrl.text.trim()
              : _field(data, ['foto_url', 'foto_perfil_url', 'avatar_url']);
          final showPhoto = _isValidPhotoUrl(photo) && photo.isNotEmpty &&
              photo != 'No registrado';
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.fromLTRB(22, 14, 12, 6), child: Row(children: [
              const Expanded(child: Text('Mi perfil',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
              IconButton(tooltip: 'Cerrar perfil',
                onPressed: saving ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded)),
            ])),
            Flexible(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: CircleAvatar(radius: 43,
                  backgroundColor: const Color(0xFFE9D9B7),
                  foregroundImage: showPhoto ? NetworkImage(photo) : null,
                  child: Text(name.isEmpty ? 'L' : name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 31,
                      color: Color(0xFF60452E), fontWeight: FontWeight.w800)))),
                const SizedBox(height: 10),
                Center(child: Text(name, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                Center(child: Text(store.role?.label ?? 'Personal',
                  style: const TextStyle(color: Color(0xFF98714D)))),
                const SizedBox(height: 14),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                else if (snapshot.hasError)
                  const Text('No se pudieron consultar los datos del personal. '
                    'Revisa la conexión o los permisos.',
                    style: TextStyle(color: Color(0xFF9A3830)))
                else ...[
                  _line(Icons.badge_outlined, 'Código de empleado',
                    _field(data, ['codigo_empleado', 'codigo']) == 'No registrado'
                      ? (store.userId ?? 'No registrado')
                      : _field(data, ['codigo_empleado', 'codigo'])),
                  _line(Icons.verified_user_outlined, 'Estado',
                    store.isDemo ? 'Demostración' :
                    (data['activo'] == true ? 'Activo' : _field(data, ['estado']))),
                  _line(Icons.email_outlined, 'Correo de acceso',
                    store.client?.auth.currentUser?.email ??
                    _field(data, ['email', 'correo'])),
                  _line(Icons.assignment_ind_outlined, 'Documento de identidad',
                    _field(data, ['dni', 'documento_identidad'])),
                ],
                const Divider(height: 26),
                const Text('Información de contacto',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                _editable(_area, 'Departamento o área', Icons.apartment_outlined),
                _editable(_personalEmail, 'Correo personal', Icons.alternate_email_outlined,
                  keyboardType: TextInputType.emailAddress),
                _editable(_phone, 'Teléfono móvil', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
                _editable(_address, 'Dirección residencial', Icons.home_outlined,
                  maxLines: editing ? 2 : 1),
                _editable(_photoUrl, 'URL HTTPS de fotografía', Icons.image_outlined,
                  keyboardType: TextInputType.url),
                const SizedBox(height: 10),
                const Text('Puedes editar tus datos de contacto y pegar una URL de fotografía. '
                  'El cargo, permisos, estado, DNI y correo de acceso los administra el personal autorizado. '
                  'No se modifica la contraseña desde este panel.',
                  style: TextStyle(color: Color(0xFF79716C), fontSize: 12, height: 1.5)),
              ]),
            )),
            Padding(padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Cerrar'))),
                if (store.client != null) ...[
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton(
                    onPressed: saving ? null : editing ? _save : () => setState(() => editing = true),
                    child: Text(saving ? 'Guardando...' : editing ? 'Guardar perfil' : 'Editar perfil'))),
                ],
              ])),
          ]);
        },
      ),
    ),
  );
}

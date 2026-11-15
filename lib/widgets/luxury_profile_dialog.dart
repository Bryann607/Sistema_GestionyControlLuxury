import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:luxury_app/controllers/restaurant_store.dart';
import 'package:luxury_app/models/models.dart';
import 'package:luxury_app/widgets/luxury_feedback.dart';
import 'package:luxury_app/widgets/luxury_progress.dart';

String staffEmploymentLabel(String value) => switch (value) {
  'VACACIONES' => 'De vacaciones',
  'LICENCIA' => 'Con licencia',
  'INACTIVO' => 'Inactivo',
  _ => 'Activo',
};

/// Avatar con la foto de Supabase Storage o la inicial del nombre.
Widget staffAvatar(RestaurantStore store, StaffMember? member, {double radius = 20}) {
  final url = member == null ? '' : store.profilePhotoUrl(member.photoPath);
  final name = (member?.name ?? store.displayName).trim();
  return CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFF805034),
    foregroundImage: url.isEmpty ? null : NetworkImage(url),
    child: Text(
      name.isEmpty ? '?' : name[0].toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: radius * .8,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// Perfil propio: foto en Supabase Storage y pocos datos de contacto.
class LuxuryProfileDialog extends StatefulWidget {
  const LuxuryProfileDialog({super.key, required this.store});
  final RestaurantStore store;

  @override
  State<LuxuryProfileDialog> createState() => _LuxuryProfileDialogState();
}

class _LuxuryProfileDialogState extends State<LuxuryProfileDialog> {
  late final TextEditingController _personalEmail;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _department;
  String? _error;
  bool _busy = false;

  RestaurantStore get store => widget.store;
  StaffMember? get member => store.currentStaffMember;

  @override
  void initState() {
    super.initState();
    final m = member;
    _personalEmail = TextEditingController(text: m?.personalEmail ?? '');
    _phone = TextEditingController(text: m?.phone ?? '');
    _address = TextEditingController(text: m?.address ?? '');
    _department = TextEditingController(text: m?.department ?? '');
  }

  @override
  void dispose() {
    _personalEmail.dispose();
    _phone.dispose();
    _address.dispose();
    _department.dispose();
    super.dispose();
  }

  Future<void> _selectPhoto() async {
    final current = member;
    if (_busy || current == null) return;
    setState(() => _error = null);
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (photo == null || !mounted) return;
      final dot = photo.name.lastIndexOf('.');
      final extension = dot < 0 ? '' : photo.name.substring(dot + 1);
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() => _busy = true);
      await showBlockingProgress(
        context,
        label: 'Subiendo foto…',
        action: () => store.uploadStaffPhoto(
          member: current,
          bytes: bytes,
          extension: extension,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = LuxuryFeedback.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await showBlockingProgress(
        context,
        label: 'Guardando perfil…',
        action: () => store.updateOwnStaffProfile(
          personalEmail: _personalEmail.text,
          phone: _phone.text,
          address: _address.text,
          department: _department.text,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = LuxuryFeedback.message(error);
          _busy = false;
        });
      }
    }
  }

  Widget _readOnly(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(TextSpan(
      text: '$label  ',
      style: const TextStyle(fontWeight: FontWeight.w700),
      children: [
        TextSpan(
          text: value.isEmpty ? 'Sin registrar' : value,
          style: const TextStyle(fontWeight: FontWeight.normal),
        ),
      ],
    )),
  );

  @override
  Widget build(BuildContext context) {
    final m = member;
    if (m == null) {
      return AlertDialog(
        title: const Text('Mi perfil'),
        content: const Text('No se encontró el perfil de este usuario.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      );
    }
    return AlertDialog(
      title: const Text('Mi perfil'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Column(children: [
                staffAvatar(store, m, radius: 44),
                TextButton.icon(
                  onPressed: _busy || store.isDemo ? null : _selectPhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Cambiar fotografía'),
                ),
                if (store.isDemo)
                  const Text('La carga de fotos requiere una cuenta conectada.',
                      style: TextStyle(color: Colors.black54, fontSize: 12)),
              ])),
              const SizedBox(height: 8),
              Text(m.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('${m.role.label} · ${staffEmploymentLabel(m.employmentStatus)}'),
              const SizedBox(height: 10),
              _readOnly('Código de empleado', m.employeeCode),
              _readOnly('Documento de identidad', m.documentId),
              _readOnly('Correo de acceso', store.currentUserEmail),
              const SizedBox(height: 10),
              TextField(
                controller: _personalEmail,
                enabled: !_busy && !store.isDemo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo personal'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                enabled: !_busy && !store.isDemo,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _address,
                enabled: !_busy && !store.isDemo,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _department,
                enabled: !_busy && !store.isDemo,
                decoration: const InputDecoration(labelText: 'Área de trabajo'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFB3261E))),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        FilledButton(
          onPressed: _busy || store.isDemo ? null : _save,
          child: const Text('Guardar perfil'),
        ),
      ],
    );
  }
}

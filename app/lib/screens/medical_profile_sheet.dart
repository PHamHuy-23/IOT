import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_medical_profile.dart';
import '../providers/user_data_provider.dart';
import '../themes/app_theme.dart';

class MedicalProfileSheet extends StatefulWidget {
  final UserMedicalProfile profile;

  const MedicalProfileSheet({super.key, required this.profile});

  @override
  State<MedicalProfileSheet> createState() => _MedicalProfileSheetState();
}

class _MedicalProfileSheetState extends State<MedicalProfileSheet> {
  late final TextEditingController _bloodCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _emergencyCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _bloodCtrl = TextEditingController(text: p.bloodType ?? '');
    _heightCtrl =
        TextEditingController(text: p.heightCm?.toString() ?? '');
    _weightCtrl =
        TextEditingController(text: p.weightKg?.toString() ?? '');
    _allergiesCtrl = TextEditingController(text: p.allergies ?? '');
    _emergencyCtrl =
        TextEditingController(text: p.emergencyContact ?? '');
  }

  @override
  void dispose() {
    _bloodCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _allergiesCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final profile = widget.profile.copyWith(
      bloodType: _bloodCtrl.text.trim().isEmpty
          ? null
          : _bloodCtrl.text.trim(),
      heightCm: int.tryParse(_heightCtrl.text.trim()),
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      allergies: _allergiesCtrl.text.trim().isEmpty
          ? null
          : _allergiesCtrl.text.trim(),
      emergencyContact: _emergencyCtrl.text.trim().isEmpty
          ? null
          : _emergencyCtrl.text.trim(),
    );
    await context.read<UserDataProvider>().saveMedicalProfile(profile);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.subtleGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chỉnh sửa ID Y tế',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _field('Nhóm máu', _bloodCtrl, 'VD: O+'),
            _field('Chiều cao (cm)', _heightCtrl, '168'),
            _field('Cân nặng (kg)', _weightCtrl, '54'),
            _field('Dị ứng', _allergiesCtrl, 'Penicillin, Đậu phộng'),
            _field('Liên hệ khẩn cấp', _emergencyCtrl, 'Tên — SĐT'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Lưu',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.subtleGrey),
              filled: true,
              fillColor: AppTheme.black,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

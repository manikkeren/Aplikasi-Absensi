import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../utils/device_helper.dart';
import 'success_screen.dart';

class AbsensiFormScreen extends StatefulWidget {
  const AbsensiFormScreen({super.key});
  @override
  State<AbsensiFormScreen> createState() => _AbsensiFormScreenState();
}

class _AbsensiFormScreenState extends State<AbsensiFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _nim = TextEditingController();
  final TextEditingController _kelas = TextEditingController();
  final TextEditingController _deviceController =
      TextEditingController(text: 'Memuat...');
  String _jenis = 'Laki-Laki';
  bool _loading = false;

  static const double _fieldHeight = 48.0;

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    final name = await DeviceHelper.getDeviceName();
    if (!mounted) return;
    _deviceController.text = name;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final att = Attendance(
      nama: _nama.text.trim(),
      nim: _nim.text.trim(),
      kelas: _kelas.text.trim(),
      jenisKelamin: _jenis,
      device: _deviceController.text,
    );

    try {
      // Simpan data secara lokal
      await LocalStorageService.saveAttendance(att);

      final res = await ApiService.submitAttendance(att);
      final code = res['statusCode'] ?? 0;
      final body = res['body'];

      String msg = 'Response $code';
      if (body is Map) {
        msg = body['message']?.toString() ?? msg;
      }

      if (code >= 200 &&
          code < 300 &&
          body is Map &&
          (body['status'] == 'success' || body['status'] == true)) {
        if (!mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => SuccessScreen(message: msg)));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _inputContainer({required Widget child}) {
    return Container(
      height: _fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    required String label,
  }) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667EEA))),
                if (state.hasError)
                  Text(' ${state.errorText}',
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            _inputContainer(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                readOnly: readOnly,
                onChanged: (value) => state.didChange(value),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dropdownField({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return FormField<String>(
      initialValue: value,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667EEA))),
            const SizedBox(height: 8),
            _inputContainer(
              child: DropdownButton<String>(
                value: state.value,
                items: items,
                onChanged: (v) {
                  state.didChange(v);
                  onChanged(v);
                },
                isExpanded: true,
                underline: const SizedBox(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nama.dispose();
    _nim.dispose();
    _kelas.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667EEA),
              const Color(0xFF764BA2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header dengan icon
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Form Absensi',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Silakan lengkapi data diri Anda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Form Card
                    Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Nama
                            _textField(
                              controller: _nama,
                              hint: 'Nama Anda',
                              label: 'Nama',
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'wajib di isi!*'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // NIM
                            _textField(
                              controller: _nim,
                              hint: 'Nomor Induk Mahasiswa',
                              keyboardType: TextInputType.number,
                              label: 'NIM',
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'wajib di isi!*'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Jenis Kelamin
                            _dropdownField(
                              value: _jenis,
                              label: 'Jenis Kelamin',
                              items: const [
                                DropdownMenuItem(
                                    value: 'Laki-Laki',
                                    child: Text('Laki-Laki')),
                                DropdownMenuItem(
                                    value: 'Perempuan',
                                    child: Text('Perempuan')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _jenis = v ?? 'Laki-Laki'),
                            ),
                            const SizedBox(height: 16),

                            // Device
                            _textField(
                              controller: _deviceController,
                              hint: 'Mark dan Model Device yang Digunakan',
                              readOnly: true,
                              label: 'Jenis Device',
                            ),
                            const SizedBox(height: 16),

                            // Kelas
                            _textField(
                              controller: _kelas,
                              hint: 'Kelas Anda',
                              label: 'Kelas',
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'wajib di isi!*'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667EEA),
                            const Color(0xFF764BA2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _loading ? null : _submit,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_loading)
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  _loading ? 'Mengirim...' : 'Kirim Absensi',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Refresh Button
                    TextButton.icon(
                      onPressed: _loadDevice,
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: const Text(
                        'Refresh Device',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

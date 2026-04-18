import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeteor/main.dart';

class EditProfile extends StatefulWidget {
  final String title;
  final String initialValue;
  final String hint;
  final int? maxLength;
  final Future<void> Function(String) onSave;

  const EditProfile({
    super.key,
    required this.title,
    required this.initialValue,
    required this.hint,
    this.maxLength,
    required this.onSave,
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOverLimit = widget.maxLength != null && _controller.text.length > widget.maxLength!;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.spaceIndigo,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.thistle,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: AppColors.thistle.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            cursorColor: AppColors.honeyBronze,
            maxLength: widget.maxLength,
            maxLines: widget.title.contains('Bio') ? 4 : 1,
            autofocus: true,
            style: GoogleFonts.dmSans(color: AppColors.thistle),
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.dmSans(
                color: AppColors.thistle.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: AppColors.prussianBlue.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              counterStyle: GoogleFonts.dmSans(
                color: isOverLimit ? Colors.redAccent : AppColors.vintageLavender,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isOverLimit
                    ? AppColors.vintageLavender.withValues(alpha: 0.4)
                    : AppColors.honeyBronze,
                foregroundColor: isOverLimit
                    ? AppColors.thistle.withValues(alpha: 0.5)
                    : AppColors.prussianBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isOverLimit || _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      final value = _controller.text.trim();
                      if (value.isNotEmpty) {
                        await widget.onSave(value);
                      }
                      if (mounted) Navigator.of(context).pop();
                    },
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.prussianBlue))
                : Text(
                  'Save',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showEditProfile({
  required BuildContext context,
  required String title,
  required String initialValue,
  required String hint,
  int? maxLength,
  required Future<void> Function(String) onSave,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => EditProfile(
      title: title,
      initialValue: initialValue,
      hint: hint,
      maxLength: maxLength,
      onSave: onSave,
    ),
  );
}

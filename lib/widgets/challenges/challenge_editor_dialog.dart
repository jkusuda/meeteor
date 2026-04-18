import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meeteor/main.dart';
import 'package:meeteor/core/challenge_models.dart';
import 'package:meeteor/services/challenge_service.dart';

// Admin dialog for creating or editing a daily challenge.
class ChallengeEditorDialog {
  static Future<String?> show(
    BuildContext context, {
    DailyChallenge? challenge,
    required ChallengeService challengeService,
    required VoidCallback onSaved,
  }) async {
    final titleController = TextEditingController(text: challenge?.title ?? '');
    final descriptionController = TextEditingController(
      text: challenge?.description ?? '',
    );
    final activationDateController = TextEditingController(
      text: dateKey(challenge?.activationDate ?? DateTime.now()),
    );
    final tipControllers = List.generate(
      3,
      (index) => TextEditingController(
        text: challenge?.tips.elementAtOrNull(index) ?? '',
      ),
    );
    String selectedIcon = challenge?.iconName ?? 'star';

    // Image picker state
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    final picker = ImagePicker();

    final message = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.spaceIndigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                challenge == null
                    ? 'Create Daily Challenge'
                    : 'Edit Daily Challenge',
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedIcon,
                        dropdownColor: AppColors.spaceIndigo,
                        decoration: _inputDecoration(
                          'Icon',
                          hasFocusBorder: false,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'star',
                            child: Text(
                              'Star',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'camera',
                            child: Text(
                              'Camera',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'moon',
                            child: Text(
                              'Moon',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedIcon = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: _inputDecoration('Description'),
                      ),
                      const SizedBox(height: 12),

                      // Image picker
                      GestureDetector(
                        onTap: () async {
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            setDialogState(() {
                              selectedImage = pickedFile;
                              selectedImageBytes = bytes;
                            });
                          }
                        },
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.prussianBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  (selectedImage == null &&
                                      (challenge?.imageUrl.isEmpty ?? true))
                                  ? AppColors.honeyBronze.withValues(alpha: 0.5)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: selectedImageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    selectedImageBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : (challenge?.imageUrl.isNotEmpty ?? false)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: buildChallengeImage(
                                    imagePath: challenge!.imageUrl,
                                    fit: BoxFit.contain,
                                    iconName: challenge.iconName,
                                    fallbackBuilder: () => _imagePlaceholder(),
                                  ),
                                )
                              : _imagePlaceholder(),
                        ),
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        controller: activationDateController,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Activation Date')
                            .copyWith(
                              suffixIcon: Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.thistle,
                                size: 18,
                              ),
                            ),
                        onTap: () async {
                          final initial =
                              DateTime.tryParse(
                                activationDateController.text,
                              ) ??
                              DateTime.now();
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: initial,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (!dialogContext.mounted) return;
                          if (picked != null) {
                            activationDateController.text = dateKey(picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        tipControllers.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(
                            bottom: index == tipControllers.length - 1 ? 0 : 12,
                          ),
                          child: TextField(
                            controller: tipControllers[index],
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Tip ${index + 1}'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.thistle),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final tips = tipControllers
                        .map((c) => c.text.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    final result = await challengeService.saveChallenge(
                      existing: challenge,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      activationDateRaw: activationDateController.text.trim(),
                      selectedIcon: selectedIcon,
                      tips: tips,
                      imageFile: selectedImage,
                      imageBytes: selectedImageBytes,
                    );

                    if (!dialogContext.mounted) return;
                    if (result.$1) {
                      onSaved();
                      Navigator.of(dialogContext).pop(result.$2);
                    } else {
                      await showDialog<void>(
                        context: dialogContext,
                        builder: (errorCtx) => AlertDialog(
                          backgroundColor: AppColors.spaceIndigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'Cannot Save Challenge',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            result.$2,
                            style: TextStyle(color: AppColors.thistle),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(errorCtx).pop(),
                              child: Text(
                                'OK',
                                style: TextStyle(color: AppColors.honeyBronze),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.honeyBronze,
                    foregroundColor: AppColors.prussianBlue,
                  ),
                  child: Text(challenge == null ? 'Create' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    return message;
  }

  static Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 48, color: AppColors.honeyBronze),
        const SizedBox(height: 8),
        Text(
          'Tap to select an image',
          style: TextStyle(color: AppColors.thistle, fontSize: 14),
        ),
      ],
    );
  }

  static InputDecoration _inputDecoration(
    String label, {
    bool hasFocusBorder = true,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.thistle),
      filled: true,
      fillColor: AppColors.prussianBlue,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.vintageLavender.withValues(alpha: 0.45),
        ),
      ),
      focusedBorder: hasFocusBorder
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.honeyBronze.withValues(alpha: 0.9),
              ),
            )
          : null,
    );
  }
}

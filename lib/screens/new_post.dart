import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meeteor/main.dart'; // AppColors
import 'package:meeteor/services/post_service.dart';
import 'package:meeteor/core/app_router.dart'; // listRefreshNotifier

class NewPostPage extends StatefulWidget {
  final String? challengeId;
  final String? challengeTitle;
  final String? challengeDescription;

  const NewPostPage({
    super.key,
    this.challengeId,
    this.challengeTitle,
    this.challengeDescription,
  });

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final _postService = PostService();
  final _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _imageBytes;

  final _captionController = TextEditingController();
  final _isoController = TextEditingController();
  final _apertureController = TextEditingController();
  final _exposureController = TextEditingController();
  final _cameraController = TextEditingController();

  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _isoController.dispose();
    _apertureController.dispose();
    _exposureController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submitPost() async {
    final description = _captionController.text.trim();

    if (_selectedImage == null || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A comment is required.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final extension = _selectedImage!.name
          .split('.')
          .last
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      final cleanExt = extension.isNotEmpty ? extension : 'jpg';

      await _postService.createPost(
        imageFile: _selectedImage,
        imageBytes: _imageBytes!,
        extension: cleanExt,
        caption: description,
        iso: _isoController.text.trim(),
        aperture: _apertureController.text.trim(),
        exposure: _exposureController.text.trim(),
        camera: _cameraController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.challengeTitle == null
                ? 'Post published successfully!'
                : 'Challenge submission published successfully!',
          ),
        ),
      );

      listRefreshNotifier.value++;

      setState(() {
        _selectedImage = null;
        _imageBytes = null;
      });
      _captionController.clear();
      _isoController.clear();
      _apertureController.clear();
      _exposureController.clear();
      _cameraController.clear();

      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading post: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int? maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        cursorColor: AppColors.honeyBronze,
        showCursor: true,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: TextStyle(color: AppColors.thistle),
          filled: true,
          fillColor: AppColors.spaceIndigo,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.honeyBronze),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussianBlue,
      body: Stack(
        children: [
          // Starry sky background
          Positioned.fill(
            child: Image.asset(
              'assets/starry_sky_bg_1.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title matching Daily Challenges style
                  const SizedBox(height: 8),
                  Text(
                    'New Post',
                    style: TextStyle(
                      color: AppColors.thistle,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.challengeTitle != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.spaceIndigo,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.honeyBronze.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge Submission',
                            style: TextStyle(
                              color: AppColors.honeyBronze,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.challengeTitle!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.challengeDescription != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.challengeDescription!,
                              style: TextStyle(
                                color: AppColors.thistle,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: AppColors.spaceIndigo,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedImage == null
                              ? AppColors.honeyBronze.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 48,
                                  color: AppColors.honeyBronze,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to select a photo',
                                  style: TextStyle(
                                    color: AppColors.thistle,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    _captionController,
                    'Comment',
                    maxLines: null,
                    required: true,
                  ),
                  Text(
                    'Camera Settings (Optional)',
                    style: TextStyle(
                      color: AppColors.honeyBronze,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_cameraController, 'Camera (e.g. Sony A7III)'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_isoController, 'ISO (e.g. 3200)'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          _apertureController,
                          'Aperture (e.g. f/2.8)',
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(_exposureController, 'Exposure (e.g. 15s)'),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.honeyBronze,
                        foregroundColor: AppColors.prussianBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.prussianBlue,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Publishing...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Publish Post',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

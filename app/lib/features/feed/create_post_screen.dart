import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repository.dart';

/// Compose a new post: pick photos from the gallery + optional caption.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _caption = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _images = [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() => _images.addAll(picked.map((x) => File(x.path))));
  }

  Future<void> _submit() async {
    final family = ref.read(currentFamilyProvider);
    if (family == null) return;
    if (_images.isEmpty && _caption.text.trim().isEmpty) {
      setState(() => _error = 'Add a photo or a caption.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(repositoryProvider).createPost(
            familyId: family.id,
            content: _caption.text.trim(),
            images: _images,
          );
      ref.invalidate(feedProvider(family.id));
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New memory'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Share'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_images.isNotEmpty)
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (i == _images.length) {
                      return _AddTile(onTap: _pick);
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_images[i],
                          width: 96, height: 96, fit: BoxFit.cover),
                    );
                  },
                ),
              )
            else
              _AddTile(onTap: _pick, large: true),
            const SizedBox(height: 16),
            TextField(
              controller: _caption,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Caption',
                hintText: "Write something about this moment…",
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text('Uploading…')),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap, this.large = false});
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 140.0 : 96.0;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: large ? double.infinity : size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined, size: 32),
      ),
    );
  }
}

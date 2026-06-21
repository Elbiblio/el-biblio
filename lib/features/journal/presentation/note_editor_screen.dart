import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../../../core/di/app_providers.dart';
import '../../../../core/services/xp_service.dart';
import '../domain/models/note.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialText,
    this.initialVirtues,
    this.meditationSessionId,
  });

  final String? noteId;
  final String? initialTitle;
  final String? initialText;
  final List<String>? initialVirtues;

  /// If this note was created from a meditation session, this is the session ID.
  final String? meditationSessionId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _quillController = quill.QuillController.basic();
  final FocusNode _textFocusNode = FocusNode();
  final _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isPublic = false;
  bool _isPinned = false;
  List<String> _selectedVirtues = [];
  bool _showReference = false;
  Timer? _saveTimer;
  String? _meditationSessionId;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // Load initial data
    _meditationSessionId = widget.meditationSessionId;
    if (widget.noteId != null) {
      _loadNote();
    } else {
      if (widget.initialTitle != null) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialText != null) {
        _loadText(widget.initialText!);
      }
      if (widget.initialVirtues != null) {
        _selectedVirtues = List.from(widget.initialVirtues!);
      }
    }

    // Add listener for auto-save with debouncing and title update
    _titleController.addListener(_onTextChanged);
    _quillController.addListener(_onTextChanged);
  }

  void _onTextChanged([dynamic _]) {
    // Trigger UI update for header title
    if (mounted) {
      setState(() {});
    }

    // Cancel previous timer
    _saveTimer?.cancel();

    // Set new timer for debounced save
    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _saveInBackground();
      }
    });
  }

  void _loadText(String text) {
    if (text.isEmpty) return;
    try {
      final decoded = jsonDecode(text);
      _quillController.document = quill.Document.fromJson(decoded);
    } catch (e) {
      // Fallback for old plain text notes
      _quillController.document = quill.Document()..insert(0, text);
    }
  }

  Future<void> _loadNote() async {
    final journalState = ref.read(journalProvider);
    final note = journalState.notes.cast<Note?>().firstWhere(
      (n) => n?.id.toString() == widget.noteId,
      orElse: () => null,
    );

    if (note != null && mounted) {
      _titleController.text = note.title ?? '';
      if (note.text != null) {
        _loadText(note.text!);
      }
      setState(() {
        _isPublic = note.isPublic;
        _isPinned = note.isPinned;
        _selectedVirtues = List.from(note.virtues);
      });
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    _textFocusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  String _getNoteText() {
    final delta = _quillController.document.toDelta();
    return jsonEncode(delta.toJson());
  }

  bool _isNoteEmpty() {
    return _titleController.text.trim().isEmpty &&
        _quillController.document.isEmpty();
  }

  Future<void> _saveInBackground() async {
    if (_isNoteEmpty()) {
      if (widget.noteId != null) {
        try {
          final notifier = ref.read(journalProvider.notifier);
          await notifier.deleteNote(int.tryParse(widget.noteId!) ?? 0);
        } catch (_) {}
      }
      return;
    }

    try {
      final notifier = ref.read(journalProvider.notifier);
      final text = _getNoteText();

      if (widget.noteId != null) {
        await notifier.updateNote(
          int.tryParse(widget.noteId!) ?? 0,
          title: _titleController.text,
          text: text,
          isPublic: _isPublic,
          isPinned: _isPinned,
          virtues: _selectedVirtues,
        );
      } else {
        await notifier.createNote(
          _titleController.text,
          text,
          isPublic: _isPublic,
          isPinned: _isPinned,
          virtues: _selectedVirtues,
          meditationSessionId: _meditationSessionId,
        );
      }
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  Future<void> _save() async {
    if (_isNoteEmpty()) {
      if (widget.noteId != null) {
        try {
          final notifier = ref.read(journalProvider.notifier);
          await notifier.deleteNote(int.tryParse(widget.noteId!) ?? 0);
        } catch (_) {}
      }
      if (mounted) {
        context.pop();
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(journalProvider.notifier);
      final text = _getNoteText();

      if (widget.noteId != null) {
        await notifier.updateNote(
          int.tryParse(widget.noteId!) ?? 0,
          title: _titleController.text,
          text: text,
          isPublic: _isPublic,
          isPinned: _isPinned,
          virtues: _selectedVirtues,
        );
      } else {
        // Add XP for creating a new journal entry
        await XPService.instance.addXP(
          type: XPActivityType.journaling,
          description:
              'Created journal entry: ${_titleController.text.isNotEmpty ? _titleController.text : "Untitled"}',
          metadata: {
            'title': _titleController.text,
            'virtues': _selectedVirtues,
            'has_text': text.isNotEmpty,
          },
        );

        await notifier.createNote(
          _titleController.text,
          text,
          isPublic: _isPublic,
          isPinned: _isPinned,
          virtues: _selectedVirtues,
          meditationSessionId: _meditationSessionId,
        );
      }

      if (mounted) {
        ref.read(soundServiceProvider).playSuccess();
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleVirtue(String virtue) {
    setState(() {
      if (_selectedVirtues.contains(virtue)) {
        _selectedVirtues.remove(virtue);
      } else {
        _selectedVirtues.add(virtue);
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${error.errorMsg}')));
          }
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _lastWords = result.recognizedWords;
              if (result.finalResult) {
                final currentText = _quillController.document.toPlainText();
                final needsSpace =
                    currentText.isNotEmpty &&
                    !currentText.endsWith(' ') &&
                    !currentText.endsWith('\n');
                final textToInsert = (needsSpace ? ' ' : '') + _lastWords;
                final index = _quillController.document.length - 1;
                _quillController.document.insert(index, textToInsert);
                _lastWords = '';
              }
            });
          },
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition not available. Check permissions.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = isDark ? const Color(0xFF0f172a) : const Color(0xFFf8fafc);

    // Check if keyboard is visible for UI adjustments
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        _saveInBackground();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () => context.pop(), // PopScope handles saving
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                    // Dynamic Title with Edit Indicator
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showTitleEditModal(context),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    _titleController.text.isNotEmpty
                                        ? _titleController.text
                                        : 'Untitled Note',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade500,
                                ),
                              ],
                            ),
                            Text(
                              'JOURNAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz, size: 28),
                      onPressed: () {
                        // More options
                      },
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                  ],
                ),
              ),

              // Virtue Tags
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 16,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _VirtueChipTop(
                        label: 'Humility',
                        isSelected: _selectedVirtues.contains('humility'),
                        onTap: () => _toggleVirtue('humility'),
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _VirtueChipTop(
                        label: 'Love',
                        isSelected: _selectedVirtues.contains('love'),
                        onTap: () => _toggleVirtue('love'),
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _VirtueChipTop(
                        label: 'Faith',
                        isSelected: _selectedVirtues.contains('faith'),
                        onTap: () => _toggleVirtue('faith'),
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _VirtueChipTop(
                        label: 'Knowledge',
                        isSelected: _selectedVirtues.contains('knowledge'),
                        onTap: () => _toggleVirtue('knowledge'),
                        primaryColor: primaryColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              // Main Text Area Stack
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: quill.QuillEditor(
                        controller: _quillController,
                        focusNode: _textFocusNode,
                        scrollController: _scrollController,
                        config: const quill.QuillEditorConfig(
                          placeholder: 'Write your reflection...',
                        ),
                      ),
                    ),

                    // Bible Reference Overlay (Variant 3.2 style)
                    if (_showReference)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1e293b)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 40,
                                offset: const Offset(0, -10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.auto_stories,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'DAILY VERSE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () {},
                                    child: Row(
                                      children: [
                                        Text(
                                          'SEARCH',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.search,
                                          size: 14,
                                          color: primaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '"Let your light so shine before men, that they may see your good works, and glorify your Father which is in heaven."',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  height: 1.6,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Matthew 5:16',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Action Bar (when not typing or showing custom toolbar)
              if (!isKeyboardVisible)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  decoration: BoxDecoration(color: bgColor),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white
                            : const Color(0xFF0f172a),
                        foregroundColor: isDark
                            ? const Color(0xFF0f172a)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Save Note',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.check_circle_outline),
                              ],
                            ),
                    ),
                  ),
                ),

              // Toolbar (when keyboard is visible)
              if (isKeyboardVisible)
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? bgColor.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.8),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showReference = !_showReference;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.menu_book,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'CROSS-REF',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: _toggleListening,
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening
                                    ? Colors.red
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade500),
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.image_outlined,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            _textFocusNode.unfocus();
                          },
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTitleEditModal(BuildContext context) {
    final TextEditingController modalController = TextEditingController(
      text: _titleController.text,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Title',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: TextField(
          controller: modalController,
          autofocus: true,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Enter a meaningful title...',
            hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          maxLines: 2,
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (modalController.text.trim().isNotEmpty) {
                setState(() {
                  _titleController.text = modalController.text.trim();
                });
                _onTextChanged(); // Trigger save
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _VirtueChipTop extends StatelessWidget {
  const _VirtueChipTop({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : primaryColor.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

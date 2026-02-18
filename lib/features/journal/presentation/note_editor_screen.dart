import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/di/app_providers.dart';
import '../domain/models/note.dart';
import 'widgets/virtue_picker.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    this.noteId,
  });

  final String? noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  bool _isLoading = false;
  bool _isPublic = false;
  bool _isPinned = false;
  List<String> _selectedVirtues = [];
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    if (widget.noteId != null) {
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    final journalState = ref.read(journalProvider);
    final note = journalState.notes.cast<Note?>().firstWhere(
      (n) => n?.id.toString() == widget.noteId,
      orElse: () => null,
    );

    if (note != null) {
      _titleController.text = note.title ?? '';
      _textController.text = note.text ?? '';
      setState(() {
        _isPublic = note.isPublic;
        _isPinned = note.isPinned;
        _selectedVirtues = List.from(note.virtues);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty && _textController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notifier = ref.read(journalProvider.notifier);
      if (widget.noteId != null) {
        await notifier.updateNote(
          int.parse(widget.noteId!),
          title: _titleController.text,
          text: _textController.text,
          isPublic: _isPublic,
          isPinned: _isPinned,
          virtues: _selectedVirtues,
        );
      } else {
        await notifier.createNote(
          _titleController.text,
          _textController.text,
          isPublic: _isPublic,
          isPinned: _isPinned,
          virtues: _selectedVirtues,
        );
      }
      
      if (mounted) {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${error.errorMsg}')),
            );
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
                // Append to text with proper spacing
                final currentText = _textController.text;
                final needsSpace = currentText.isNotEmpty && 
                                   !currentText.endsWith(' ') && 
                                   !currentText.endsWith('\n');
                _textController.text = currentText + 
                                       (needsSpace ? ' ' : '') + 
                                       _lastWords;
                _lastWords = '';
              }
            });
          },
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available. Check permissions.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId != null ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () {
              setState(() {
                _isPinned = !_isPinned;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isPinned ? 'Note pinned' : 'Note unpinned'),
                  duration: const Duration(milliseconds: 500),
                ),
              );
            },
            tooltip: _isPinned ? 'Unpin' : 'Pin',
          ),
          IconButton(
            icon: Icon(_isPublic ? Icons.public : Icons.public_off),
            onPressed: () {
              setState(() {
                _isPublic = !_isPublic;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isPublic ? 'Note is now public' : 'Note is now private'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: _isPublic ? 'Public' : 'Private',
          ),
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                ) 
              : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  // Virtues Selection
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: VirtuePicker(
                        selectedVirtues: _selectedVirtues,
                        onVirtueToggle: _toggleVirtue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Start writing...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        backgroundColor: _isListening 
            ? Theme.of(context).colorScheme.error 
            : Theme.of(context).colorScheme.primary,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}

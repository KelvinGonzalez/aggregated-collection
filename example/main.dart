import 'package:aggregated_collection/aggregated_collection.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const NotesApp());
}

final AggregatedCollection notesCollection = (CollectionAggregator.instance
      ..setMaximumDocsPerAggregation(2)
      ..setCacheLastDocReferenceFromSnapshotData(true))
    .collection('notes');

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FEATURE USE: AggregatedCollection.doc()
    notesCollection
        .doc("9f948b9e-28fb-4873-9ae3-d8cc7e79b632")
        .then((e) => print(e?.id));
    // FEATURE USE: AggregatedCollection.docGet()
    notesCollection
        .docGet("9f948b9e-28fb-4873-9ae3-d8cc7e79b632")
        .then((e) => print(e?.data));

    return MaterialApp(
      title: 'Aggregated Notes Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feature Demonstration')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Live Stream List (snapshots)'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotesListStreamPage(),
              )),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('One-Time Fetch List (get)'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotesListFuturePage(),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesListStreamPage extends StatelessWidget {
  const NotesListStreamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes (Live Stream)'),
        actions: [
          IconButton(
              onPressed: () => _showAddNoteDialog(context),
              icon: const Icon(Icons.add))
        ],
      ),
      body: StreamBuilder<List<AggregatedDocumentData>>(
        stream: notesCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notes yet!'));
          }
          final notes = snapshot.data!;
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.get('title') ?? 'No Title'),
                onTap: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => NoteDetailPage(
                      noteReference: note.reference,
                      isLive: true,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NotesListFuturePage extends StatefulWidget {
  const NotesListFuturePage({super.key});
  @override
  NotesListFuturePageState createState() => NotesListFuturePageState();
}

class NotesListFuturePageState extends State<NotesListFuturePage> {
  late Future<List<AggregatedDocumentData>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _notesFuture = notesCollection.get();
  }

  void _refreshNotes() {
    _notesFuture = notesCollection.get();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes (One-Time Fetch)'),
        actions: [
          IconButton(onPressed: _refreshNotes, icon: const Icon(Icons.refresh))
        ],
      ),
      body: FutureBuilder<List<AggregatedDocumentData>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notes found.'));
          }
          final notes = snapshot.data!;
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.get('title') ?? 'No Title'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => NoteDetailPage(
                      noteReference: note.reference,
                      isLive: false,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NoteDetailPage extends StatefulWidget {
  final AggregatedDocumentReference noteReference;
  final bool isLive;

  const NoteDetailPage({
    super.key,
    required this.noteReference,
    required this.isLive,
  });

  @override
  NoteDetailPageState createState() => NoteDetailPageState();
}

class NoteDetailPageState extends State<NoteDetailPage> {
  AggregatedDocumentData? _staticNoteData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isLive) {
      _fetchNoteData();
    }
  }

  // FEATURE USE: AggregatedDocumentReference.get()
  Future<void> _fetchNoteData() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.noteReference.get();
      if (mounted) {
        setState(() {
          _staticNoteData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error fetching note: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLive ? 'Note (Live)' : 'Note (Static)'),
        actions: [
          if (!widget.isLive)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchNoteData,
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EditNotePage(noteReference: widget.noteReference),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              widget.noteReference.delete();
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: widget.isLive
          // FEATURE USE: AggregatedDocumentReference.snapshots()
          ? StreamBuilder<AggregatedDocumentData>(
              stream: widget.noteReference.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: Text('Note not found or deleted.'));
                }
                return _NoteContentView(data: snapshot.data!);
              },
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _staticNoteData != null
                  ? _NoteContentView(data: _staticNoteData!)
                  : const Center(child: Text('Note not found.')),
    );
  }
}

class _NoteContentView extends StatelessWidget {
  final AggregatedDocumentData data;
  const _NoteContentView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.get('title') ?? 'No Title',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(data.get('content') ?? ''),
        ],
      ),
    );
  }
}

class EditNotePage extends StatefulWidget {
  final AggregatedDocumentReference noteReference;
  const EditNotePage({super.key, required this.noteReference});

  @override
  EditNotePageState createState() => EditNotePageState();
}

class EditNotePageState extends State<EditNotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // FEATURE USE: .get() is perfect for loading initial form data
    widget.noteReference.get().then((noteData) {
      if (mounted) {
        setState(() {
          _titleController.text = noteData.get('title') ?? '';
          _contentController.text = noteData.get('content') ?? '';
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty) return;
    FocusScope.of(context).unfocus();

    // FEATURE USE: .set() overwrites the sub-document's data
    await widget.noteReference.set({
      'title': _titleController.text,
      'content': _contentController.text,
    });

    // FEATURE USE: .update() modifies fields without overwriting
    await widget.noteReference.update({
      'last_updated': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        actions: [
          IconButton(onPressed: _saveNote, icon: const Icon(Icons.save))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 16),
                  Expanded(
                      child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          decoration:
                              const InputDecoration(labelText: 'Content'))),
                ],
              ),
            ),
    );
  }
}

void _showAddNoteDialog(BuildContext context) {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Note'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content')),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                // FEATURE USE: AggregatedCollection.add()
                notesCollection.add({
                  'title': titleController.text,
                  'content': contentController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      });
}

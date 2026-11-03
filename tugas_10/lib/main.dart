import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DailyNoteApp());
}

// =====================================================
// APP CONFIGURATION
// =====================================================

class AppColors {
  static const primary = Color(0xFF536DFE);
  static const secondary = Color(0xFF8065F7);
  static const background = Color(0xFFF5F6FC);
  static const text = Color(0xFF202B48);
  static const muted = Color(0xFF8991A7);
  static const white = Colors.white;
}

class DailyNoteApp extends StatelessWidget {
  const DailyNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.white,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
        ),
      ),
      home: const DailyNoteHome(),
    );
  }
}

// =====================================================
// NOTE MODEL
// =====================================================

class Note {
  final String id;
  String title;
  String content;
  String category;
  final DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'Pribadi',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// =====================================================
// DATE FORMAT
// =====================================================

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatLongDate(DateTime date) {
  const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  return '${days[date.weekday - 1]}, ${date.day} '
      '${months[date.month - 1]} ${date.year}';
}

// =====================================================
// MAIN HOME
// =====================================================

class DailyNoteHome extends StatefulWidget {
  const DailyNoteHome({super.key});

  @override
  State<DailyNoteHome> createState() => _DailyNoteHomeState();
}

class _DailyNoteHomeState extends State<DailyNoteHome> {
  final List<Note> notes = [];

  final TextEditingController searchController = TextEditingController();

  int selectedPage = 0;
  String selectedCategory = 'Semua';
  String searchText = '';
  bool isLoading = true;

  final List<String> categories = [
    'Semua',
    'Kuliah',
    'Pribadi',
    'Ide',
    'Pekerjaan',
  ];

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ===================================================
  // LOAD NOTES
  // ===================================================

  Future<void> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('daily_notes');

      if (savedData != null) {
        final List<dynamic> decoded = jsonDecode(savedData);

        notes
          ..clear()
          ..addAll(
            decoded.map(
              (item) => Note.fromJson(Map<String, dynamic>.from(item)),
            ),
          );
      }
    } catch (e) {
      debugPrint('Gagal membaca catatan: $e');
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ===================================================
  // SAVE NOTES
  // ===================================================

  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(notes.map((note) => note.toJson()).toList());

    await prefs.setString('daily_notes', encoded);
  }

  // ===================================================
  // FILTER NOTES
  // ===================================================

  List<Note> get filteredNotes {
    return notes.where((note) {
      final matchesCategory =
          selectedCategory == 'Semua' || note.category == selectedCategory;

      final query = searchText.toLowerCase();

      final matchesSearch =
          note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ===================================================
  // ADD NOTE
  // ===================================================

  Future<void> addNote() async {
    final result = await showModalBottomSheet<Note>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NoteEditorSheet(),
    );

    if (!mounted || result == null) return;

    setState(() {
      notes.insert(0, result);
    });

    await saveNotes();

    if (!mounted) return;
    showMessage('Catatan berhasil ditambahkan');
  }

  // ===================================================
  // EDIT NOTE
  // ===================================================

  Future<void> editNote(Note note) async {
    final result = await showModalBottomSheet<Note>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditorSheet(note: note),
    );

    if (!mounted || result == null) return;

    setState(() {
      final index = notes.indexWhere((n) => n.id == note.id);

      if (index != -1) {
        notes[index] = result;
      }
    });

    await saveNotes();

    if (!mounted) return;
    showMessage('Catatan berhasil diperbarui');
  }

  // ===================================================
  // DELETE NOTE
  // ===================================================

  Future<void> deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Catatan?'),
          content: const Text('Apakah kamu yakin ingin menghapus catatan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      notes.removeWhere((n) => n.id == note.id);
    });

    await saveNotes();

    if (!mounted) return;
    showMessage('Catatan berhasil dihapus');
  }

  // ===================================================
  // MESSAGE
  // ===================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.text,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ===================================================
  // OPEN DETAIL
  // ===================================================

  void openDetail(Note note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return NoteDetailSheet(
          note: note,
          onEdit: () {
            Navigator.pop(context);
            editNote(note);
          },
          onDelete: () {
            Navigator.pop(context);
            deleteNote(note);
          },
        );
      },
    );
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: selectedPage,
                children: [
                  buildHomePage(),
                  buildCategoryPage(),
                  buildCalendarPage(),
                  buildSettingsPage(),
                ],
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedPage,
        onDestinationSelected: (index) {
          setState(() {
            selectedPage = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8ECFF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Kategori',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
      floatingActionButton: selectedPage == 3
          ? null
          : FloatingActionButton(
              onPressed: addNote,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 30),
            ),
    );
  }

  // ===================================================
  // HOME PAGE
  // ===================================================

  Widget buildHomePage() {
    final displayed = filteredNotes;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'DailyNote.',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'SELAMAT DATANG KEMBALI',
                  style: TextStyle(
                    color: Color(0xFFE1E5FF),
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Apa ceritamu hari ini?',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Simpan momen kecil yang berarti.',
                  style: TextStyle(fontSize: 13, color: Color(0xFFE5E8FF)),
                ),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL CATATAN',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${notes.length} Catatan',
                              style: const TextStyle(
                                fontSize: 23,
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Semua ceritamu tersimpan di sini.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 53,
                        height: 53,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: AppColors.primary,
                          size: 29,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 19),
                Text(
                  formatLongDate(DateTime.now()),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // SEARCH
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Temukan Catatan',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari judul atau isi catatan...',
                    hintStyle: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                searchText = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${notes.length} catatan',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 39,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final active = selectedCategory == category;

                      return ChoiceChip(
                        label: Text(category),
                        selected: active,
                        onSelected: (_) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: active ? Colors.white : AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                        showCheckmark: false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 23),
                Row(
                  children: [
                    const Text(
                      'Catatan Terbaru',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${displayed.length} ditemukan',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
              ],
            ),
          ),
        ),

        // NOTES GRID
        if (displayed.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyNotes(hasSearch: searchText.isNotEmpty, onAdd: addNote),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final note = displayed[index];

                return NoteCard(note: note, onTap: () => openDetail(note));
              }, childCount: displayed.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 164,
              ),
            ),
          ),
      ],
    );
  }

  // ===================================================
  // CATEGORY PAGE
  // ===================================================

  Widget buildCategoryPage() {
    final categoryCounts = {
      for (final category in categories.skip(1))
        category: notes.where((n) => n.category == category).length,
    };

    const icons = {
      'Kuliah': Icons.school_rounded,
      'Pribadi': Icons.favorite_rounded,
      'Ide': Icons.lightbulb_rounded,
      'Pekerjaan': Icons.work_rounded,
    };

    const colors = [
      Color(0xFFE8EDFF),
      Color(0xFFFFEAF0),
      Color(0xFFFFF1DF),
      Color(0xFFE3F7ED),
    ];

    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Kelompokkan ceritamu agar lebih mudah ditemukan.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final category = categories[index + 1];

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                    selectedPage = 0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 47,
                        height: 47,
                        decoration: BoxDecoration(
                          color: colors[index],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icons[category], color: AppColors.primary),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${categoryCounts[category]} catatan',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: categories.length - 1),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 13,
              crossAxisSpacing: 13,
              mainAxisExtent: 165,
            ),
          ),
        ),
      ],
    );
  }

  // ===================================================
  // CALENDAR PAGE
  // ===================================================

  Widget buildCalendarPage() {
    final sortedNotes = [...notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kalender Catatan',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Lihat kembali catatan yang pernah kamu buat.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        formatLongDate(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${notes.length} cerita tersimpan',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Riwayat Catatan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        if (sortedNotes.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Belum ada riwayat catatan.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final note = sortedNotes[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: NoteListTile(
                    note: note,
                    onTap: () => openDetail(note),
                  ),
                );
              }, childCount: sortedNotes.length),
            ),
          ),
      ],
    );
  }

  // ===================================================
  // SETTINGS PAGE
  // ===================================================

  Widget buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        const Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: 26,
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Informasi dan pengaturan aplikasi.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            children: [
              Icon(Icons.menu_book_rounded, size: 48, color: Colors.white),
              SizedBox(height: 12),
              Text(
                'DailyNote',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Tempat menyimpan setiap ceritamu.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          'Penyimpanan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        settingTile(
          Icons.storage_rounded,
          'Total Catatan',
          '${notes.length} catatan tersimpan',
        ),
        settingTile(
          Icons.phone_android_rounded,
          'Penyimpanan Lokal',
          'Data tersimpan pada perangkat ini',
        ),
        const SizedBox(height: 25),
        const Text(
          'Tentang Aplikasi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        settingTile(
          Icons.info_outline_rounded,
          'Versi Aplikasi',
          'DailyNote v1.0.0',
        ),
        const SizedBox(height: 25),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: notes.isEmpty
              ? null
              : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Hapus Semua Catatan?'),
                      content: const Text(
                        'Semua catatan akan dihapus secara permanen.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text(
                            'Hapus Semua',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (!mounted || confirm != true) return;

                  setState(() {
                    notes.clear();
                  });

                  await saveNotes();

                  if (!mounted) return;
                  showMessage('Semua catatan berhasil dihapus');
                },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Hapus Semua Catatan'),
        ),
      ],
    );
  }

  Widget settingTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFFF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// NOTE CARD
// =====================================================

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'Kuliah': const Color(0xFFE9EDFF),
      'Pribadi': const Color(0xFFFFEAF0),
      'Ide': const Color(0xFFFFF1DF),
      'Pekerjaan': const Color(0xFFE4F7EC),
    };

    final icons = {
      'Kuliah': Icons.school_rounded,
      'Pribadi': Icons.favorite_rounded,
      'Ide': Icons.lightbulb_rounded,
      'Pekerjaan': Icons.work_rounded,
    };

    final categoryColor = colors[note.category] ?? const Color(0xFFE9EDFF);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 37,
                    width: 37,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icons[note.category] ?? Icons.notes_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    color: Color(0xFFADB5C9),
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(note.updatedAt),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// NOTE LIST TILE
// =====================================================

class NoteListTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteListTile({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFECEFFF),
          child: Icon(Icons.menu_book_rounded, color: AppColors.primary),
        ),
        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        subtitle: Text(
          '${note.category} • ${formatDate(note.updatedAt)}',
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      ),
    );
  }
}

// =====================================================
// EMPTY STATE
// =====================================================

class EmptyNotes extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;

  const EmptyNotes({super.key, required this.hasSearch, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: const BoxDecoration(
                color: Color(0xFFECEFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.note_add_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasSearch ? 'Catatan tidak ditemukan' : 'Belum ada catatan',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasSearch
                  ? 'Coba kata kunci pencarian lainnya.'
                  : 'Mulai tuliskan cerita pertamamu hari ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Buat Catatan'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================
// NOTE EDITOR SHEET
// =====================================================

class NoteEditorSheet extends StatefulWidget {
  final Note? note;

  const NoteEditorSheet({super.key, this.note});

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late final TextEditingController titleController;
  late final TextEditingController contentController;

  String selectedCategory = 'Pribadi';

  final List<String> categories = ['Kuliah', 'Pribadi', 'Ide', 'Pekerjaan'];

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.note?.title ?? '');

    contentController = TextEditingController(text: widget.note?.content ?? '');

    selectedCategory = widget.note?.category ?? 'Pribadi';
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void submitNote() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan isi catatan harus diisi.')),
      );
      return;
    }

    final now = DateTime.now();
    final old = widget.note;

    final note = Note(
      id: old?.id ?? '${now.microsecondsSinceEpoch}',
      title: title,
      content: content,
      category: selectedCategory,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              widget.note == null ? 'Catatan Baru' : 'Edit Catatan',
              style: const TextStyle(
                fontSize: 22,
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tuliskan cerita atau hal pentingmu.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            const Text(
              'Judul Catatan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: editorDecoration(
                'Contoh: Kegiatan Kuliah Hari Ini',
                Icons.title_rounded,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Kategori',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: editorDecoration(
                'Pilih kategori',
                Icons.folder_outlined,
              ),
              items: categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Isi Catatan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: contentController,
              maxLines: 6,
              minLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: editorDecoration(
                'Tuliskan ceritamu di sini...',
                Icons.edit_note_rounded,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: submitNote,
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  widget.note == null ? 'Simpan Catatan' : 'Simpan Perubahan',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration editorDecoration(String hint, IconData icon) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 12),
    prefixIcon: Icon(icon, color: AppColors.primary, size: 21),
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
    ),
  );
}

// =====================================================
// NOTE DETAIL SHEET
// =====================================================

class NoteDetailSheet extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteDetailSheet({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  note.category,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Text(
                note.title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Dibuat ${formatDate(note.createdAt)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Divider(height: 32),
              SelectableText(
                note.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.text,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

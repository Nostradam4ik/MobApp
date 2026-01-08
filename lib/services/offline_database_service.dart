import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/models/expense.dart';
import '../data/models/category.dart' as models;
import '../data/models/budget.dart';

/// Service de base de données locale SQLite pour le mode hors-ligne
class OfflineDatabaseService {
  OfflineDatabaseService._();

  static Database? _database;
  static const String _databaseName = 'smartspend_offline.db';
  static const int _databaseVersion = 1;

  /// Obtient l'instance de la base de données
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialise la base de données
  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crée les tables
  static Future<void> _onCreate(Database db, int version) async {
    // Table des catégories
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'category',
        color TEXT DEFAULT '#6366F1',
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced'
      )
    ''');

    // Table des dépenses
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT,
        amount REAL NOT NULL,
        note TEXT,
        expense_date TEXT NOT NULL,
        is_recurring INTEGER DEFAULT 0,
        recurring_frequency TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Table des budgets
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT,
        monthly_limit REAL NOT NULL,
        alert_threshold INTEGER DEFAULT 80,
        is_active INTEGER DEFAULT 1,
        period_start TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // Table de file d'attente de synchronisation
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Index pour les performances
    await db.execute('CREATE INDEX idx_expenses_user_id ON expenses(user_id)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(expense_date)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses(category_id)');
    await db.execute('CREATE INDEX idx_expenses_sync ON expenses(sync_status)');
    await db.execute('CREATE INDEX idx_categories_user ON categories(user_id)');
    await db.execute('CREATE INDEX idx_budgets_user ON budgets(user_id)');
  }

  /// Mise à jour de la base de données
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrations futures ici
  }

  // ============ Catégories ============

  /// Sauvegarde les catégories localement
  static Future<void> saveCategories(List<models.Category> categories) async {
    final db = await database;
    final batch = db.batch();

    for (final category in categories) {
      batch.insert(
        'categories',
        {
          'id': category.id,
          'user_id': category.userId,
          'name': category.name,
          'icon': category.icon,
          'color': category.color,
          'is_default': category.isDefault ? 1 : 0,
          'is_active': category.isActive ? 1 : 0,
          'sort_order': category.sortOrder,
          'created_at': category.createdAt.toIso8601String(),
          'updated_at': category.updatedAt.toIso8601String(),
          'sync_status': 'synced',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Récupère toutes les catégories locales
  static Future<List<models.Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'sort_order ASC');

    return maps.map((map) => models.Category(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? 'category',
      color: map['color'] as String? ?? '#6366F1',
      isDefault: (map['is_default'] as int) == 1,
      isActive: (map['is_active'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  /// Ajoute une catégorie (mode hors-ligne)
  static Future<void> insertCategory(models.Category category) async {
    final db = await database;

    await db.insert(
      'categories',
      {
        'id': category.id,
        'user_id': category.userId,
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'is_default': category.isDefault ? 1 : 0,
        'is_active': category.isActive ? 1 : 0,
        'sort_order': category.sortOrder,
        'created_at': category.createdAt.toIso8601String(),
        'updated_at': category.updatedAt.toIso8601String(),
        'sync_status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Ajouter à la file de synchronisation
    await _addToSyncQueue('categories', category.id, 'insert', category.toJson());
  }

  // ============ Dépenses ============

  /// Sauvegarde les dépenses localement
  static Future<void> saveExpenses(List<Expense> expenses) async {
    final db = await database;
    final batch = db.batch();

    for (final expense in expenses) {
      batch.insert(
        'expenses',
        {
          'id': expense.id,
          'user_id': expense.userId,
          'category_id': expense.categoryId,
          'amount': expense.amount,
          'note': expense.note,
          'expense_date': expense.expenseDate.toIso8601String().split('T')[0],
          'is_recurring': expense.isRecurring ? 1 : 0,
          'recurring_frequency': expense.recurringFrequency,
          'created_at': expense.createdAt.toIso8601String(),
          'updated_at': expense.updatedAt.toIso8601String(),
          'sync_status': 'synced',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Récupère toutes les dépenses locales
  static Future<List<Expense>> getExpenses() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT e.*, c.id as cat_id, c.user_id as cat_user_id, c.name as cat_name,
             c.icon as cat_icon, c.color as cat_color, c.is_default as cat_is_default,
             c.is_active as cat_is_active, c.sort_order as cat_sort_order,
             c.created_at as cat_created_at, c.updated_at as cat_updated_at
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      ORDER BY e.expense_date DESC, e.created_at DESC
    ''');

    return maps.map((map) {
      models.Category? category;
      if (map['cat_id'] != null) {
        category = models.Category(
          id: map['cat_id'] as String,
          userId: map['cat_user_id'] as String?,
          name: map['cat_name'] as String,
          icon: map['cat_icon'] as String? ?? 'category',
          color: map['cat_color'] as String? ?? '#6366F1',
          isDefault: (map['cat_is_default'] as int) == 1,
          isActive: (map['cat_is_active'] as int) == 1,
          sortOrder: map['cat_sort_order'] as int? ?? 0,
          createdAt: DateTime.parse(map['cat_created_at'] as String),
          updatedAt: DateTime.parse(map['cat_updated_at'] as String),
        );
      }

      return Expense(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        categoryId: map['category_id'] as String?,
        amount: (map['amount'] as num).toDouble(),
        note: map['note'] as String?,
        expenseDate: DateTime.parse(map['expense_date'] as String),
        isRecurring: (map['is_recurring'] as int) == 1,
        recurringFrequency: map['recurring_frequency'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        category: category,
      );
    }).toList();
  }

  /// Récupère les dépenses d'un mois
  static Future<List<Expense>> getExpensesByMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final maps = await db.rawQuery('''
      SELECT e.*, c.id as cat_id, c.user_id as cat_user_id, c.name as cat_name,
             c.icon as cat_icon, c.color as cat_color, c.is_default as cat_is_default,
             c.is_active as cat_is_active, c.sort_order as cat_sort_order,
             c.created_at as cat_created_at, c.updated_at as cat_updated_at
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      WHERE e.expense_date >= ? AND e.expense_date <= ?
      ORDER BY e.expense_date DESC, e.created_at DESC
    ''', [
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0],
    ]);

    return maps.map((map) {
      models.Category? category;
      if (map['cat_id'] != null) {
        category = models.Category(
          id: map['cat_id'] as String,
          userId: map['cat_user_id'] as String?,
          name: map['cat_name'] as String,
          icon: map['cat_icon'] as String? ?? 'category',
          color: map['cat_color'] as String? ?? '#6366F1',
          isDefault: (map['cat_is_default'] as int) == 1,
          isActive: (map['cat_is_active'] as int) == 1,
          sortOrder: map['cat_sort_order'] as int? ?? 0,
          createdAt: DateTime.parse(map['cat_created_at'] as String),
          updatedAt: DateTime.parse(map['cat_updated_at'] as String),
        );
      }

      return Expense(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        categoryId: map['category_id'] as String?,
        amount: (map['amount'] as num).toDouble(),
        note: map['note'] as String?,
        expenseDate: DateTime.parse(map['expense_date'] as String),
        isRecurring: (map['is_recurring'] as int) == 1,
        recurringFrequency: map['recurring_frequency'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        category: category,
      );
    }).toList();
  }

  /// Ajoute une dépense (mode hors-ligne)
  static Future<void> insertExpense(Expense expense) async {
    final db = await database;

    await db.insert(
      'expenses',
      {
        'id': expense.id,
        'user_id': expense.userId,
        'category_id': expense.categoryId,
        'amount': expense.amount,
        'note': expense.note,
        'expense_date': expense.expenseDate.toIso8601String().split('T')[0],
        'is_recurring': expense.isRecurring ? 1 : 0,
        'recurring_frequency': expense.recurringFrequency,
        'created_at': expense.createdAt.toIso8601String(),
        'updated_at': expense.updatedAt.toIso8601String(),
        'sync_status': 'pending',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Ajouter à la file de synchronisation
    await _addToSyncQueue('expenses', expense.id, 'insert', expense.toJson());
  }

  /// Met à jour une dépense (mode hors-ligne)
  static Future<void> updateExpense(Expense expense) async {
    final db = await database;

    await db.update(
      'expenses',
      {
        'category_id': expense.categoryId,
        'amount': expense.amount,
        'note': expense.note,
        'expense_date': expense.expenseDate.toIso8601String().split('T')[0],
        'is_recurring': expense.isRecurring ? 1 : 0,
        'recurring_frequency': expense.recurringFrequency,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      },
      where: 'id = ?',
      whereArgs: [expense.id],
    );

    await _addToSyncQueue('expenses', expense.id, 'update', expense.toJson());
  }

  /// Supprime une dépense (mode hors-ligne)
  static Future<void> deleteExpense(String id) async {
    final db = await database;

    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await _addToSyncQueue('expenses', id, 'delete', null);
  }

  // ============ Budgets ============

  /// Sauvegarde les budgets localement
  static Future<void> saveBudgets(List<Budget> budgets) async {
    final db = await database;
    final batch = db.batch();

    for (final budget in budgets) {
      batch.insert(
        'budgets',
        {
          'id': budget.id,
          'user_id': budget.userId,
          'category_id': budget.categoryId,
          'monthly_limit': budget.monthlyLimit,
          'alert_threshold': budget.alertThreshold,
          'is_active': budget.isActive ? 1 : 0,
          'period_start': budget.periodStart.toIso8601String().split('T')[0],
          'created_at': budget.createdAt.toIso8601String(),
          'updated_at': budget.updatedAt.toIso8601String(),
          'sync_status': 'synced',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Récupère les budgets locaux
  static Future<List<Budget>> getBudgets() async {
    final db = await database;
    final maps = await db.query('budgets');

    return maps.map((map) => Budget(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String?,
      monthlyLimit: (map['monthly_limit'] as num).toDouble(),
      alertThreshold: map['alert_threshold'] as int? ?? 80,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      periodStart: DateTime.parse(map['period_start'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  // ============ File de synchronisation ============

  /// Ajoute une opération à la file de synchronisation
  static Future<void> _addToSyncQueue(
    String tableName,
    String recordId,
    String action,
    Map<String, dynamic>? data,
  ) async {
    final db = await database;

    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'data': data != null ? data.toString() : null,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  /// Récupère les opérations en attente de synchronisation
  static Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
    );
  }

  /// Supprime une opération de la file
  static Future<void> removeSyncOperation(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Incrémente le compteur de tentatives
  static Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  /// Compte les opérations en attente
  static Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
    return result.first['count'] as int;
  }

  // ============ Utilitaires ============

  /// Vide toutes les données locales
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('categories');
    await db.delete('budgets');
    await db.delete('sync_queue');
  }

  /// Vide la base de données et la supprime
  static Future<void> deleteDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
  }

  /// Vérifie si des données existent localement
  static Future<bool> hasLocalData() async {
    final db = await database;
    final expenses = await db.rawQuery('SELECT COUNT(*) as count FROM expenses');
    return (expenses.first['count'] as int) > 0;
  }
}

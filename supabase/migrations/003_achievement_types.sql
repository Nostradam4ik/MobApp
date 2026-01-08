-- =====================================================
-- Achievement Types Definition
-- These define all possible achievements
-- =====================================================

-- Create achievement_types table for reference
CREATE TABLE IF NOT EXISTS achievement_types (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT NOT NULL,
    points INTEGER DEFAULT 0,
    requirement_value INTEGER,
    category TEXT NOT NULL
);

INSERT INTO achievement_types (id, title, description, icon, points, requirement_value, category) VALUES
    -- Streak achievements
    ('streak_3', '3 jours de suite', 'Suivez vos dépenses 3 jours consécutifs', 'local_fire_department', 10, 3, 'streak'),
    ('streak_7', 'Une semaine parfaite', 'Suivez vos dépenses 7 jours consécutifs', 'whatshot', 25, 7, 'streak'),
    ('streak_30', 'Mois complet', 'Suivez vos dépenses 30 jours consécutifs', 'military_tech', 100, 30, 'streak'),
    ('streak_100', 'Centurion', 'Suivez vos dépenses 100 jours consécutifs', 'emoji_events', 500, 100, 'streak'),

    -- Budget achievements
    ('budget_first', 'Premier budget', 'Créez votre premier budget', 'account_balance_wallet', 10, 1, 'budget'),
    ('budget_respected', 'Budget respecté', 'Respectez un budget mensuel complet', 'verified', 50, 1, 'budget'),
    ('budget_master', 'Maître du budget', 'Respectez vos budgets 3 mois de suite', 'workspace_premium', 150, 3, 'budget'),

    -- Savings achievements
    ('goal_first', 'Premier objectif', 'Créez votre premier objectif d\'épargne', 'flag', 10, 1, 'savings'),
    ('goal_50', 'À mi-chemin', 'Atteignez 50% d\'un objectif', 'trending_up', 25, 50, 'savings'),
    ('goal_complete', 'Objectif atteint', 'Complétez un objectif d\'épargne', 'celebration', 100, 100, 'savings'),
    ('goal_master', 'Épargnant pro', 'Complétez 5 objectifs d\'épargne', 'star', 300, 5, 'savings'),

    -- Tracking achievements
    ('expense_first', 'Première dépense', 'Enregistrez votre première dépense', 'edit_note', 5, 1, 'tracking'),
    ('expense_10', 'Débutant', 'Enregistrez 10 dépenses', 'looks_one', 15, 10, 'tracking'),
    ('expense_50', 'Habitué', 'Enregistrez 50 dépenses', 'looks_two', 30, 50, 'tracking'),
    ('expense_100', 'Expert', 'Enregistrez 100 dépenses', 'looks_3', 50, 100, 'tracking'),
    ('expense_500', 'Vétéran', 'Enregistrez 500 dépenses', 'looks_4', 100, 500, 'tracking'),

    -- Special achievements
    ('early_adopter', 'Early Adopter', 'Parmi les premiers utilisateurs', 'rocket_launch', 50, NULL, 'special'),
    ('feedback', 'Contributeur', 'Donnez votre avis sur l\'app', 'rate_review', 25, NULL, 'special'),
    ('premium', 'Supporter', 'Passez à Premium', 'diamond', 100, NULL, 'special');

-- Make achievement_types readable by all authenticated users
ALTER TABLE achievement_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view achievement types" ON achievement_types FOR SELECT USING (true);

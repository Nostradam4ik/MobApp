-- =====================================================
-- Default Categories
-- These are created for all users
-- =====================================================

-- Insert default categories (will be copied for each user via trigger)
INSERT INTO categories (id, user_id, name, icon, color, is_default, sort_order) VALUES
    ('00000000-0000-0000-0000-000000000001', NULL, 'Alimentation', 'restaurant', '#EF4444', TRUE, 1),
    ('00000000-0000-0000-0000-000000000002', NULL, 'Transport', 'directions_car', '#F59E0B', TRUE, 2),
    ('00000000-0000-0000-0000-000000000003', NULL, 'Logement', 'home', '#10B981', TRUE, 3),
    ('00000000-0000-0000-0000-000000000004', NULL, 'Loisirs', 'sports_esports', '#8B5CF6', TRUE, 4),
    ('00000000-0000-0000-0000-000000000005', NULL, 'Shopping', 'shopping_bag', '#EC4899', TRUE, 5),
    ('00000000-0000-0000-0000-000000000006', NULL, 'Santé', 'medical_services', '#06B6D4', TRUE, 6),
    ('00000000-0000-0000-0000-000000000007', NULL, 'Factures', 'receipt_long', '#6366F1', TRUE, 7),
    ('00000000-0000-0000-0000-000000000008', NULL, 'Café', 'coffee', '#92400E', TRUE, 8),
    ('00000000-0000-0000-0000-000000000009', NULL, 'Abonnements', 'subscriptions', '#7C3AED', TRUE, 9),
    ('00000000-0000-0000-0000-000000000010', NULL, 'Autre', 'more_horiz', '#6B7280', TRUE, 10);

-- Update RLS policy for default categories
DROP POLICY IF EXISTS "Users can view own categories" ON categories;
CREATE POLICY "Users can view own categories" ON categories
    FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);

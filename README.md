# SmartSpend

Application mobile de suivi des dépenses personnelles, conçue pour être simple, intelligente et motivante.

## Fonctionnalités

### V1 - MVP
- **Authentification** : Inscription/connexion via Supabase Auth
- **Gestion des dépenses** : Ajout rapide en moins de 10 secondes
- **Catégories personnalisables** : Icônes et couleurs
- **Budgets** : Global et par catégorie avec alertes
- **Statistiques** : Graphiques clairs (jour/semaine/mois)

### Fonctionnalités Innovantes
- **Assistant intelligent** : Conseils personnalisés basés sur vos habitudes
- **Objectifs financiers** : Suivi visuel de progression
- **Mode revenu variable** : Budget journalier adaptatif
- **Gamification** : Streaks, badges, challenges

## Technologies

- **Flutter** : Android & iOS avec un seul codebase
- **Supabase** : Auth, PostgreSQL, Storage
- **Provider** : State management
- **SQLite** : Cache local

## Installation

```bash
# Cloner le projet
git clone <repo-url>
cd smartspend

# Installer les dépendances
flutter pub get

# Configurer l'environnement
cp .env.example .env
# Éditer .env avec vos clés Supabase

# Lancer l'application
flutter run
```

## Configuration Supabase

1. Créer un projet sur [supabase.com](https://supabase.com)
2. Exécuter les migrations SQL dans `supabase/migrations/`
3. Copier l'URL et la clé anonyme dans `.env`

## Structure du Projet

```
lib/
├── core/           # Configuration, thème, constantes
├── data/           # Modèles et sources de données
├── services/       # Services (API, notifications, etc.)
├── providers/      # State management
├── screens/        # Écrans de l'application
├── widgets/        # Composants réutilisables
└── main.dart       # Point d'entrée
```

## Monétisation

- **Gratuit** : Suivi basique, budgets, statistiques
- **Premium** (3-5€/mois) : Assistant IA, objectifs illimités, exports

## Auteur

**Andrii Zhmuryk**
- LinkedIn: [https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/](https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/)

## Licence

MIT License

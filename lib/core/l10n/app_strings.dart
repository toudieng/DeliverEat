/// Lightweight hand-rolled localization (FR/EN) — no codegen, so the app
/// keeps compiling with a plain `flutter run` and no extra tooling step.
class AppStrings {
  AppStrings(this.languageCode);

  final String languageCode;

  bool get isFrench => languageCode == 'fr';

  static const Map<String, Map<String, String>> _values = {
    'appName': {'fr': 'DeliverEat', 'en': 'DeliverEat'},
    'login': {'fr': 'Connexion', 'en': 'Login'},
    'register': {'fr': "S'inscrire", 'en': 'Sign up'},
    'email': {'fr': 'E-mail', 'en': 'Email'},
    'password': {'fr': 'Mot de passe', 'en': 'Password'},
    'name': {'fr': 'Nom', 'en': 'Name'},
    'noAccount': {'fr': "Pas encore de compte ? ", 'en': "No account yet? "},
    'haveAccount': {'fr': 'Déjà un compte ? ', 'en': 'Already have an account? '},
    'welcomeBack': {'fr': 'Content de vous revoir 👋', 'en': 'Welcome back 👋'},
    'createAccount': {'fr': 'Créer un compte', 'en': 'Create an account'},
    'home': {'fr': 'Accueil', 'en': 'Home'},
    'favorites': {'fr': 'Favoris', 'en': 'Favorites'},
    'orders': {'fr': 'Commandes', 'en': 'Orders'},
    'profile': {'fr': 'Profil', 'en': 'Profile'},
    'search': {'fr': 'Rechercher un restaurant, un plat…', 'en': 'Search a restaurant, a dish…'},
    'noResults': {'fr': 'Aucun résultat', 'en': 'No results'},
    'retry': {'fr': 'Réessayer', 'en': 'Retry'},
    'offline': {
      'fr': 'Vous êtes hors connexion — affichage des données en cache',
      'en': 'You are offline — showing cached data',
    },
    'cart': {'fr': 'Panier', 'en': 'Cart'},
    'checkout': {'fr': 'Commander', 'en': 'Checkout'},
    'subtotal': {'fr': 'Sous-total', 'en': 'Subtotal'},
    'deliveryFee': {'fr': 'Frais de livraison', 'en': 'Delivery fee'},
    'total': {'fr': 'Total', 'en': 'Total'},
    'deliveryAddress': {'fr': 'Adresse de livraison', 'en': 'Delivery address'},
    'notes': {'fr': 'Remarques (facultatif)', 'en': 'Notes (optional)'},
    'placeOrder': {'fr': 'Valider la commande', 'en': 'Place order'},
    'darkMode': {'fr': 'Mode sombre', 'en': 'Dark mode'},
    'language': {'fr': 'Langue', 'en': 'Language'},
    'logout': {'fr': 'Se déconnecter', 'en': 'Log out'},
  };

  String t(String key) => _values[key]?[languageCode] ?? key;
}

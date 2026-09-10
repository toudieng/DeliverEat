# DeliverEat 🛵

Application mobile Flutter de livraison de repas pour Dakar — projet réalisé pour
l'examen final M1 (2025-2026). L'API REST fournie est l'unique source de données ;
aucune donnée métier n'est codée en dur.

## Lancer le projet

```bash
flutter pub get
flutter run
```

L'adresse de l'API est déclarée à un seul endroit : `lib/core/config/api_config.dart`
(`ApiConfig.baseUrl`). Si le serveur redémarre avec une nouvelle adresse, il suffit de
changer cette ligne.

## Architecture

Le code est organisé en couches nettement séparées, comme demandé par l'énoncé :

```
lib/
├── core/            # config, client HTTP (dio) + intercepteurs, stockage,
│                     # thème, connectivité, petites utilitaires (validators,
│                     # debouncer, formatters), localisation FR/EN
├── models/           # classes typées avec fromJson (User, Restaurant, MenuItem,
│                     # Review, Order, CartItem, PaginatedResponse…) — aucun
│                     # Map<String, dynamic> manipulé directement dans les widgets
├── services/         # appels API purs par domaine (AuthService, CatalogService,
│                     # ReviewService, OrderService, FavoriteService,
│                     # ProfileService, OrderSocketService pour le WebSocket)
├── providers/        # état applicatif avec Provider/ChangeNotifier (pas de
│                     # setState dispersé) : AuthProvider, CartProvider,
│                     # RestaurantListProvider, FavoritesProvider, OrderProvider,
│                     # OrderTrackingProvider, ThemeProvider, LocaleProvider,
│                     # ConnectivityProvider
├── screens/          # un dossier par écran/flux (auth, home, restaurant, cart,
│                     # checkout, order, favorites, profile, root shell)
└── widgets/          # composants réutilisables (cartes restaurant, chips,
                       # timeline de statut animée, skeletons, états vide/erreur…)
```

### Authentification & session (Partie 1)

- Validation client (email, mot de passe 6 caractères) avant tout appel réseau.
- Jetons stockés dans `flutter_secure_storage`.
- `ApiClient` (dio) intercepte chaque requête pour injecter le `Bearer` token, et
  chaque réponse `401 TOKEN_EXPIRED` déclenche un rafraîchissement automatique
  (`/api/auth/refresh`), la sauvegarde de la nouvelle paire rotative, puis rejoue
  la requête d'origine — invisible pour l'utilisateur. Un `Completer` garantit
  qu'un seul rafraîchissement est en vol même si plusieurs requêtes échouent en
  même temps.
- La déconnexion appelle `/api/auth/logout` puis vide le stockage local quoi
  qu'il arrive.

### Accueil & catalogue (Partie 2)

- Pagination par défilement infini (`page` / `meta.hasNextPage`), une page à la
  fois.
- Recherche avec `Debouncer` (~400 ms), filtre par catégorie, sélecteur de tri.
- États chargement / vide / erreur avec bouton *Réessayer* gérés par
  `RestaurantListProvider`.

### Fiche restaurant & panier (Partie 3)

- Menu groupé par section, avis paginés + formulaire d'ajout gérant le `409
  ALREADY_REVIEWED` sans crash.
- `CartProvider` centralise tout l'état du panier (ajout/retrait/quantités,
  sous-total, frais, total en CFA). La règle « un seul restaurant par
  commande » est appliquée : ajouter un article d'un autre restaurant ouvre une
  boîte de dialogue (vider le panier / annuler).
- Favoris synchronisés avec l'API, mise à jour optimiste avec rollback en cas
  d'échec.
- Animation `Hero` entre la carte restaurant et sa fiche détail.

### Commande & suivi temps réel (Partie 4)

- Écran de validation avec adresse validée, remarques facultatives, gestion de
  `422 RESTAURANT_CLOSED`.
- `OrderSocketService` se connecte à `wss://…/ws?token=…`, anime la frise de
  statuts à chaque `order_update`, affiche les horodatages de `statusHistory`,
  et déclenche une petite célébration (confettis) à l'arrivée du statut
  `delivered`.
- Robustesse : `OrderTrackingProvider` bascule automatiquement sur un polling de
  `GET /api/orders/:id` (toutes les 8 s) dès que le WebSocket se déconnecte, et
  revient au WebSocket dès qu'il se reconnecte avec un jeton d'accès frais
  (celui de l'URL expire comme les autres).
- Historique filtrable par statut ; le bouton *Annuler* n'apparaît que pour les
  commandes `pending` et gère le `422 CANNOT_CANCEL`.

### Profil & robustesse (Partie 5)

- Édition nom/téléphone, avatar via galerie ou appareil photo, envoi multipart,
  contrôle de taille côté client (2 Mo) en plus de la gestion de
  `FILE_TOO_LARGE` renvoyée par l'API.
- `ApiException` centralise tous les codes documentés (400, 401, 404, 409, 422,
  429) avec un message compréhensible par code (`friendlyMessage`).
- `ConnectivityProvider` détecte la perte de réseau (bannière globale) ;
  `RestaurantListProvider` retombe sur le dernier catalogue mis en cache
  (`shared_preferences`) pour garder l'accueil consultable hors connexion.

### Bonus

- **Mode sombre** persistant (`ThemeProvider` + `shared_preferences`).
- **Localisation FR/EN** complète sur tous les écrans, via un petit système de
  traduction sans génération de code (`AppStrings`), pour garantir un
  `flutter run` toujours sans étape supplémentaire.
- **Animations Hero** entre la liste de restaurants et la fiche détail, plus des
  micro-interactions (`flutter_animate`) partout : apparition en fondu/
  glissement en cascade sur les listes, cœur animé, frise de statut qui pulse
  sur l'étape en cours, bannière de bienvenue dégradée avec message selon
  l'heure, rebond du panier flottant à chaque ajout, célébration animée à la
  livraison.

## Packages utilisés

| Package | Rôle |
|---|---|
| `dio` | Client HTTP + intercepteurs (auth, refresh, erreurs, logs debug) |
| `flutter_secure_storage` | Stockage sécurisé des jetons |
| `provider` | Gestion d'état |
| `web_socket_channel` | Suivi de commande en temps réel |
| `cached_network_image` | Images réseau avec cache et placeholders |
| `shared_preferences` | Préférences (thème, langue) + cache hors-ligne |
| `connectivity_plus` | Détection de la perte de réseau |
| `image_picker` | Photo de profil (galerie / appareil photo) |
| `flutter_animate` | Animations déclaratives |
| `shimmer` | Effets de chargement squelette |
| `intl` | Formatage des montants CFA |
| `flutter_localizations` | Délégués de localisation Material/Widgets/Cupertino |

## Difficultés rencontrées

- **Forme des réponses `/auth/me` et `/auth/me/avatar`.** La documentation
  laissait penser que ces deux endpoints renvoyaient l'utilisateur « à plat »,
  alors qu'ils l'enveloppent en réalité dans `{ "user": { ... } } }`, comme
  `login`/`register`. Résultat : l'édition du profil et l'upload d'avatar
  semblaient « ne rien faire » côté app, sans la moindre erreur visible,
  puisque `AppUser.fromJson` recevait l'enveloppe au lieu de l'objet utilisateur
  et retombait silencieusement sur des champs vides. Diagnostiqué en ajoutant un
  `LogInterceptor` Dio (actif uniquement en debug) pour voir le JSON brut, puis
  corrigé avec un petit `unwrapUser()` partagé qui gère les deux formes.
- **Avatar qui ne se rafraîchissait pas visuellement.** Même une fois le
  parsing corrigé, la nouvelle photo n'apparaissait pas : le serveur réutilise
  la même URL de fichier, et `Image`/`CircleAvatar` ne redemande une image que
  si son `ImageProvider` change réellement (par égalité). Un `ImageProvider`
  identique = pas de nouvelle requête, même avec le cache vidé. Résolu en
  ajoutant un paramètre `?v=<timestamp>` local après chaque upload réussi, pour
  forcer un `ImageProvider` réellement différent.
- **Crash à l'ouverture d'une fiche restaurant** (`'_elements.contains(element)'`
  puis `RenderViewport expected RenderSliver…`). Cause réelle : un
  `.animate()` de `flutter_animate` était chaîné sur un `SliverToBoxAdapter`
  lui-même plutôt que sur son contenu, ce qui le transformait en widget
  « boîte » alors que la liste défilante attendait un vrai sliver à cet
  emplacement. Le message d'erreur affiché en premier (une assertion de
  `GlobalKey`) était une conséquence en cascade, pas la cause — la vraie piste
  se trouvait dans le tout premier bloc d'exception affiché par Flutter.
- **Environnement Windows** : plusieurs blocages avant même de pouvoir
  compiler — connexion IPv6 cassée faisant échouer le téléchargement du SDK
  Android (corrigé avec `-Djava.net.preferIPv4Stack=true` en variable
  `JAVA_TOOL_OPTIONS`), puis un chemin d'installation contenant un espace
  (`C:\Users\<nom avec espace>\...`) qui casse l'outillage Dart/Android sur
  Windows — réglé en réinstallant le SDK Flutter et le SDK Android sous des
  chemins sans espace (`C:\flutter`, `C:\Android\sdk`).
- **Compte de démonstration partagé.** `demo@delivereat.app` étant utilisé par
  tous les candidats, il accumule des commandes et des avis d'autres sessions
  de test — ce qui est normal (l'app affiche fidèlement les données du compte
  connecté) mais peut surprendre. Un compte personnel via l'inscription donne
  un historique propre.

Le projet a été développé et débogué en échange continu avec l'API réelle une
fois ces blocages d'environnement levés, ce qui a permis de corriger les
hypothèses de départ sur la forme exacte de certaines réponses.

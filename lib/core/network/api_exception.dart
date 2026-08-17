/// Uniform representation of the API's `{ "error": { "code", "message" } }`
/// envelope, plus the HTTP status that came with it.
class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;

  const ApiException({required this.statusCode, required this.code, required this.message});

  factory ApiException.fromResponse(int? statusCode, dynamic data) {
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      return ApiException(
        statusCode: statusCode,
        code: (error['code'] ?? 'UNKNOWN').toString(),
        message: (error['message'] ?? _fallbackMessage(statusCode)).toString(),
      );
    }
    return ApiException(
      statusCode: statusCode,
      code: 'UNKNOWN',
      message: _fallbackMessage(statusCode),
    );
  }

  factory ApiException.network() => const ApiException(
        statusCode: null,
        code: 'NETWORK_ERROR',
        message: "Impossible de contacter le serveur. Vérifiez votre connexion.",
      );

  static String _fallbackMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return "Requête invalide.";
      case 401:
        return "Session expirée, veuillez vous reconnecter.";
      case 404:
        return "Ressource introuvable.";
      case 409:
        return "Conflit avec une donnée existante.";
      case 422:
        return "Cette action n'est pas autorisée pour le moment.";
      case 429:
        return "Trop de requêtes, réessayez dans un instant.";
      default:
        return "Une erreur inattendue est survenue.";
    }
  }

  /// Human-readable message tuned per documented error code, falling back
  /// to whatever the API sent.
  String get friendlyMessage {
    switch (code) {
      case 'EMAIL_TAKEN':
        return "Cette adresse e-mail est déjà utilisée.";
      case 'INVALID_CREDENTIALS':
        return "Identifiants incorrects.";
      case 'TOKEN_EXPIRED':
        return "Votre session a expiré, reconnexion...";
      case 'ALREADY_REVIEWED':
        return "Vous avez déjà laissé un avis pour ce restaurant.";
      case 'RESTAURANT_CLOSED':
        return "Ce restaurant est actuellement fermé.";
      case 'MIXED_RESTAURANTS':
        return "Votre panier contient déjà des articles d'un autre restaurant.";
      case 'CANNOT_CANCEL':
        return "Cette commande ne peut plus être annulée.";
      case 'FILE_TOO_LARGE':
        return "Le fichier dépasse la taille maximale autorisée (2 Mo).";
      case 'RATE_LIMITED':
        return "Trop de requêtes, réessayez dans un instant.";
      case 'VALIDATION_ERROR':
        return message.isNotEmpty ? message : "Certains champs sont invalides.";
      case 'NETWORK_ERROR':
        return message;
      default:
        return message;
    }
  }

  bool get isTokenExpired => statusCode == 401 && code == 'TOKEN_EXPIRED';

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}

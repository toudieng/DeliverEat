class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[a-zA-Z]{2,}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return "L'adresse e-mail est requise.";
    if (!_emailRegex.hasMatch(value.trim())) return "Adresse e-mail invalide.";
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return "Le mot de passe est requis.";
    if (value.length < 6) return "6 caractères minimum.";
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return "Le nom est requis.";
    if (value.trim().length < 2) return "Nom trop court.";
    return null;
  }

  static String? notEmpty(String? value, {String message = "Ce champ est requis."}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) return "L'adresse de livraison est requise.";
    if (value.trim().length < 6) return "Adresse trop courte, précisez le quartier.";
    return null;
  }
}

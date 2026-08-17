class Review {
  final String id;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: (json['id'] ?? '').toString(),
        userId: (json['userId'] ?? json['user']?['id'] ?? '').toString(),
        userName: (json['userName'] ?? json['user']?['name'] ?? 'Utilisateur').toString(),
        rating: (json['rating'] is num) ? (json['rating'] as num).round() : 0,
        comment: (json['comment'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      );
}

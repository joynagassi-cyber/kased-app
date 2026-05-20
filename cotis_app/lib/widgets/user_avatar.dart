import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kased_app/core/avatar_service.dart';

class UserAvatar extends StatelessWidget {
  final String email;
  final double radius;

  const UserAvatar({
    super.key,
    required this.email,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (email.trim().isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: Icon(
          Icons.person,
          color: Colors.grey.shade600,
          size: radius * 1.2,
        ),
      );
    }

    final url = AvatarService.generateFromEmail(email);
    final initials = AvatarService.initialsFromEmail(email);
    final bgColor = AvatarService.colorFromEmail(email);

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: Colors.transparent,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor.withValues(alpha: 0.15),
        child: SizedBox(
          width: radius * 0.8,
          height: radius * 0.8,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: bgColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

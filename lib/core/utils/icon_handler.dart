import 'package:flutter/material.dart';

class IconHandler {
  static IconData getIcon(String name) {
    switch (name) {
      case 'account_circle': return Icons.account_circle_rounded;
      case 'rocket_launch': return Icons.rocket_launch_rounded;
      case 'auto_awesome': return Icons.auto_awesome_rounded;
      case 'psychology': return Icons.psychology_rounded;
      case 'shutter_speed': return Icons.shutter_speed_rounded;
      case 'wallpaper': return Icons.wallpaper_rounded;
      case 'temp_sky': return Icons.wb_twilight_rounded;
      case 'nightlife': return Icons.nightlife_rounded;
      case 'forest': return Icons.forest_rounded;
      case 'wb_sunny': return Icons.wb_sunny_rounded;
      case 'light_mode': return Icons.light_mode_rounded;
      case 'bolt': return Icons.bolt_rounded;
      case 'stars': return Icons.stars_rounded;
      case 'filter_vintage': return Icons.filter_vintage_rounded;
      case 'terminal': return Icons.terminal_rounded;
      case 'bubble_chart': return Icons.bubble_chart_rounded;
      case 'confirmation_num': return Icons.confirmation_num_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'person': return Icons.person_rounded;
      case 'computer': return Icons.smart_toy_rounded;
      case 'smart_toy': return Icons.smart_toy_rounded;
      case 'robot': return Icons.smart_toy_rounded;
      case 'medal': return Icons.military_tech_rounded;
      case 'emoji_events_rounded': return Icons.emoji_events_rounded;
      case 'diamond': return Icons.stars_rounded;
      case 'gems': return Icons.stars_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  static Widget buildItemIcon(String image, {double size = 32, Color? color}) {
    if (image.isEmpty) return Icon(Icons.help_outline_rounded, size: size, color: color);
    
    // Normalize mascot.png/maskot.png to kinz.png
    if (image.toLowerCase().contains('mascot') || image.toLowerCase().contains('maskot')) {
      image = 'kinz.png';
    }

    if (image == 'diamond' || image == 'gems') {
      return Image.asset(
        'assets/images/diamond.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    
    if (image.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          image,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.account_circle_rounded, size: size, color: color),
        ),
      );
    }

    if (image.endsWith('.png')) {
      return Image.asset(
        image.contains('/') ? image : 'assets/images/char/$image',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.account_circle_rounded, size: size, color: color),
      );
    }
    
    // Check if it's an emoji (still fallback)
    if (image.length <= 2) {
      return Text(image, style: TextStyle(fontSize: size * 0.8));
    }
    
    return Icon(getIcon(image), size: size, color: color);
  }
}

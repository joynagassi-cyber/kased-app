import 'dart:math';

class UuidUtils {
  static String generate() {
    final random = Random.secure();
    
    final r1 = random.nextInt(0xffffffff);
    final r2 = random.nextInt(0xffffffff);
    final r3 = random.nextInt(0xffffffff);
    final r4 = random.nextInt(0xffffffff);
    
    final s1 = r1.toRadixString(16).padLeft(8, '0');
    final s2 = (r2 & 0xffff).toRadixString(16).padLeft(4, '0');
    final s3 = (((r2 >> 16) & 0x0fff) | 0x4000).toRadixString(16).padLeft(4, '0');
    final s4 = (((r3 & 0x3fff) | 0x8000)).toRadixString(16).padLeft(4, '0');
    final s5 = (((r3 >> 16) & 0xffff).toRadixString(16).padLeft(4, '0')) + 
               (r4 & 0xffffffff).toRadixString(16).padLeft(8, '0');
               
    return '$s1-$s2-$s3-$s4-$s5';
  }
}

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class WatermarkUtil {
  static Future<File> addPackingWatermark({
    required File imageFile,
    required String orderId,
    required String adminName,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) return imageFile;

    final now = DateTime.now();
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final formattedTime = '${now.day.toString().padLeft(2, '0')}-${monthNames[now.month - 1]}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final watermarkLines = [
      formattedTime,
      'Order: $orderId',
      'Packer: $adminName',
    ];

    final font = decodedImage.width > 1000 ? img.arial48 : img.arial24;
    final padding = 15;
    final lineSpacing = 8;
    
    final totalHeight = (font.size + lineSpacing) * watermarkLines.length;

    // Bottom-Left alignment
    final startX = padding;
    final startY = decodedImage.height - totalHeight - padding;

    img.fillRect(
      decodedImage,
      x1: 0,
      y1: startY - padding,
      x2: decodedImage.width,
      y2: decodedImage.height,
      color: img.ColorRgba8(0, 0, 0, 100), // Slightly transparent black covering bottom
    );

    // Draw each line
    int currentY = startY;
    for (var line in watermarkLines) {
      // Draw shadow
      img.drawString(
        decodedImage,
        line,
        font: font,
        x: startX + 2,
        y: currentY + 2,
        color: img.ColorRgb8(0, 0, 0),
      );
      // Draw text
      img.drawString(
        decodedImage,
        line,
        font: font,
        x: startX,
        y: currentY,
        color: img.ColorRgb8(230, 230, 230), // Off-White
      );
      currentY += font.size + lineSpacing;
    }

    final encoded = img.encodeJpg(decodedImage, quality: 85);

    // Save to app's documents directory (persistent, won't be cleared by OS)
    final appDir = await getApplicationDocumentsDirectory();
    final packingDir = Directory('${appDir.path}/packing_photos');
    if (!await packingDir.exists()) {
      await packingDir.create(recursive: true);
    }
    
    final fileName = 'packing_${now.millisecondsSinceEpoch}.jpg';
    final savedFile = File('${packingDir.path}/$fileName');
    await savedFile.writeAsBytes(encoded);

    print('[WatermarkUtil] Saved watermarked file to: ${savedFile.path} (${await savedFile.length()} bytes)');
    
    return savedFile;
  }
}

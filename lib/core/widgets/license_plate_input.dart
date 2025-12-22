import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Text formatter that converts input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// License plate type enumeration
enum PlateType {
  // Regular Series (Tunisian)
  tunis('تونس', 'TN', 'Standard', PlateCategory.regular),
  rs('ن ت', 'RS', 'Régime Suspensif', PlateCategory.regular),

  // Government Series (red on white)
  government('-', 'GOV', 'Gouvernement', PlateCategory.government),

  // Libya
  libya('ليبيا', 'LY', 'Libye', PlateCategory.libya),

  // Algeria
  algeria('الجزائر', 'DZ', 'Algérie', PlateCategory.algeria),

  // European Union
  eu('EU', 'EU', 'Union Européenne', PlateCategory.eu),

  // Other (generic for any country)
  other('Autre', 'OTHER', 'Autre', PlateCategory.other),

  // Diplomatic Series
  cmd('ر ب د', 'CMD', 'Chef Mission Diplo.', PlateCategory.diplomatic),
  cd('س د', 'CD', 'Corps Diplomatique', PlateCategory.diplomatic),
  md('ب د', 'MD', 'Mission Diplo.', PlateCategory.diplomatic),
  pat('م ا ف', 'PAT', 'Personnel Admin.', PlateCategory.diplomatic),

  // Consular Series
  cc('س ق', 'CC', 'Corps Consulaire', PlateCategory.consular),
  mc('ث ق', 'MC', 'Mission Consulaire', PlateCategory.consular);

  final String arabicLabel;
  final String latinLabel;
  final String description;
  final PlateCategory category;

  const PlateType(
    this.arabicLabel,
    this.latinLabel,
    this.description,
    this.category,
  );

  /// Get display label (Arabic for regular/libya, Latin for diplomatic/EU)
  String get displayLabel {
    if (category == PlateCategory.diplomatic ||
        category == PlateCategory.consular ||
        category == PlateCategory.eu) {
      return latinLabel;
    }
    return arabicLabel;
  }

  /// Check if plate uses Arabic label in the center
  bool get usesArabicCenter => category == PlateCategory.regular;

  /// Check if label is positioned on the right (single number + label)
  bool get hasRightLabel => this == PlateType.rs;

  /// Check if this uses the standard center layout (number - label - number)
  bool get hasCenterLabel => !hasRightLabel && !isEu && !isLibya && !isAlgeria && !isOther;

  /// Check if this is a government plate (red on white, dash separator)
  bool get isGovernment => this == PlateType.government;

  /// Check if this is an EU plate
  bool get isEu => category == PlateCategory.eu;

  /// Check if this is a Libyan plate
  bool get isLibya => category == PlateCategory.libya;

  /// Check if this is an Algerian plate
  bool get isAlgeria => category == PlateCategory.algeria;

  /// Check if this is an "other" generic plate
  bool get isOther => category == PlateCategory.other;

  /// Check if this plate uses alphanumeric input (EU, Other plates)
  bool get usesAlphanumeric => isEu || isOther;

  /// Get the country code for EU plates (shown in blue band)
  String get countryCode => arabicLabel;

  /// Get left number max length
  int get leftMaxLength {
    if (isGovernment) return 2;
    if (hasRightLabel) return 6;
    if (isEu) return 9; // EU plates can have up to 9 characters
    if (isLibya) return 12; // Libya: single field, flexible length
    if (isAlgeria) return 15; // Algeria: single field, flexible length
    if (isOther) return 50; // Other: no practical limit
    if (usesArabicCenter) return 3;
    return 2; // diplomatic/consular
  }

  /// Get middle number max length (for Algeria)
  int get middleMaxLength {
    return 0;
  }

  /// Get right number max length
  int get rightMaxLength {
    if (isGovernment) return 6;
    if (hasRightLabel) return 0;
    if (isEu) return 0; // EU plates use single field
    if (isLibya) return 0; // Libya: single field
    if (isAlgeria) return 0; // Algeria: single field
    if (isOther) return 0; // Other: single field
    if (usesArabicCenter) return 4;
    return 3; // diplomatic/consular
  }
}

/// Category for visual styling
enum PlateCategory {
  regular, // Black plate, white text
  government, // White plate, red text
  diplomatic, // Light plate, dark text
  consular, // Light plate, dark text
  eu, // White plate, black text, blue band on left
  libya, // White plate, black text, Arabic label on right
  algeria, // Yellow plate, dark text
  other, // White plate, dark text (generic)
}

/// Plate styling configuration
class PlateStyle {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final Color borderColor;

  const PlateStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.borderColor,
  });

  static PlateStyle forCategory(PlateCategory category) {
    switch (category) {
      case PlateCategory.regular:
        return const PlateStyle(
          backgroundColor: Color(0xFF1A1A1A),
          textColor: Colors.white,
          accentColor: Colors.white,
          borderColor: Colors.white,
        );
      case PlateCategory.government:
        return const PlateStyle(
          backgroundColor: Color(0xFFF5F5F0),
          textColor: Color(0xFFDC2626),
          accentColor: Color(0xFFDC2626),
          borderColor: Color(0xFFDC2626),
        );
      case PlateCategory.diplomatic:
        return const PlateStyle(
          backgroundColor: Color(0xFFF5F5F0),
          textColor: Color(0xFF1A1A1A),
          accentColor: Color(0xFF1A1A1A),
          borderColor: Color(0xFF333333),
        );
      case PlateCategory.consular:
        return const PlateStyle(
          backgroundColor: Color(0xFFF5F5F0),
          textColor: Color(0xFF1A1A1A),
          accentColor: Color(0xFF1A1A1A),
          borderColor: Color(0xFF333333),
        );
      case PlateCategory.eu:
        return const PlateStyle(
          backgroundColor: Color(0xFFF5F5F0),
          textColor: Color(0xFF1A1A1A),
          accentColor: Color(0xFF003399), // EU blue
          borderColor: Color(0xFF333333),
        );
      case PlateCategory.libya:
        return const PlateStyle(
          backgroundColor: Color(0xFFF5F5F0),
          textColor: Color(0xFF1A1A1A),
          accentColor: Color(0xFF1A1A1A),
          borderColor: Color(0xFF333333),
        );
      case PlateCategory.algeria:
        return const PlateStyle(
          backgroundColor: Color(0xFFFFCC00), // Yellow
          textColor: Color(0xFF1A1A1A),
          accentColor: Color(0xFF1A1A1A),
          borderColor: Color(0xFF333333),
        );
      case PlateCategory.other:
        return const PlateStyle(
          backgroundColor: Color(0xFFF5F5F0), // White/light
          textColor: Color(0xFF1A1A1A),
          accentColor: Color(0xFF666666),
          borderColor: Color(0xFF333333),
        );
    }
  }
}

/// EU blue band color constant
const Color euBlue = Color(0xFF003399);

/// Structured license plate model for clean JSON serialization
class LicensePlate {
  final PlateType type;
  final String? left;
  final String? right;

  const LicensePlate({
    required this.type,
    this.left,
    this.right,
  });

  /// Create an empty plate with default type
  const LicensePlate.empty() : type = PlateType.tunis, left = null, right = null;

  /// Check if the plate has any data
  bool get isEmpty => (left == null || left!.isEmpty) && (right == null || right!.isEmpty);
  bool get isNotEmpty => !isEmpty;

  /// Get formatted display string
  String get formatted {
    final l = left ?? '';
    final r = right ?? '';

    // Single field types (RS, EU, Libya, Algeria, Other)
    if (type.hasRightLabel) {
      return l.isEmpty ? '' : '$l ${type.displayLabel}';
    }
    if (type.isEu || type.isAlgeria || type.isOther) {
      return l;
    }
    if (type.isLibya) {
      return l.isEmpty ? '' : '$l ${type.displayLabel}';
    }

    // Two field types (Standard, Government, Diplomatic, Consular)
    if (l.isEmpty && r.isEmpty) return '';
    if (l.isEmpty) return '${type.displayLabel} $r';
    if (r.isEmpty) return '$l ${type.displayLabel}';
    return '$l ${type.displayLabel} $r';
  }

  /// Create from JSON map
  factory LicensePlate.fromJson(Map<String, dynamic> json) {
    return LicensePlate(
      type: PlateType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PlateType.tunis,
      ),
      left: json['left'] as String?,
      right: json['right'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'category': type.category.name,
      if (left != null && left!.isNotEmpty) 'left': left,
      if (right != null && right!.isNotEmpty) 'right': right,
      'formatted': formatted,
    };
  }

  /// Create a copy with updated values
  LicensePlate copyWith({
    PlateType? type,
    String? left,
    String? right,
  }) {
    return LicensePlate(
      type: type ?? this.type,
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }

  @override
  String toString() => formatted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LicensePlate &&
          type == other.type &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => Object.hash(type, left, right);
}

/// @deprecated Use LicensePlate instead
/// Parse a license plate string into components (legacy support)
class ParsedPlate {
  final String leftNumber;
  final String middleNumber;
  final String rightNumber;
  final PlateType type;

  ParsedPlate({
    required this.leftNumber,
    this.middleNumber = '',
    required this.rightNumber,
    required this.type,
  });

  /// Convert to new LicensePlate model
  LicensePlate toLicensePlate() {
    return LicensePlate(
      type: type,
      left: leftNumber.isEmpty ? null : leftNumber,
      right: rightNumber.isEmpty ? null : rightNumber,
    );
  }

  /// Get the full plate string
  String get fullPlate {
    // RS format: NUMBER ن.ت
    if (type.hasRightLabel) {
      if (leftNumber.isEmpty) return '';
      return '$leftNumber ${type.displayLabel}';
    }
    // EU format: just the plate number
    if (type.isEu) {
      if (leftNumber.isEmpty) return '';
      return leftNumber;
    }
    // Libya format: NUMBER ليبيا (single field with label)
    if (type.isLibya) {
      if (leftNumber.isEmpty) return '';
      return '$leftNumber ${type.displayLabel}';
    }
    // Algeria format: single field
    if (type.isAlgeria) {
      if (leftNumber.isEmpty) return '';
      return leftNumber;
    }
    // Other format: single field (generic)
    if (type.isOther) {
      if (leftNumber.isEmpty) return '';
      return leftNumber;
    }
    // Standard/Diplomatic/Consular format: NUMBER LABEL NUMBER
    if (leftNumber.isEmpty && rightNumber.isEmpty) return '';
    if (leftNumber.isEmpty) return '${type.displayLabel} $rightNumber';
    if (rightNumber.isEmpty) return '$leftNumber ${type.displayLabel}';
    return '$leftNumber ${type.displayLabel} $rightNumber';
  }
}

/// Parse a license plate string
ParsedPlate parseLicensePlate(String plate, [PlateType? suggestedType]) {
  String normalized = plate.trim();
  PlateType detectedType = suggestedType ?? PlateType.tunis;

  // Check if suggested type is EU
  if (suggestedType != null && suggestedType.isEu) {
    return ParsedPlate(
      leftNumber: normalized.replaceAll(' ', '').toUpperCase(),
      rightNumber: '',
      type: suggestedType,
    );
  }

  // Check if suggested type is Libya (single field with label)
  if (suggestedType != null && suggestedType.isLibya) {
    String plateNumber = normalized;
    // Remove the Arabic label if present
    plateNumber = plateNumber.replaceAll(suggestedType.arabicLabel, '').trim();
    return ParsedPlate(
      leftNumber: plateNumber.replaceAll(' ', ''),
      rightNumber: '',
      type: suggestedType,
    );
  }

  // Check if suggested type is Algeria (single field)
  if (suggestedType != null && suggestedType.isAlgeria) {
    return ParsedPlate(
      leftNumber: normalized.replaceAll(' ', ''),
      rightNumber: '',
      type: suggestedType,
    );
  }

  // Check if suggested type is Other (single field, free input)
  if (suggestedType != null && suggestedType.isOther) {
    return ParsedPlate(
      leftNumber: normalized.toUpperCase(),
      rightNumber: '',
      type: suggestedType,
    );
  }

  // Try to detect plate type from content
  for (final type in PlateType.values) {
    // Skip EU types for auto-detection (they need explicit selection)
    if (type.isEu) continue;

    if (normalized.contains(type.arabicLabel) ||
        normalized.toUpperCase().contains(type.latinLabel)) {
      detectedType = type;
      normalized = normalized
          .replaceAll(type.arabicLabel, '|')
          .replaceAll(RegExp(type.latinLabel, caseSensitive: false), '|');
      break;
    }
  }

  // Clean up separators
  normalized = normalized.replaceAll('-', ' ').replaceAll('/', ' ').trim();

  final parts = normalized
      .split('|')
      .map((e) => e.trim())
      .where((p) => p.isNotEmpty)
      .toList();

  // RS format: single number with label on right
  if (detectedType.hasRightLabel) {
    final number = parts.isNotEmpty ? parts[0].replaceAll(' ', '') : '';
    return ParsedPlate(leftNumber: number, rightNumber: '', type: detectedType);
  }

  // Standard/Diplomatic/Consular format: NUMBER LABEL NUMBER
  if (parts.isEmpty) {
    return ParsedPlate(leftNumber: '', rightNumber: '', type: detectedType);
  } else if (parts.length == 1) {
    final spaceParts = parts[0]
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (spaceParts.length >= 2) {
      return ParsedPlate(
        leftNumber: spaceParts[0],
        rightNumber: spaceParts.sublist(1).join(''),
        type: detectedType,
      );
    }
    return ParsedPlate(
      leftNumber: parts[0],
      rightNumber: '',
      type: detectedType,
    );
  } else {
    return ParsedPlate(
      leftNumber: parts[0].replaceAll(' ', ''),
      rightNumber: parts[1].replaceAll(' ', ''),
      type: detectedType,
    );
  }
}

/// Visual license plate display widget - looks like a real plate
class LicensePlateDisplay extends StatelessWidget {
  final String? leftNumber;
  final String? rightNumber;
  final PlateType type;
  final double scale;
  final bool mini;

  const LicensePlateDisplay({
    super.key,
    this.leftNumber,
    this.rightNumber,
    this.type = PlateType.tunis,
    this.scale = 1.0,
    this.mini = false,
  });

  /// Create from a LicensePlate model (preferred)
  factory LicensePlateDisplay.fromPlate(
    LicensePlate plate, {
    double scale = 1.0,
    bool mini = false,
  }) {
    return LicensePlateDisplay(
      leftNumber: plate.left,
      rightNumber: plate.right,
      type: plate.type,
      scale: scale,
      mini: mini,
    );
  }

  /// @deprecated Use fromPlate instead
  /// Create from a raw string (legacy support)
  factory LicensePlateDisplay.fromString(
    String plate, {
    double scale = 1.0,
    bool mini = false,
    PlateType? suggestedType,
  }) {
    final parsed = parseLicensePlate(plate, suggestedType);
    return LicensePlateDisplay(
      leftNumber: parsed.leftNumber,
      rightNumber: parsed.rightNumber,
      type: parsed.type,
      scale: scale,
      mini: mini,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = PlateStyle.forCategory(type.category);
    final baseHeight = mini ? 32.0 : 48.0;
    final baseFontSize = mini ? 14.0 : 22.0;
    final centerFontSize = mini ? 11.0 : 16.0;
    final euBandWidth = mini ? 24.0 : 36.0;

    return Container(
      height: baseHeight * scale,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: style.borderColor, width: 2.5 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6 * scale,
            offset: Offset(0, 3 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8 * scale),
        child: Stack(
          children: [
            // Subtle texture overlay (only for dark backgrounds)
            if (type.category == PlateCategory.regular)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                ),
              ),
            // EU blue band on left
            if (type.isEu)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: euBandWidth * scale,
                child: Container(
                  decoration: const BoxDecoration(
                    color: euBlue,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/Eu-stars.png',
                      width: (mini ? 16.0 : 24.0) * scale,
                      height: (mini ? 16.0 : 24.0) * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            // Main content
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  left: type.isEu ? (euBandWidth + 8) * scale : 12 * scale,
                  right: 12 * scale,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildPlateContent(
                    style,
                    baseFontSize,
                    centerFontSize,
                    scale,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlateContent(
    PlateStyle style,
    double baseFontSize,
    double centerFontSize,
    double scale,
  ) {
    final left = leftNumber ?? '';
    final right = rightNumber ?? '';

    // RS format: NUMBER ن.ت (label on right)
    if (type.hasRightLabel) {
      return [
        Text(
          left.isNotEmpty ? left : '000000',
          style: TextStyle(
            fontSize: baseFontSize * scale,
            fontWeight: FontWeight.w900,
            color: left.isNotEmpty
                ? style.textColor
                : style.textColor.withValues(alpha: 0.3),
            letterSpacing: 3 * scale,
            fontFamily: 'monospace',
          ),
        ),
        SizedBox(width: 14 * scale),
        Text(
          type.displayLabel,
          style: TextStyle(
            fontSize: centerFontSize * scale,
            fontWeight: FontWeight.w700,
            color: style.accentColor,
          ),
        ),
      ];
    }

    // EU format: single alphanumeric field (country code is shown in blue band)
    if (type.isEu) {
      return [
        Text(
          left.isNotEmpty ? left : 'AB-123-CD',
          style: TextStyle(
            fontSize: baseFontSize * scale,
            fontWeight: FontWeight.w900,
            color: left.isNotEmpty
                ? style.textColor
                : style.textColor.withValues(alpha: 0.3),
            letterSpacing: 2 * scale,
            fontFamily: 'monospace',
          ),
        ),
      ];
    }

    // Libya format: NUMBER ليبيا (single field with label on right)
    if (type.isLibya) {
      return [
        Text(
          left.isNotEmpty ? left : '00000000',
          style: TextStyle(
            fontSize: baseFontSize * scale,
            fontWeight: FontWeight.w900,
            color: left.isNotEmpty
                ? style.textColor
                : style.textColor.withValues(alpha: 0.3),
            letterSpacing: 2 * scale,
            fontFamily: 'monospace',
          ),
        ),
        SizedBox(width: 10 * scale),
        Text(
          type.displayLabel,
          style: TextStyle(
            fontSize: centerFontSize * scale,
            fontWeight: FontWeight.w700,
            color: style.textColor,
            fontFamily: 'serif',
          ),
        ),
      ];
    }

    // Algeria format: single field (yellow plate)
    if (type.isAlgeria) {
      return [
        Text(
          left.isNotEmpty ? left : '00000000',
          style: TextStyle(
            fontSize: baseFontSize * scale,
            fontWeight: FontWeight.w900,
            color: left.isNotEmpty
                ? style.textColor
                : style.textColor.withValues(alpha: 0.3),
            letterSpacing: 2 * scale,
            fontFamily: 'monospace',
          ),
        ),
      ];
    }

    // Other format: single field (generic)
    if (type.isOther) {
      return [
        Text(
          left.isNotEmpty ? left : 'ABC-123',
          style: TextStyle(
            fontSize: baseFontSize * scale,
            fontWeight: FontWeight.w900,
            color: left.isNotEmpty
                ? style.textColor
                : style.textColor.withValues(alpha: 0.3),
            letterSpacing: 2 * scale,
            fontFamily: 'monospace',
          ),
        ),
      ];
    }

    // Standard/Diplomatic/Consular/Transport format: NUMBER TYPE NUMBER (label in center)
    final isDiploConsular =
        type.category == PlateCategory.diplomatic ||
        type.category == PlateCategory.consular;

    // Determine placeholder text based on plate type
    final leftPlaceholder = '0' * type.leftMaxLength;
    final rightPlaceholder = '0' * type.rightMaxLength;

    return [
      Text(
        left.isNotEmpty ? left : leftPlaceholder,
        style: TextStyle(
          fontSize: baseFontSize * scale,
          fontWeight: FontWeight.w900,
          color: left.isNotEmpty
              ? style.textColor
              : style.textColor.withValues(alpha: 0.3),
          letterSpacing: 3 * scale,
          fontFamily: 'monospace',
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * scale,
            vertical: 4 * scale,
          ),
          decoration: (type.usesArabicCenter || type.isGovernment)
              ? null
              : BoxDecoration(
                  border: Border.all(
                    color: style.accentColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4 * scale),
                ),
          child: isDiploConsular
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        type.latinLabel,
                        style: TextStyle(
                          fontSize: (centerFontSize - 2) * scale,
                          fontWeight: FontWeight.w800,
                          color: style.accentColor,
                          letterSpacing: 2,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        type.arabicLabel,
                        style: TextStyle(
                          fontSize: (centerFontSize - 4) * scale,
                          fontWeight: FontWeight.w600,
                          color: style.accentColor.withValues(alpha: 0.85),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                )
              : type.isGovernment
                  ? Container(
                      width: 12 * scale,
                      height: 3 * scale,
                      decoration: BoxDecoration(
                        color: style.accentColor,
                        borderRadius: BorderRadius.circular(1.5 * scale),
                      ),
                    )
                  : Text(
                      type.displayLabel,
                      style: TextStyle(
                        fontSize: centerFontSize * scale,
                        fontWeight: FontWeight.w700,
                        color: style.accentColor,
                        letterSpacing: type.usesArabicCenter ? 0 : 2,
                      ),
                    ),
        ),
      ),
      Text(
        right.isNotEmpty ? right : rightPlaceholder,
        style: TextStyle(
          fontSize: baseFontSize * scale,
          fontWeight: FontWeight.w900,
          color: right.isNotEmpty
              ? style.textColor
              : style.textColor.withValues(alpha: 0.3),
          letterSpacing: 3 * scale,
          fontFamily: 'monospace',
        ),
      ),
    ];
  }
}

/// Plate type selector chip
class PlateTypeChip extends StatelessWidget {
  final PlateType type;
  final bool isSelected;
  final VoidCallback onTap;

  const PlateTypeChip({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = PlateStyle.forCategory(type.category);
    final isGov = type.isGovernment;
    final isEu = type.isEu;
    final isAlgeria = type.isAlgeria;
    final isRegular = type.category == PlateCategory.regular; // tunis, rs

    // Regular plates (tunis, rs) and government always show with their plate colors
    final showSpecialStyle = isGov || isEu || isAlgeria || isRegular;
    final borderColor = isSelected
        ? style.borderColor
        : (showSpecialStyle
            ? ((isRegular || isGov) ? style.borderColor : style.accentColor.withValues(alpha: 0.5))
            : AppColors.border);
    final bgColor = isSelected
        ? (isEu ? euBlue : style.backgroundColor)
        : (showSpecialStyle
            ? (isAlgeria
                ? style.backgroundColor.withValues(alpha: 0.4)
                : (isRegular || isGov)
                    ? style.backgroundColor // Always use plate colors for tunis/rs/gov
                    : style.accentColor.withValues(alpha: 0.15))
            : Colors.transparent);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isEu ? euBlue : style.backgroundColor).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isGov
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '00',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: style.textColor, // Always red
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: style.textColor, // Always red
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Text(
                        '00',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: style.textColor, // Always red
                        ),
                      ),
                    ],
                  )
                : isEu
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 24,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: euBlue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Image.asset(
                              'assets/images/Eu-stars.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'EU',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : euBlue,
                            ),
                          ),
                        ],
                      )
                    : type.isLibya
                        ? Text(
                            type.displayLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? style.textColor : AppColors.textPrimary,
                              fontFamily: 'serif',
                            ),
                          )
                        : Text(
                            type.displayLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              // Always white for regular plates (tunis, rs) since they have black background
                              color: isRegular ? style.textColor : (isSelected ? style.textColor : AppColors.textPrimary),
                            ),
                          ),
            const SizedBox(height: 2),
            Text(
              type.description,
              style: TextStyle(
                fontSize: 9,
                color: isSelected
                    ? (isEu ? Colors.white.withValues(alpha: 0.8) : style.textColor.withValues(alpha: 0.7))
                    // Regular and government plates always use their text color for description
                    : ((isRegular || isGov)
                        ? style.textColor.withValues(alpha: 0.7)
                        : (showSpecialStyle ? style.accentColor.withValues(alpha: 0.7) : AppColors.textTertiary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plate type selector with categories
class PlateTypeSelector extends StatefulWidget {
  final PlateType selectedType;
  final ValueChanged<PlateType> onTypeChanged;

  const PlateTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  State<PlateTypeSelector> createState() => _PlateTypeSelectorState();
}

class _PlateTypeSelectorState extends State<PlateTypeSelector> {
  bool _diplomaticExpanded = false;

  @override
  void initState() {
    super.initState();
    // Auto-expand if a diplomatic/consular type is selected
    _diplomaticExpanded = widget.selectedType.category == PlateCategory.diplomatic ||
        widget.selectedType.category == PlateCategory.consular;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySection('Série Normale', PlateCategory.regular),
        const SizedBox(height: 12),
        _buildCategorySection('Gouvernement', PlateCategory.government),
        const SizedBox(height: 12),
        _buildCategorySection('Libye', PlateCategory.libya),
        const SizedBox(height: 12),
        _buildCategorySection('Algérie', PlateCategory.algeria),
        const SizedBox(height: 12),
        _buildCategorySection('Union Européenne', PlateCategory.eu),
        const SizedBox(height: 12),
        _buildCategorySection('Autre', PlateCategory.other),
        const SizedBox(height: 12),
        _buildDiplomaticSection(),
      ],
    );
  }

  Widget _buildCategorySection(String title, PlateCategory category) {
    final types = PlateType.values
        .where((t) => t.category == category)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            return PlateTypeChip(
              type: type,
              isSelected: widget.selectedType == type,
              onTap: () => widget.onTypeChanged(type),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build expandable diplomatic section with subcategories
  Widget _buildDiplomaticSection() {
    final isDiplomaticSelected = widget.selectedType.category == PlateCategory.diplomatic ||
        widget.selectedType.category == PlateCategory.consular;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with expand/collapse
        GestureDetector(
          onTap: () => setState(() => _diplomaticExpanded = !_diplomaticExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  _diplomaticExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 18,
                  color: isDiplomaticSelected ? AppColors.secondary : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Diplomatique & Consulaire',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDiplomaticSelected ? AppColors.secondary : AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isDiplomaticSelected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.selectedType.description,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Expandable content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Diplomatic subcategory
                _buildSubcategory(
                  'Corps Diplomatique',
                  [PlateType.cmd, PlateType.cd, PlateType.md, PlateType.pat],
                ),
                const SizedBox(height: 12),
                // Consular subcategory
                _buildSubcategory(
                  'Corps Consulaire',
                  [PlateType.cc, PlateType.mc],
                ),
              ],
            ),
          ),
          crossFadeState: _diplomaticExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildSubcategory(String title, List<PlateType> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            return PlateTypeChip(
              type: type,
              isSelected: widget.selectedType == type,
              onTap: () => widget.onTypeChanged(type),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Compact inline plate type selector
class PlateTypePicker extends StatelessWidget {
  final PlateType selectedType;
  final ValueChanged<PlateType> onTypeChanged;

  const PlateTypePicker({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  /// Types to show directly in the picker (excluding diplomatic/consular)
  static const _mainTypes = [
    PlateType.tunis,
    PlateType.rs,
    PlateType.government,
    PlateType.libya,
    PlateType.algeria,
    PlateType.eu,
    PlateType.other,
  ];

  /// Diplomatic and consular types (shown in bottom sheet)
  static const _diplomaticTypes = [
    PlateType.cmd,
    PlateType.cd,
    PlateType.md,
    PlateType.pat,
    PlateType.cc,
    PlateType.mc,
  ];

  bool get _isDiplomaticSelected =>
      _diplomaticTypes.contains(selectedType);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Main plate types
          ..._mainTypes.map((type) => _buildTypeChip(context, type)),
          // Diplomatic chip (opens bottom sheet)
          _buildDiplomaticChip(context),
        ],
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, PlateType type) {
    final isSelected = type == selectedType;
    final style = PlateStyle.forCategory(type.category);
    final isGov = type.isGovernment;
    final isEu = type.isEu;
    final isAlgeria = type.isAlgeria;
    final isRegular = type.category == PlateCategory.regular; // tunis, rs

    final showSpecialStyle = isGov || isEu || isAlgeria || isRegular;
    final bgColor = isSelected
        ? (isEu ? euBlue : style.backgroundColor)
        : (showSpecialStyle
            ? (isAlgeria
                ? style.backgroundColor.withValues(alpha: 0.4)
                : (isRegular || isGov)
                    ? style.backgroundColor // Always use plate colors for tunis/rs/gov
                    : style.accentColor.withValues(alpha: 0.15))
            : AppColors.surfaceVariant);
    final borderColor = isSelected
        ? (isEu ? euBlue : style.borderColor)
        : (showSpecialStyle
            ? ((isRegular || isGov) ? style.borderColor : style.accentColor.withValues(alpha: 0.4))
            : Colors.transparent);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: _buildTypeChipContent(type, isSelected, style),
        ),
      ),
    );
  }

  Widget _buildTypeChipContent(PlateType type, bool isSelected, PlateStyle style) {
    final isRegular = type.category == PlateCategory.regular; // tunis, rs

    if (type.isGovernment) {
      // Always show government plates with full red styling
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '00',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: style.textColor, // Always red
            ),
          ),
          Container(
            width: 6,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: style.textColor, // Always red
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Text(
            '00',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: style.textColor, // Always red
            ),
          ),
        ],
      );
    }

    if (type.isEu) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 18,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: euBlue,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Image.asset(
              'assets/images/Eu-stars.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            'EU',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : euBlue,
            ),
          ),
        ],
      );
    }

    return Text(
      type.displayLabel,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        // Always white for regular plates (tunis, rs) since they have black background
        color: isRegular ? style.textColor : (isSelected ? style.textColor : AppColors.textSecondary),
        fontFamily: type.isLibya ? 'serif' : null,
      ),
    );
  }

  Widget _buildDiplomaticChip(BuildContext context) {
    final isSelected = _isDiplomaticSelected;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _showDiplomaticSheet(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondary
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.secondary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSelected ? selectedType.latinLabel : 'Diplo.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiplomaticSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _DiplomaticBottomSheet(
        selectedType: selectedType,
        onTypeSelected: (type) {
          Navigator.pop(context);
          onTypeChanged(type);
        },
      ),
    );
  }
}

/// Bottom sheet for selecting diplomatic/consular plate types
class _DiplomaticBottomSheet extends StatelessWidget {
  final PlateType selectedType;
  final ValueChanged<PlateType> onTypeSelected;

  const _DiplomaticBottomSheet({
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Plaques Diplomatiques',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Corps Diplomatique section
            Text(
              'Corps Diplomatique',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildOption(PlateType.cmd),
                _buildOption(PlateType.cd),
                _buildOption(PlateType.md),
                _buildOption(PlateType.pat),
              ],
            ),
            const SizedBox(height: 16),

            // Corps Consulaire section
            Text(
              'Corps Consulaire',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildOption(PlateType.cc),
                _buildOption(PlateType.mc),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(PlateType type) {
    final isSelected = type == selectedType;

    return GestureDetector(
      onTap: () => onTypeSelected(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              type.latinLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              type.arabicLabel,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              type.description,
              style: TextStyle(
                fontSize: 9,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple inline plate display with optional icon
class LicensePlateText extends StatelessWidget {
  final LicensePlate plate;
  final double fontSize;
  final bool showIcon;
  final Color? plateColor;

  const LicensePlateText({
    super.key,
    required this.plate,
    this.fontSize = 16,
    this.showIcon = false,
    this.plateColor,
  });

  /// Create from a formatted string (for backward compatibility)
  factory LicensePlateText.fromString(
    String plateString, {
    Key? key,
    double fontSize = 16,
    bool showIcon = false,
    Color? plateColor,
    PlateType? suggestedType,
  }) {
    final parsed = parseLicensePlate(plateString, suggestedType);
    return LicensePlateText(
      key: key,
      plate: parsed.toLicensePlate(),
      fontSize: fontSize,
      showIcon: showIcon,
      plateColor: plateColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.directions_car_rounded,
            size: fontSize + 2,
            color: plateColor ?? AppColors.textSecondary,
          ),
          SizedBox(width: fontSize * 0.5),
        ],
        LicensePlateDisplay.fromPlate(plate, scale: fontSize / 22, mini: true),
      ],
    );
  }
}

/// License plate display card (for summaries, confirmations)
class LicensePlateCard extends StatelessWidget {
  final LicensePlate plate;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? trailing;

  const LicensePlateCard({
    super.key,
    required this.plate,
    this.isSelected = false,
    this.onTap,
    this.trailing,
  });

  /// Create from a formatted string (for backward compatibility)
  factory LicensePlateCard.fromString(
    String plateString, {
    Key? key,
    bool isSelected = false,
    VoidCallback? onTap,
    Widget? trailing,
    PlateType? suggestedType,
  }) {
    final parsed = parseLicensePlate(plateString, suggestedType);
    return LicensePlateCard(
      key: key,
      plate: parsed.toLicensePlate(),
      isSelected: isSelected,
      onTap: onTap,
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LicensePlateDisplay.fromPlate(plate, scale: 0.75),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Full featured license plate input with type selection
class LicensePlateInput extends StatefulWidget {
  final LicensePlate? initialValue;
  final ValueChanged<LicensePlate>? onChanged;
  final String? label;
  final bool showTypeSelector;
  final bool compactTypeSelector;

  const LicensePlateInput({
    super.key,
    this.initialValue,
    this.onChanged,
    this.label,
    this.showTypeSelector = true,
    this.compactTypeSelector = true,
  });

  @override
  State<LicensePlateInput> createState() => _LicensePlateInputState();
}

class _LicensePlateInputState extends State<LicensePlateInput> {
  final _leftController = TextEditingController();
  final _rightController = TextEditingController();
  final _leftFocus = FocusNode();
  final _rightFocus = FocusNode();
  bool _isFocused = false;
  late PlateType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialValue?.type ?? PlateType.tunis;
    _initializeFromValue();

    _leftController.addListener(_onChanged);
    _rightController.addListener(_onChanged);

    _leftFocus.addListener(_onFocusChange);
    _rightFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _leftFocus.hasFocus || _rightFocus.hasFocus;
    });
  }

  void _initializeFromValue() {
    if (widget.initialValue != null) {
      _leftController.text = widget.initialValue!.left ?? '';
      _rightController.text = widget.initialValue!.right ?? '';
    }
  }

  /// Get the current plate as a structured model
  LicensePlate get _currentPlate {
    final left = _leftController.text.trim();
    final right = _rightController.text.trim();

    return LicensePlate(
      type: _selectedType,
      left: left.isEmpty ? null : left,
      right: right.isEmpty ? null : right,
    );
  }

  void _onChanged() {
    widget.onChanged?.call(_currentPlate);
  }

  void _onTypeChanged(PlateType type) {
    setState(() {
      _selectedType = type;
    });
    _onChanged();
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _leftFocus.dispose();
    _rightFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = PlateStyle.forCategory(_selectedType.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Type selector
        if (widget.showTypeSelector) ...[
          widget.compactTypeSelector
              ? PlateTypePicker(
                  selectedType: _selectedType,
                  onTypeChanged: _onTypeChanged,
                )
              : PlateTypeSelector(
                  selectedType: _selectedType,
                  onTypeChanged: _onTypeChanged,
                ),
          const SizedBox(height: AppSpacing.md),
        ],

        // License plate styled container
        Container(
          decoration: BoxDecoration(
            color: style.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused ? style.accentColor : style.borderColor,
              width: _isFocused ? 2.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              if (_isFocused)
                BoxShadow(
                  color: style.accentColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Subtle texture (only for dark backgrounds)
                if (_selectedType.category == PlateCategory.regular)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.08),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                // EU blue band on left
                if (_selectedType.isEu)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 44,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: euBlue,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/Eu-stars.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                // Input fields
                Padding(
                  padding: EdgeInsets.only(
                    left: _selectedType.isEu ? 44 : 0,
                    top: 4,
                    bottom: 4,
                  ),
                  child: _selectedType.hasRightLabel
                      ? _buildRightLabelLayout(style)
                      : _selectedType.isEu
                          ? _buildEuLayout(style)
                          : _selectedType.isLibya
                              ? _buildLibyaLayout(style)
                              : _selectedType.isAlgeria
                                  ? _buildAlgeriaLayout(style)
                                  : _selectedType.isOther
                                      ? _buildOtherLayout(style)
                                      : _buildCenterLabelLayout(style),
                ),
              ],
            ),
          ),
        ),

        // Preview text
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            _selectedType.description,
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  /// Layout for RS plates: NUMBER ن.ت (label on right)
  Widget _buildRightLabelLayout(PlateStyle style) {
    return Row(
      children: [
        Expanded(
          child: _buildNumberField(
            controller: _leftController,
            focusNode: _leftFocus,
            hint: '123456',
            maxLength: 6,
            style: style,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(right: 12),
          color: style.backgroundColor,
          child: Text(
            _selectedType.displayLabel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: style.accentColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Layout for Standard/Diplomatic/Consular/Government: NUMBER LABEL NUMBER (label in center)
  Widget _buildCenterLabelLayout(PlateStyle style) {
    final usesArabic = _selectedType.usesArabicCenter;
    final isGovernment = _selectedType.isGovernment;
    final isDiploConsular =
        _selectedType.category == PlateCategory.diplomatic ||
        _selectedType.category == PlateCategory.consular;

    // Use plate type's defined max lengths
    final leftHint = '0' * _selectedType.leftMaxLength;
    final rightHint = '0' * _selectedType.rightMaxLength;

    return Row(
      children: [
        // Left number
        Expanded(
          flex: isGovernment ? 2 : 3,
          child: _buildNumberField(
            controller: _leftController,
            focusNode: _leftFocus,
            hint: leftHint,
            maxLength: _selectedType.leftMaxLength,
            style: style,
            onMaxReached: () => _rightFocus.requestFocus(),
          ),
        ),

        // Center label
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: (usesArabic || isGovernment) ? 12 : 14,
            vertical: (usesArabic || isGovernment) ? 0 : 4,
          ),
          color: (usesArabic || isGovernment) ? style.backgroundColor : null,
          decoration: (usesArabic || isGovernment)
              ? null
              : BoxDecoration(
                  color: style.backgroundColor,
                  border: Border.all(
                    color: style.accentColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
          child: isDiploConsular
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedType.latinLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: style.accentColor,
                          letterSpacing: 2,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        _selectedType.arabicLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: style.accentColor.withValues(alpha: 0.85),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                )
              : isGovernment
                  ? Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: style.accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  : Text(
                      _selectedType.displayLabel,
                      style: TextStyle(
                        fontSize: usesArabic ? 20 : 16,
                        fontWeight: FontWeight.w700,
                        color: style.accentColor,
                        letterSpacing: usesArabic ? 1 : 3,
                      ),
                    ),
        ),

        // Right number
        Expanded(
          flex: isGovernment ? 5 : 4,
          child: _buildNumberField(
            controller: _rightController,
            focusNode: _rightFocus,
            hint: rightHint,
            maxLength: _selectedType.rightMaxLength,
            style: style,
          ),
        ),
      ],
    );
  }

  /// Layout for EU plates: single alphanumeric field with country code in blue band
  Widget _buildEuLayout(PlateStyle style) {
    return Row(
      children: [
        Expanded(
          child: _buildAlphanumericField(
            controller: _leftController,
            focusNode: _leftFocus,
            hint: 'AB-123-CD',
            maxLength: _selectedType.leftMaxLength,
            style: style,
          ),
        ),
      ],
    );
  }

  /// Layout for Libya plates: NUMBER ليبيا (single field with label on right)
  Widget _buildLibyaLayout(PlateStyle style) {
    return Row(
      children: [
        // Single number field
        Expanded(
          child: _buildNumberField(
            controller: _leftController,
            focusNode: _leftFocus,
            hint: '00000000',
            maxLength: _selectedType.leftMaxLength,
            style: style,
          ),
        ),

        // Libya label on right
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: style.backgroundColor,
          child: Text(
            _selectedType.displayLabel,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: style.textColor,
              fontFamily: 'serif',
            ),
          ),
        ),
      ],
    );
  }

  /// Layout for Algeria plates: single field (yellow plate)
  Widget _buildAlgeriaLayout(PlateStyle style) {
    return Row(
      children: [
        Expanded(
          child: _buildNumberField(
            controller: _leftController,
            focusNode: _leftFocus,
            hint: '00000000',
            maxLength: _selectedType.leftMaxLength,
            style: style,
          ),
        ),
      ],
    );
  }

  /// Layout for Other plates: single alphanumeric field (free input)
  Widget _buildOtherLayout(PlateStyle style) {
    return Row(
      children: [
        Expanded(
          child: _buildAlphanumericField(
            controller: _leftController,
            focusNode: _leftFocus,
            hint: 'ABC-123',
            maxLength: _selectedType.leftMaxLength,
            style: style,
          ),
        ),
      ],
    );
  }

  Widget _buildAlphanumericField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required int maxLength,
    required PlateStyle style,
  }) {
    return Container(
      color: style.backgroundColor,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        cursorColor: style.textColor,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: style.textColor,
          letterSpacing: 3,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: style.textColor.withValues(alpha: 0.25),
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontFamily: 'monospace',
          ),
          filled: true,
          fillColor: style.backgroundColor,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
          counterText: '',
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
          LengthLimitingTextInputFormatter(maxLength),
          UpperCaseTextFormatter(),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required int maxLength,
    required PlateStyle style,
    VoidCallback? onMaxReached,
  }) {
    return Container(
      color: style.backgroundColor,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        cursorColor: style.textColor,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: style.textColor,
          letterSpacing: 4,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: style.textColor.withValues(alpha: 0.25),
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontFamily: 'monospace',
          ),
          filled: true,
          fillColor: style.backgroundColor,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
          counterText: '',
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength),
        ],
        onChanged: (value) {
          if (value.length >= maxLength && onMaxReached != null) {
            onMaxReached();
          }
        },
      ),
    );
  }
}

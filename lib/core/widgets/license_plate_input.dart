import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Tunisian license plate type enumeration
enum PlateType {
  // Regular Series
  tunis('تونس', 'TN', 'Standard', PlateCategory.regular),
  rs('ن ت', 'RS', 'Régime Suspensif', PlateCategory.regular),

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

  /// Get display label (Arabic for regular, Latin for diplomatic)
  String get displayLabel {
    if (category == PlateCategory.diplomatic ||
        category == PlateCategory.consular) {
      return latinLabel;
    }
    return arabicLabel;
  }

  /// Check if plate uses Arabic label in the center
  bool get usesArabicCenter => category == PlateCategory.regular;

  /// Check if label is positioned on the right (single number + label)
  bool get hasRightLabel => this == PlateType.rs;

  /// Check if this uses the standard center layout (number - label - number)
  bool get hasCenterLabel => !hasRightLabel;
}

/// Category for visual styling
enum PlateCategory {
  regular, // Black plate, white text
  diplomatic, // Blue plate
  consular, // Green plate
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
    }
  }
}

/// Parse a license plate string into components
class ParsedPlate {
  final String leftNumber;
  final String rightNumber;
  final PlateType type;

  ParsedPlate({
    required this.leftNumber,
    required this.rightNumber,
    required this.type,
  });

  /// Get the full plate string
  String get fullPlate {
    // RS format: NUMBER ن.ت
    if (type.hasRightLabel) {
      if (leftNumber.isEmpty) return '';
      return '$leftNumber ${type.displayLabel}';
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

  // Try to detect plate type from content
  for (final type in PlateType.values) {
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

  factory LicensePlateDisplay.fromString(
    String plate, {
    double scale = 1.0,
    bool mini = false,
  }) {
    final parsed = parseLicensePlate(plate);
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
            // Subtle texture overlay
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
            // Main content
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
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

    // Standard/Diplomatic/Consular format: NUMBER TYPE NUMBER (label in center)
    final isDiploConsular =
        type.category == PlateCategory.diplomatic ||
        type.category == PlateCategory.consular;

    return [
      Text(
        left.isNotEmpty ? left : (type.usesArabicCenter ? '000' : '00'),
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
          decoration: type.usesArabicCenter
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
        right.isNotEmpty ? right : (type.usesArabicCenter ? '0000' : '000'),
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? style.backgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? style.borderColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: style.backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.displayLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? style.textColor : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              type.description,
              style: TextStyle(
                fontSize: 9,
                color: isSelected
                    ? style.textColor.withValues(alpha: 0.7)
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plate type selector with categories
class PlateTypeSelector extends StatelessWidget {
  final PlateType selectedType;
  final ValueChanged<PlateType> onTypeChanged;

  const PlateTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategorySection('Série Normale', PlateCategory.regular),
        const SizedBox(height: 12),
        _buildCategorySection('Diplomatique', PlateCategory.diplomatic),
        const SizedBox(height: 12),
        _buildCategorySection('Consulaire', PlateCategory.consular),
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
              isSelected: selectedType == type,
              onTap: () => onTypeChanged(type),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PlateType.values.map((type) {
          final isSelected = type == selectedType;
          final style = PlateStyle.forCategory(type.category);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTypeChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? style.backgroundColor
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? style.borderColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  type.displayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? style.textColor
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Legacy support - simple text display
class LicensePlateText extends StatelessWidget {
  final String plate;
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
        LicensePlateDisplay.fromString(plate, scale: fontSize / 22, mini: true),
      ],
    );
  }
}

/// License plate display card (for summaries, confirmations)
class LicensePlateCard extends StatelessWidget {
  final String plate;
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
            LicensePlateDisplay.fromString(plate, scale: 0.75),
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
  final String? initialValue;
  final PlateType? initialType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<PlateType>? onTypeChanged;
  final String? label;
  final bool showTypeSelector;
  final bool compactTypeSelector;

  const LicensePlateInput({
    super.key,
    this.initialValue,
    this.initialType,
    this.onChanged,
    this.onTypeChanged,
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
    _selectedType = widget.initialType ?? PlateType.tunis;
    _parseInitialValue();

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

  void _parseInitialValue() {
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      final parsed = parseLicensePlate(
        widget.initialValue!,
        widget.initialType,
      );
      _leftController.text = parsed.leftNumber;
      _rightController.text = parsed.rightNumber;
      if (widget.initialType == null) {
        _selectedType = parsed.type;
      }
    }
  }

  String get _fullPlate {
    final left = _leftController.text.trim();
    final right = _rightController.text.trim();

    // RS format: NUMBER ن.ت
    if (_selectedType.hasRightLabel) {
      if (left.isEmpty) return '';
      return '$left ${_selectedType.displayLabel}';
    }

    // Standard/Diplomatic/Consular format: NUMBER LABEL NUMBER
    if (left.isEmpty && right.isEmpty) return '';
    if (left.isEmpty) return '${_selectedType.displayLabel} $right';
    if (right.isEmpty) return '$left ${_selectedType.displayLabel}';
    return '$left ${_selectedType.displayLabel} $right';
  }

  void _onChanged() {
    widget.onChanged?.call(_fullPlate);
  }

  void _onTypeChanged(PlateType type) {
    setState(() {
      _selectedType = type;
    });
    widget.onTypeChanged?.call(type);
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
                // Subtle texture
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
                // Input fields
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _selectedType.hasRightLabel
                      ? _buildRightLabelLayout(style)
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

  /// Layout for Standard/Diplomatic/Consular: NUMBER LABEL NUMBER (label in center)
  Widget _buildCenterLabelLayout(PlateStyle style) {
    final usesArabic = _selectedType.usesArabicCenter;
    final isDiploConsular =
        _selectedType.category == PlateCategory.diplomatic ||
        _selectedType.category == PlateCategory.consular;

    return Row(
      children: [
        // Left number
        Expanded(
          flex: 3,
          child: _buildNumberField(
            controller: _leftController,
            focusNode: _leftFocus,
            hint: usesArabic ? '123' : '00',
            maxLength: usesArabic ? 3 : 2,
            style: style,
            onMaxReached: () => _rightFocus.requestFocus(),
          ),
        ),

        // Center label
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: usesArabic ? 12 : 14,
            vertical: usesArabic ? 0 : 4,
          ),
          color: usesArabic ? style.backgroundColor : null,
          decoration: usesArabic
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
          flex: 4,
          child: _buildNumberField(
            controller: _rightController,
            focusNode: _rightFocus,
            hint: usesArabic ? '4567' : '000',
            maxLength: usesArabic ? 4 : 3,
            style: style,
          ),
        ),
      ],
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

import 'package:flutter/material.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';

/// Confirmation dialog for data reset operation
/// 
/// This dialog implements a strong confirmation mechanism requiring users
/// to type "RESET" to confirm the destructive action. It follows Solo Leveling
/// theme and provides clear warnings about data loss.
/// 
/// **Features:**
/// - Type-to-confirm mechanism (must type "RESET")
/// - Clear warning messages about data loss
/// - Danger styling with red colors
/// - Solo Leveling themed design
/// - Glassmorphism effects
/// - Loading state during reset operation
/// - Error handling and display
/// 
/// **Safety Measures:**
/// - Requires exact text match ("RESET")
/// - Multiple warning messages
/// - Clear action button states
/// - Confirmation text field validation
/// - Non-dismissible during reset operation
/// 
/// Usage:
/// ```dart
/// final shouldReset = await showDialog<bool>(
///   context: context,
///   builder: (context) => const DataResetConfirmationDialog(),
/// );
/// 
/// if (shouldReset == true) {
///   // Perform reset operation
/// }
/// ```
class DataResetConfirmationDialog extends StatefulWidget {
  const DataResetConfirmationDialog({super.key});

  @override
  State<DataResetConfirmationDialog> createState() => _DataResetConfirmationDialogState();
}

class _DataResetConfirmationDialogState extends State<DataResetConfirmationDialog>
    with TickerProviderStateMixin {
  final _confirmationController = TextEditingController();
  final _confirmationFocusNode = FocusNode();
  
  late AnimationController _warningController;
  late AnimationController _dangerController;
  late Animation<double> _warningAnimation;
  late Animation<double> _dangerAnimation;
  
  bool _isConfirmationValid = false;
  bool _isResetting = false;
  String? _errorMessage;
  
  static const String requiredConfirmationText = 'RESET';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _confirmationController.addListener(_onConfirmationChanged);
  }

  void _initializeAnimations() {
    // Warning pulse animation
    _warningController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Danger glow animation
    _dangerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _warningAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _warningController,
      curve: Curves.easeInOut,
    ));
    
    _dangerAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dangerController,
      curve: Curves.easeInOut,
    ));
    
    // Start warning animation
    _warningController.repeat(reverse: true);
    _dangerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _warningController.dispose();
    _dangerController.dispose();
    _confirmationController.dispose();
    _confirmationFocusNode.dispose();
    super.dispose();
  }

  void _onConfirmationChanged() {
    final text = _confirmationController.text.trim();
    final isValid = text == requiredConfirmationText;
    
    if (isValid != _isConfirmationValid) {
      setState(() {
        _isConfirmationValid = isValid;
        _errorMessage = null; // Clear error when user types
      });
    }
  }

  Future<void> _performReset() async {
    if (!_isConfirmationValid || _isResetting) return;
    
    setState(() {
      _isResetting = true;
      _errorMessage = null;
    });
    
    try {
      // Return true to indicate user confirmed reset
      // The actual reset will be handled by the calling code
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to confirm reset: $e';
        _isResetting = false;
      });
    }
  }

  void _cancelReset() {
    if (_isResetting) return; // Prevent cancellation during reset
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isResetting, // Prevent dismissal during reset
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _dangerAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: SoloLevelingColors.crimsonRed.withValues(
                      alpha: 0.3 * _dangerAnimation.value,
                    ),
                    blurRadius: 30 * _dangerAnimation.value,
                    spreadRadius: 5 * _dangerAnimation.value,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GlassmorphismEffects.hunterPanel(
                  context: context,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildWarningContent(),
                        const SizedBox(height: 24),
                        _buildConfirmationField(),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorMessage(),
                        ],
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _warningAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SoloLevelingColors.crimsonRed.withValues(alpha: _warningAnimation.value),
                    SoloLevelingColors.crimsonRed.withValues(alpha: 0.7 * _warningAnimation.value),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: SoloLevelingColors.crimsonRed.withValues(
                      alpha: 0.4 * _warningAnimation.value,
                    ),
                    blurRadius: 20 * _warningAnimation.value,
                    spreadRadius: 2 * _warningAnimation.value,
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'DANGER ZONE',
              style: SoloLevelingTypography.hunterTitle.copyWith(
                fontSize: 24,
                color: SoloLevelingColors.crimsonRed,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reset All Data',
              style: SoloLevelingTypography.hunterSubtitle.copyWith(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWarningContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: SoloLevelingColors.crimsonRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'This action cannot be undone!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: SoloLevelingColors.crimsonRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The following data will be permanently deleted:',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildDataList(),
        ],
      ),
    );
  }

  List<Widget> _buildDataList() {
    final dataTypes = [
      'All character stats and levels',
      'Complete activity history',
      'All achievements and progress',
      'App settings and preferences',
      'Daily login streaks and rewards',
      'Notification schedules',
    ];

    return dataTypes.map((data) => Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  Widget _buildConfirmationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type "$requiredConfirmationText" to confirm:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmationController,
          focusNode: _confirmationFocusNode,
          enabled: !_isResetting,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isConfirmationValid 
                ? SoloLevelingColors.hunterGreen 
                : Theme.of(context).colorScheme.onSurface,
            letterSpacing: 2.0,
          ),
          decoration: InputDecoration(
            hintText: requiredConfirmationText,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 2.0,
            ),
            prefixIcon: Icon(
              _isConfirmationValid ? Icons.check_circle : Icons.edit,
              color: _isConfirmationValid 
                  ? SoloLevelingColors.hunterGreen 
                  : SoloLevelingColors.crimsonRed.withValues(alpha: 0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isConfirmationValid 
                    ? SoloLevelingColors.hunterGreen 
                    : SoloLevelingColors.crimsonRed,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error,
            color: SoloLevelingColors.crimsonRed,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: SoloLevelingColors.crimsonRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: TextButton(
            onPressed: _isResetting ? null : _cancelReset,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Text(
              'Cancel',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Reset Button
        Expanded(
          child: ElevatedButton(
            onPressed: (_isConfirmationValid && !_isResetting) ? _performReset : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: SoloLevelingColors.crimsonRed,
              foregroundColor: Colors.white,
              disabledBackgroundColor: SoloLevelingColors.crimsonRed.withValues(alpha: 0.3),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _isConfirmationValid ? 8 : 2,
              shadowColor: SoloLevelingColors.crimsonRed.withValues(alpha: 0.5),
            ),
            child: _isResetting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Resetting...'),
                    ],
                  )
                : const Text(
                    'RESET ALL DATA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
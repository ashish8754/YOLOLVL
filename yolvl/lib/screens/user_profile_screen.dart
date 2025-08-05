import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/daily_login_provider.dart';
import '../theme/solo_leveling_theme.dart';
import '../theme/glassmorphism_effects.dart';
import '../widgets/hunter_profile_card.dart';
import '../widgets/data_reset_confirmation_dialog.dart';
import '../services/hunter_rank_service.dart';
import '../services/data_reset_service.dart';
import '../screens/onboarding_screen.dart';

/// User profile editing screen with Solo Leveling theme
/// 
/// This screen allows users to edit their profile information including
/// display name and avatar. It follows the existing app architecture and
/// design patterns while providing a seamless user experience.
/// 
/// **Key Features:**
/// - Edit display name with validation
/// - Solo Leveling themed UI design
/// - Integration with existing state management
/// - Proper error handling and user feedback
/// - Glassmorphism effects matching app theme
/// 
/// **Navigation:**
/// - Accessible from user icon in dashboard/navigation app bar
/// - Uses slide transition for smooth navigation
/// - Proper back navigation handling
/// 
/// **Form Validation:**
/// - Display name length validation (1-30 characters)
/// - Prevents empty names
/// - Trims whitespace
/// - Real-time validation feedback
/// 
/// **State Management:**
/// - Integrates with UserProvider
/// - Loading states during save operations
/// - Error handling with user-friendly messages
/// - Success feedback with visual confirmation
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  
  late AnimationController _glowController;
  late AnimationController _saveButtonController;
  late Animation<double> _glowAnimation;
  late Animation<double> _saveButtonAnimation;
  
  bool _hasChanges = false;
  String? _initialName;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeUserData();
  }

  void _initializeAnimations() {
    // Glow animation for profile card
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Save button animation
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _saveButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _saveButtonController, curve: Curves.elasticOut),
    );

    // Start continuous glow animation
    _glowController.repeat(reverse: true);
  }

  void _initializeUserData() {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    if (user != null) {
      _initialName = user.name;
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _saveButtonController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        if (user == null) {
          return _buildErrorScreen('User not found');
        }

        final rankData = HunterRankService.instance.getRankForLevel(user.level);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: _buildAppBar(context, rankData),
          body: _buildBody(context, user, userProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, HunterRankData rankData) {
    return AppBar(
      title: Text(
        'Hunter Profile',
        style: SoloLevelingTypography.hunterTitle.copyWith(
          fontSize: 24,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: () => _handleBackPressed(context),
        tooltip: 'Back to Dashboard',
      ),
      actions: [
        if (_hasChanges)
          AnimatedBuilder(
            animation: _saveButtonAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _saveButtonAnimation.value,
                child: IconButton(
                  icon: Icon(
                    Icons.save,
                    color: SoloLevelingColors.hunterGreen,
                  ),
                  onPressed: () => _saveProfile(context),
                  tooltip: 'Save Changes',
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, User user, UserProvider userProvider) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card Display
              _buildProfileCardSection(user),
              
              const SizedBox(height: 32),
              
              // Profile Information Section
              _buildProfileInfoSection(context, user, userProvider),
              
              const SizedBox(height: 32),
              
              // Stats Overview Section
              _buildStatsOverviewSection(user),
              
              const SizedBox(height: 32),
              
              // Hunter Information Section
              _buildHunterInfoSection(user),
              
              const SizedBox(height: 32),
              
              // Danger Zone Section
              _buildDangerZoneSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCardSection(User user) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SoloLevelingColors.electricBlue.withValues(
                  alpha: 0.3 * _glowAnimation.value,
                ),
                blurRadius: 20 * _glowAnimation.value,
                spreadRadius: 5 * _glowAnimation.value,
              ),
            ],
          ),
          child: HunterProfileCard(
            displayMode: HunterProfileDisplayMode.detailed,
            showAvatar: true,
            showRankBadge: true,
            showLevelProgress: false, // Disabled to prevent overflow in profile view
            showStats: true,
            margin: const EdgeInsets.all(0),
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoSection(BuildContext context, User user, UserProvider userProvider) {
    return GlassmorphismEffects.hunterPanel(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: SoloLevelingColors.electricBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Profile Information',
                  style: SoloLevelingTypography.hunterSubtitle.copyWith(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Display Name Field
            _buildDisplayNameField(context, userProvider),
            
            const SizedBox(height: 16),
            
            // Hunter ID (Read-only)
            _buildHunterIdField(user),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayNameField(BuildContext context, UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Name',
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          enabled: !userProvider.isLoading,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your hunter name',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              Icons.badge_outlined,
              color: SoloLevelingColors.hunterGreen,
            ),
            suffixIcon: _hasChanges
                ? Icon(
                    Icons.edit,
                    color: SoloLevelingColors.electricBlue,
                  )
                : null,
          ),
          validator: _validateDisplayName,
          onChanged: _onNameChanged,
          onFieldSubmitted: (_) => _saveProfile(context),
          textInputAction: TextInputAction.done,
          maxLength: 30,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
            return Text(
              '$currentLength/${maxLength ?? 30}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHunterIdField(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hunter ID',
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: user.id.substring(0, 12).toUpperCase(),
          enabled: false,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 16,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.fingerprint,
              color: SoloLevelingColors.silverMist,
            ),
            helperText: 'Unique hunter identification',
            helperStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverviewSection(User user) {
    return GlassmorphismEffects.hunterPanel(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: SoloLevelingColors.hunterGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Hunter Statistics',
                  style: SoloLevelingTypography.hunterSubtitle.copyWith(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Level and EXP
            Row(
              children: [
                _buildStatCard('Level', '${user.level}', SoloLevelingColors.electricBlue),
                const SizedBox(width: 16),
                _buildStatCard('EXP', '${user.currentEXP.toInt()}', SoloLevelingColors.hunterGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: SoloLevelingTypography.statValue.copyWith(
                fontSize: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: SoloLevelingTypography.statLabel.copyWith(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHunterInfoSection(User user) {
    return GlassmorphismEffects.hunterPanel(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: SoloLevelingColors.mysticPurple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Hunter Information',
                  style: SoloLevelingTypography.hunterSubtitle.copyWith(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Registration Date
            _buildInfoRow('Registered', _formatDate(user.createdAt)),
            const SizedBox(height: 12),
            
            // Last Active
            _buildInfoRow('Last Active', _formatDate(user.lastActive)),
            const SizedBox(height: 12),
            
            // Onboarding Status
            _buildInfoRow(
              'Training Status',
              user.hasCompletedOnboarding ? 'Completed' : 'In Progress',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: SoloLevelingTypography.systemNotification.copyWith(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection(BuildContext context) {
    return GlassmorphismEffects.hunterPanel(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: SoloLevelingColors.crimsonRed,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Danger Zone',
                  style: SoloLevelingTypography.hunterSubtitle.copyWith(
                    fontSize: 20,
                    color: SoloLevelingColors.crimsonRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Warning Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SoloLevelingColors.crimsonRed.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: SoloLevelingColors.crimsonRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Destructive actions that cannot be undone',
                      style: TextStyle(
                        fontSize: 14,
                        color: SoloLevelingColors.crimsonRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Reset All Data Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showResetConfirmation(context),
                icon: const Icon(Icons.delete_forever, size: 20),
                label: const Text(
                  'Reset All Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SoloLevelingColors.crimsonRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: SoloLevelingColors.crimsonRed.withValues(alpha: 0.5),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Description Text
            Text(
              'This will permanently delete all your progress, activities, achievements, and settings. This action cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Hunter Profile'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name cannot be empty';
    }
    
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Display name must be at least 1 character';
    }
    
    if (trimmed.length > 30) {
      return 'Display name must be 30 characters or less';
    }
    
    // Check for invalid characters (optional)
    if (trimmed.contains(RegExp(r'[<>"\\/]'))) {
      return 'Display name contains invalid characters';
    }
    
    return null;
  }

  void _onNameChanged(String value) {
    final hasChanges = value.trim() != (_initialName ?? '');
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
      
      if (_hasChanges) {
        _saveButtonController.forward();
      } else {
        _saveButtonController.reverse();
      }
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userProvider = context.read<UserProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final newName = _nameController.text.trim();
    
    if (newName == _initialName) {
      // No changes to save
      return;
    }

    try {
      await userProvider.updateProfile(name: newName);
      
      if (mounted) {
        // Update initial name for future comparisons
        _initialName = newName;
        setState(() {
          _hasChanges = false;
        });
        _saveButtonController.reverse();
        
        // Show success message
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: SoloLevelingColors.hunterGreen,
                ),
                const SizedBox(width: 12),
                const Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: theme.colorScheme.surfaceContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: SoloLevelingColors.crimsonRed,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to update profile: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.surfaceContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleBackPressed(BuildContext context) async {
    if (_hasChanges) {
      final navigator = Navigator.of(context);
      final shouldDiscard = await _showDiscardChangesDialog(context);
      if (shouldDiscard) {
        if (mounted) {
          navigator.pop();
        }
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showDiscardChangesDialog(BuildContext context) async {
    final theme = Theme.of(context);
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Discard Changes?',
          style: SoloLevelingTypography.hunterSubtitle.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: SoloLevelingColors.crimsonRed,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Show reset confirmation dialog
  Future<void> _showResetConfirmation(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const DataResetConfirmationDialog(),
    );

    if (shouldReset == true && mounted) {
      await _performDataReset(context);
    }
  }

  /// Perform the actual data reset operation
  Future<void> _performDataReset(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: SoloLevelingColors.crimsonRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Resetting all data...',
                style: SoloLevelingTypography.systemNotification.copyWith(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please do not close the app',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Perform the reset using DataResetService
      final resetService = DataResetService();
      final result = await resetService.resetAllData();

      // Close loading dialog
      if (mounted) {
        navigator.pop();
      }

      if (result.success) {
        // Reset all providers
        await _resetAllProviders(context);

        // Show success message
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: SoloLevelingColors.hunterGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All data has been reset successfully',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: theme.colorScheme.surfaceContainer,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to onboarding after a brief delay
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
              (route) => false,
            );
          }
        }
      } else {
        // Show error message
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: SoloLevelingColors.crimsonRed,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.errorMessage ?? 'Failed to reset data',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: theme.colorScheme.surfaceContainer,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        navigator.pop();
      }

      // Show error message
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: SoloLevelingColors.crimsonRed,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to reset data: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.surfaceContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Reset all providers to clear their state
  Future<void> _resetAllProviders(BuildContext context) async {
    try {
      // Reset UserProvider
      final userProvider = context.read<UserProvider>();
      await userProvider.initializeApp(); // This will detect no user and set needsOnboarding

      // Reset ActivityProvider
      final activityProvider = context.read<ActivityProvider>();
      await activityProvider.initialize();

      // Reset AchievementProvider
      final achievementProvider = context.read<AchievementProvider>();
      await achievementProvider.loadAchievements();

      // Reset SettingsProvider
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.initialize();

      // Reset DailyLoginProvider
      final dailyLoginProvider = context.read<DailyLoginProvider>();
      await dailyLoginProvider.initialize();

    } catch (e) {
      debugPrint('Error resetting providers: $e');
    }
  }
}
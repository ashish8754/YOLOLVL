import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../providers/activity_provider.dart';
import '../services/activity_service.dart';
import '../widgets/floating_stat_gain_animation.dart';
import '../widgets/level_up_celebration.dart';

/// Screen for logging new activities with duration and expected gains preview
class ActivityLoggingScreen extends StatefulWidget {
  const ActivityLoggingScreen({super.key});

  @override
  State<ActivityLoggingScreen> createState() => _ActivityLoggingScreenState();
}

class _ActivityLoggingScreenState extends State<ActivityLoggingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController(text: '60');
  final _notesController = TextEditingController();
  
  ActivityType _selectedActivityType = ActivityType.workoutWeights;
  int _selectedDuration = 60;
  ActivityGainPreview? _gainPreview;
  bool _isLogging = false;
  bool _showGainAnimation = false;
  bool _showLevelUpAnimation = false;
  Map<StatType, double>? _lastStatGains;
  double? _lastExpGained;
  int? _newLevel;

  @override
  void initState() {
    super.initState();
    _updateGainPreview();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateGainPreview() {
    // Create a temporary activity service to calculate gains
    final activityService = ActivityService();
    setState(() {
      _gainPreview = activityService.calculateExpectedGains(
        activityType: _selectedActivityType,
        durationMinutes: _selectedDuration,
      );
    });
  }

  Future<void> _logActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLogging = true;
    });

    try {
      final activityProvider = context.read<ActivityProvider>();
      final result = await activityProvider.logActivity(
        activityType: _selectedActivityType,
        durationMinutes: _selectedDuration,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (result != null && result.success) {
        // Haptic feedback for success
        HapticFeedback.mediumImpact();
        
        // Store animation data
        setState(() {
          _lastStatGains = result.statGains;
          _lastExpGained = result.expGained;
          _newLevel = result.leveledUp ? result.newLevel : null;
        });

        // Show stat gain animation first
        setState(() {
          _showGainAnimation = true;
        });

        // Wait for stat animation to complete, then show level up if needed
        await Future.delayed(const Duration(milliseconds: 1800));
        
        if (result.leveledUp && mounted) {
          // Additional haptic feedback for level up
          HapticFeedback.heavyImpact();
          setState(() {
            _showLevelUpAnimation = true;
          });
          
          // Wait for level up animation
          await Future.delayed(const Duration(milliseconds: 3000));
        }

        // Show success feedback and close
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Activity logged successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Close the screen
          Navigator.of(context).pop(result);
        }
      } else {
        // Haptic feedback for error
        HapticFeedback.lightImpact();
        
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?.errorMessage ?? 'Failed to log activity'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Haptic feedback for error
      HapticFeedback.lightImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLogging = false;
        });
      }
    }
  }

  void _onGainAnimationComplete() {
    setState(() {
      _showGainAnimation = false;
    });
  }

  void _onLevelUpAnimationComplete() {
    setState(() {
      _showLevelUpAnimation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LevelUpOverlay(
      showCelebration: _showLevelUpAnimation,
      newLevel: _newLevel,
      onAnimationComplete: _onLevelUpAnimationComplete,
      child: FloatingGainOverlay(
        showGains: _showGainAnimation,
        statGains: _lastStatGains ?? {},
        expGained: _lastExpGained ?? 0.0,
        onAnimationComplete: _onGainAnimationComplete,
        child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Log Activity'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity Type Selection
              Text(
                'Activity Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ActivityType>(
                    value: _selectedActivityType,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                    items: ActivityType.values.map((ActivityType type) {
                      return DropdownMenuItem<ActivityType>(
                        value: type,
                        child: Text(
                          type.displayName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (ActivityType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedActivityType = newValue;
                        });
                        _updateGainPreview();
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Duration Input
              Text(
                'Duration (minutes)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter duration in minutes',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a duration';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Duration must be a positive number';
                  }
                  if (duration > 1440) {
                    return 'Duration cannot exceed 24 hours (1440 minutes)';
                  }
                  return null;
                },
                onChanged: (value) {
                  final duration = int.tryParse(value);
                  if (duration != null && duration > 0) {
                    setState(() {
                      _selectedDuration = duration;
                    });
                    _updateGainPreview();
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              // Notes Input (Optional)
              Text(
                'Notes (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Add any notes about this activity...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Expected Gains Preview
              if (_gainPreview != null && _gainPreview!.isValid) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Gains:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          // Stat gains
                          for (final statType in _gainPreview!.affectedStats)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    statType.icon,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${statType.displayName} ${_gainPreview!.getStatGainText(statType)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // EXP gain
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '⭐',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _gainPreview!.expGainText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLogging ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLogging ? null : _logActivity,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLogging
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Log Activity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chart Auto-scaling Logic', () {
    /// Calculate appropriate chart maximum using dynamic scaling
    /// Uses increments of 5, 10, 15, 20, etc. for better readability
    double calculateChartMaximum(double maxStatValue) {
      // For values up to 5, use 5 as the ceiling (original behavior)
      if (maxStatValue <= 5.0) {
        return 5.0;
      }
      
      // For values above 5, use increments of 5
      // Round up to the next multiple of 5
      final increment = 5.0;
      return (maxStatValue / increment).ceil() * increment;
    }

    /// Format stat value with appropriate decimal precision
    /// Shows meaningful precision without trailing zeros (e.g., 7.23 instead of 7.2300)
    String formatStatValue(double value) {
      // For whole numbers, show no decimal places
      if (value == value.roundToDouble()) {
        return value.toStringAsFixed(0);
      }
      
      // For values with decimals, show up to 2 decimal places but remove trailing zeros
      String formatted = value.toStringAsFixed(2);
      
      // Remove trailing zeros after decimal point
      if (formatted.contains('.')) {
        formatted = formatted.replaceAll(RegExp(r'0*$'), '');
        formatted = formatted.replaceAll(RegExp(r'\.$'), '');
      }
      
      return formatted;
    }

    test('should calculate correct chart maximum for stats below 5.0', () {
      expect(calculateChartMaximum(1.0), equals(5.0));
      expect(calculateChartMaximum(3.5), equals(5.0));
      expect(calculateChartMaximum(4.9), equals(5.0));
      expect(calculateChartMaximum(5.0), equals(5.0));
    });

    test('should calculate correct chart maximum for stats above 5.0', () {
      expect(calculateChartMaximum(5.1), equals(10.0));
      expect(calculateChartMaximum(7.5), equals(10.0));
      expect(calculateChartMaximum(10.0), equals(10.0));
      expect(calculateChartMaximum(10.1), equals(15.0));
      expect(calculateChartMaximum(12.5), equals(15.0));
      expect(calculateChartMaximum(15.0), equals(15.0));
    });

    test('should calculate correct chart maximum for very high stats', () {
      expect(calculateChartMaximum(23.7), equals(25.0));
      expect(calculateChartMaximum(47.5), equals(50.0));
      expect(calculateChartMaximum(123.7), equals(125.0));
      expect(calculateChartMaximum(999.1), equals(1000.0));
    });

    test('should format whole numbers without decimal places', () {
      expect(formatStatValue(1.0), equals('1'));
      expect(formatStatValue(5.0), equals('5'));
      expect(formatStatValue(10.0), equals('10'));
      expect(formatStatValue(100.0), equals('100'));
    });

    test('should format decimal values with appropriate precision', () {
      expect(formatStatValue(1.5), equals('1.5'));
      expect(formatStatValue(7.25), equals('7.25'));
      expect(formatStatValue(12.75), equals('12.75'));
      expect(formatStatValue(99.99), equals('99.99'));
    });

    test('should remove trailing zeros from formatted values', () {
      expect(formatStatValue(7.10), equals('7.1'));
      expect(formatStatValue(15.20), equals('15.2'));
      expect(formatStatValue(23.00), equals('23'));
      expect(formatStatValue(42.30), equals('42.3'));
    });

    test('should handle edge cases in formatting', () {
      expect(formatStatValue(0.0), equals('0'));
      expect(formatStatValue(0.1), equals('0.1'));
      expect(formatStatValue(0.01), equals('0.01'));
      expect(formatStatValue(0.10), equals('0.1'));
    });

    test('should handle high precision values correctly', () {
      // Values with more than 2 decimal places should be rounded to 2
      expect(formatStatValue(7.123), equals('7.12'));
      expect(formatStatValue(15.999), equals('16'));
      expect(formatStatValue(23.456), equals('23.46'));
    });

    test('should handle chart scaling for mixed stat ranges', () {
      // Test scenario: mixed stats like in real usage
      final stats = [1.1, 5.0, 12.5, 100.0, 3.7, 25.8];
      final maxStat = stats.reduce((a, b) => a > b ? a : b); // 100.0
      
      expect(calculateChartMaximum(maxStat), equals(100.0));
    });

    test('should handle chart scaling progression scenarios', () {
      // Test progression from below ceiling to above ceiling
      expect(calculateChartMaximum(4.8), equals(5.0));  // Below old ceiling
      expect(calculateChartMaximum(5.1), equals(10.0)); // Just above old ceiling
      expect(calculateChartMaximum(6.8), equals(10.0)); // Moderate progression
      expect(calculateChartMaximum(12.6), equals(15.0)); // Higher progression
    });

    test('should format stats for display in different scenarios', () {
      // Test formatting for various stat values that might appear in the app
      final testValues = {
        1.0: '1',
        1.1: '1.1',
        5.0: '5',
        7.23: '7.23',
        15.5: '15.5',
        25.75: '25.75',
        42.12: '42.12',
        99.99: '99.99',
        123.45: '123.45',
      };

      for (final entry in testValues.entries) {
        expect(formatStatValue(entry.key), equals(entry.value),
            reason: 'Failed to format ${entry.key} correctly');
      }
    });
  });
}
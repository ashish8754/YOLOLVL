import 'lib/services/exp_service.dart';

void main() {
  print('Level 1 threshold: ${EXPService.calculateEXPThreshold(1)}');
  print('Level 2 threshold: ${EXPService.calculateEXPThreshold(2)}');
  print('Level 3 threshold: ${EXPService.calculateEXPThreshold(3)}');
  print('Level 4 threshold: ${EXPService.calculateEXPThreshold(4)}');
  print('Level 5 threshold: ${EXPService.calculateEXPThreshold(5)}');
}
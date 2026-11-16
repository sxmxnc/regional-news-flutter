import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<SelectedTabController, int> selectedTabProvider =
    NotifierProvider<SelectedTabController, int>(SelectedTabController.new);

final class SelectedTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

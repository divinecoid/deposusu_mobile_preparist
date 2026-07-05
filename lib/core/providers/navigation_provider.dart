import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _bottomNavIndex = 0;
  int _packingTabIndex = 0;
  
  bool _filterPrioritas = false;
  bool _filterHariIni = false;

  int get bottomNavIndex => _bottomNavIndex;
  int get packingTabIndex => _packingTabIndex;
  bool get filterPrioritas => _filterPrioritas;
  bool get filterHariIni => _filterHariIni;

  void navigateToPacking(int tabIndex, {bool filterPrioritas = false}) {
    _packingTabIndex = tabIndex;
    _filterPrioritas = filterPrioritas;
    _bottomNavIndex = 1;
    notifyListeners();
  }

  void navigateToHistory({bool filterHariIni = false}) {
    _filterHariIni = filterHariIni;
    _bottomNavIndex = 2;
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    _bottomNavIndex = index;
    // reset filters when manually switching tabs via bottom nav
    if (index != 1) _filterPrioritas = false;
    if (index != 2) _filterHariIni = false;
    notifyListeners();
  }
}

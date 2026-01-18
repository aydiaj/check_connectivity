import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    InternetConnection? internetConnection,
  }) : _connectivity = connectivity ?? Connectivity(),
       _internetConnection =
           internetConnection ?? InternetConnection();

  final Connectivity _connectivity;
  final InternetConnection _internetConnection;

  Future<bool> hasInterfaceNow() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Stream<bool> interfaceChanges() {
    return _connectivity.onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none),
    );
  }

  Future<bool> hasInternetNow() async {
    return _internetConnection.hasInternetAccess;
    // If your version doesn't support hasInternetAccess:
    // return InternetConnectionCheckerPlus().hasConnection;
  }

  Stream<InternetStatus> internetStatusChanges() {
    return _internetConnection.onStatusChange;
  }
}

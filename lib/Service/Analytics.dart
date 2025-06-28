import '../../Library/RestClient.dart';
import '../../Library/RestClient.dart';

class Analytics {

  Future<void> logEvent(String name, Map<String, String> param) async {
    final currentUser = await RestClient().getCurrentUser();
    final email = currentUser['email']?.toString() ?? "N/A";
    final userRole = currentUser['role']?.toString() ?? "N/A"; // Default value or handling if needed
    final userId = currentUser['user_id']?.toString() ?? "N/A";
    param['email'] = email;
    param['user_role'] = userRole;
    param['user_id'] = userId;
    param['key'] = name;
    final returnData = await RestClient().authPost('/student/activity/add', param);
  }

}
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final String accessToken;

  GoogleDriveService(this.accessToken);

  Future<List<drive.File>> listFiles() async {
    final client = authenticatedClient(http.Client(), AccessCredentials(
      AccessToken('Bearer', accessToken, DateTime.now().add(const Duration(hours:1))),
      null, // no refresh token in simple flow
      ['https://www.googleapis.com/auth/drive.readonly'],
    ));
    final api = drive.DriveApi(client);
    final fileList = await api.files.list(q: "trashed=false", pageSize: 50);
    return fileList.files ?? [];
  }
}

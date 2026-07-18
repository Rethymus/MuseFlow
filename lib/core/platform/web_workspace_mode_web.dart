import 'package:web/web.dart' as web;

bool get isTemporaryWebWorkspace =>
    Uri.base.queryParameters['workspace'] == 'temporary';

void switchWebWorkspaceMode({required bool temporary}) {
  final parameters = Map<String, String>.from(Uri.base.queryParameters);
  if (temporary) {
    parameters['workspace'] = 'temporary';
  } else {
    parameters.remove('workspace');
  }
  final target = Uri.base.replace(queryParameters: parameters);
  web.window.location.replace(target.toString());
}

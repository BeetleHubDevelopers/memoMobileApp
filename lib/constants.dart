import 'package:http/http.dart' as http;

const apiBaseUrl =
    "https://main-bvxea6i-7szszldycz7ms.uk-1.platformsh.site/api";
const sharedPrefKeyAccessToken = "access_token";
const sharedPrefKeyDeviceCode = "device_code";
final httpClient = http.Client();

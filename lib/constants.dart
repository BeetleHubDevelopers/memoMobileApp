import 'package:http/http.dart' as http;

const apiBaseUrl = "https://memo-approval-api-30503147f1c7.herokuapp.com/api";
const sharedPrefKeyAccessToken = "access_token";
const sharedPrefKeyDeviceCode = "device_code";
final httpClient = http.Client();
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth/user_data.dart';
import '../models/auth/user_login_model.dart';
import '../models/auth/user_register_model.dart';
import '../models/base_response.dart';

part 'client.g.dart';

@RestApi(
  baseUrl:
  'https://script.google.com/macros/s/AKfycbzvHq06GwL_I8qH2IPyQP36dRlESN62PYF4Ak5WkRE2VjHL5a-tr0Yk_KEtSvU_ZL6IbQ/exec',
)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @POST('')
  Future<BaseResponse<UserData>> loginUser(
    @Query('path') String path,
    @Body() Map<String, dynamic> request,
  );

  @POST('')
  Future<BaseResponse<UserData>> registerUser(
    @Query('path') String path,
    @Body() Map<String, dynamic> request,
  );
}

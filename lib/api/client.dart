import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/user/user_data.dart';
import '../models/base_response.dart';
import '../models/location/city_model.dart';
import '../models/location/state_model.dart';

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

  @GET('')
  Future<BaseResponse<List<StateModel>>> getStates(
      @Query('path') String path,
      );

  @GET('')
  Future<BaseResponse<List<CityModel>>> getCities(
      @Query('path') String path,
      @Query('stateCode') String stateCode,
      );
}

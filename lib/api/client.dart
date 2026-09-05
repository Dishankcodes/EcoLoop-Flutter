import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth/artist/artist_auth_response.dart';
import '../models/auth/artist/artist_login_verify_otp_request.dart';
import '../models/auth/artist/artist_register_verify_otp_request.dart';
import '../models/auth/artist/artist_send_otp_request.dart';
import '../models/auth/artist/artist_send_otp_response.dart';
import '../models/base_response.dart';
import '../models/location/city_model.dart';
import '../models/location/state_model.dart';
import '../models/user/user_data.dart';

part 'client.g.dart';

@RestApi(
  baseUrl:
      'https://script.google.com/macros/s/AKfycbzvHq06GwL_I8qH2IPyQP36dRlESN62PYF4Ak5WkRE2VjHL5a-tr0Yk_KEtSvU_ZL6IbQ/exec',
)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  // ============================================================
  // USER AUTH
  // ============================================================

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

  // ============================================================
  // LOCATION
  // ============================================================

  @GET('')
  Future<BaseResponse<List<StateModel>>> getStates(@Query('path') String path);

  @GET('')
  Future<BaseResponse<List<CityModel>>> getCities(
    @Query('path') String path,
    @Query('stateCode') String stateCode,
  );

  // ============================================================
  // ARTIST REGISTRATION - SEND OTP
  // ============================================================

  @POST('')
  Future<BaseResponse<ArtistSendOtpData>> artistRegisterSendOtp(
    @Query('path') String path,
    @Body() ArtistSendOtpRequest request,
  );

  // ============================================================
  // ARTIST REGISTRATION - VERIFY OTP
  // ============================================================

  @POST('')
  Future<BaseResponse<ArtistAuthResponse>> artistRegisterVerifyOtp(
    @Query('path') String path,
    @Body() ArtistRegisterVerifyOtpRequest request,
  );

  // ============================================================
  // ARTIST LOGIN - SEND OTP
  // ============================================================

  @POST('')
  Future<BaseResponse<ArtistSendOtpData>> artistLoginSendOtp(
    @Query('path') String path,
    @Body() ArtistSendOtpRequest request,
  );

  // ============================================================
  // ARTIST LOGIN - VERIFY OTP
  // ============================================================

  @POST('')
  Future<BaseResponse<ArtistAuthResponse>> artistLoginVerifyOtp(
    @Query('path') String path,
    @Body() ArtistLoginVerifyOtpRequest request,
  );
}

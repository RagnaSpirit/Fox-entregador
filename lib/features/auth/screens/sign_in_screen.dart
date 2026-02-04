import 'package:country_code_picker/country_code_picker.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/helper/custom_validator_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_snackbar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _countryDialCode;
  String? _countryCode;

  @override
  void initState() {
    super.initState();
    _countryDialCode = Get.find<AuthController>().getUserCountryDialCode().isNotEmpty
        ? Get.find<AuthController>().getUserCountryDialCode()
        : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;

    _countryCode = Get.find<AuthController>().getUserCountryCode().isNotEmpty
        ? Get.find<AuthController>().getUserCountryCode()
        : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code;

    _phoneController.text = Get.find<AuthController>().getUserNumber();
    _passwordController.text = Get.find<AuthController>().getUserPassword();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E2D),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: GetBuilder<AuthController>(
              builder: (authController) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Center(
                      child: Image.asset(
                        Images.logo,
                        width: 160,
                      ),
                    ),
                    const SizedBox(height: 48),

                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Entre para continuar',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),

                    CustomTextFieldWidget(
                      hintText: 'Número de telefone',
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      nextFocus: _passwordFocus,
                      inputType: TextInputType.phone,
                      isPhone: true,
                      isRequired: true,
                      onCountryChanged: (CountryCode countryCode) {
                        _countryDialCode = countryCode.dialCode;
                        _countryCode = countryCode.code;
                      },
                      countryDialCode: _countryCode ??
                          CountryCode.fromCountryCode(
                              Get.find<SplashController>().configModel!.country!)
                              .code,
                    ),
                    const SizedBox(height: 20),

                    CustomTextFieldWidget(
                      hintText: 'Senha',
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      inputAction: TextInputAction.done,
                      inputType: TextInputType.visiblePassword,
                      isPassword: true,
                      isRequired: true,
                      onSubmit: (_) => _login(
                        authController,
                        _phoneController,
                        _passwordController,
                        _countryDialCode!,
                        _countryCode!,
                        context,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Checkbox(
                          value: authController.isActiveRememberMe,
                          activeColor: const Color(0xFF00C853),
                          onChanged: (_) => authController.toggleRememberMe(),
                        ),
                        const Text(
                          'Lembrar-me',
                          style: TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Get.toNamed(RouteHelper.getForgotPassRoute()),
                          child: const Text(
                            'Esqueci a senha',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    CustomButtonWidget(
                      buttonText: 'ENTRAR',
                      isLoading: authController.isLoading,
                      onPressed: () => _login(
                        authController,
                        _phoneController,
                        _passwordController,
                        _countryDialCode!,
                        _countryCode!,
                        context,
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (Get.find<SplashController>().configModel!.toggleDmRegistration!)
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Get.toNamed(RouteHelper.getDeliverymanRegistrationRoute()),
                          child: const Text(
                            'Quero me cadastrar',
                            style: TextStyle(
                              color: Color(0xFF00C853),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _login(
      AuthController authController,
      TextEditingController phoneText,
      TextEditingController passText,
      String countryDialCode,
      String countryCode,
      BuildContext context,
      ) async {
    String phone = phoneText.text.trim();
    String password = passText.text.trim();

    String numberWithCountryCode = countryDialCode + phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if (phone.isEmpty) {
      showCustomSnackBar('Informe o telefone');
    } else if (!phoneValid.isValid) {
      showCustomSnackBar('Telefone inválido');
    } else if (password.isEmpty) {
      showCustomSnackBar('Informe a senha');
    } else if (password.length < 6) {
      showCustomSnackBar('Senha muito curta');
    } else {
      authController.login(numberWithCountryCode, password).then((status) async {
        if (status.isSuccess) {
          if (authController.isActiveRememberMe) {
            authController.saveUserNumberAndPassword(
              phone,
              password,
              countryDialCode,
              countryCode,
            );
          } else {
            authController.clearUserNumberAndPassword();
          }
          await Get.find<ProfileController>().getProfile();
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else {
          showCustomSnackBar(status.message);
        }
      });
    }
  }
}

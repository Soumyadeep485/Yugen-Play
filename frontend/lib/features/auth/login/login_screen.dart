import 'package:flutter/material.dart';

import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppTextField(hintText: "Email", prefixIcon: Icons.email_outlined),

              const SizedBox(height: 20),

              AppTextField(
                hintText: "Password",
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),

              const SizedBox(height: 32),

              PrimaryButton(
                text: "Continue",
                onPressed: () {
                  debugPrint("Login Clicked");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

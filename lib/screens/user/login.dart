import 'package:flutter/material.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({super.key, required this.title});

  final String title;

  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),

      body: Scrollbar(
        thumbVisibility: true,

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              const SizedBox(height: 40),

              const Icon(Icons.account_circle, size: 120, color: Colors.green),

              const SizedBox(height: 30),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Login Button Clicked")),
                    );
                  },
                  child: const Text("Login"),
                ),
              ),

              TextButton(
                onPressed: () {
                  // Navigate to Register Page later
                },
                child: const Text("Create Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/config/app_config.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn({required bool create}) async {
    final l10n = AppLocalizations.of(context)!;
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.length < 8) {
      setState(() => error = l10n.authInvalid);
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final client = Supabase.instance.client;
      if (create) {
        await client.auth.signUp(email: email, password: password);
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!AppConfig.hasSupabase) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.account)),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.supabaseRequired),
        )),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.accountDescription,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.email,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.password,
              border: const OutlineInputBorder(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : () => _signIn(create: true),
            child: Text(l10n.createAccount),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: loading ? null : () => _signIn(create: false),
            child: Text(l10n.signIn),
          ),
        ],
      ),
    );
  }
}

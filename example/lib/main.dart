import 'package:flutter/material.dart';
import 'package:ai_smart_translate/ai_smart_translate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AiSmartTranslate.init(
    geminiKey: 'YOUR_GEMINI_KEY',   // https://aistudio.google.com
    groqKey: 'YOUR_GROQ_KEY',       // optional fallback
  );

  runApp(
    // Wrap app with TranslationScope for automatic .tr rebuilds
    const TranslationScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AiSmartTranslate Demo',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _languages = {
    'en': 'English',
    'hi': 'Hindi',
    'ar': 'Arabic',
    'fr': 'French',
    'es': 'Spanish',
  };

  // Simulated API content
  String _apiContent = 'This is a post from the server.';
  String _translatedContent = 'This is a post from the server.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // .tr on any string — auto translates + rebuilds via TranslationScope
        title: Text('Welcome'.tr),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Static UI strings — use .tr
            Text('Hello, User!'.tr,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text('Settings'.tr),
            Text('Profile'.tr),
            Text('Logout'.tr),

            const Divider(height: 32),

            // Language switcher
            Text('Select Language:'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _languages.entries.map((e) {
                final isActive = AiSmartTranslate.currentLanguage == e.key;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.blue : null,
                  ),
                  onPressed: () async {
                    await AiSmartTranslate.changeLanguage(e.key);
                    setState(() {});
                  },
                  child: Text(e.value),
                );
              }).toList(),
            ),

            const Divider(height: 32),

            // API / dynamic content — use translateContent
            Text('Post Content (from API):'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_translatedContent),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final translated = await AiSmartTranslate.translateContent(
                    _apiContent);
                setState(() => _translatedContent = translated);
              },
              child: Text('Translate Post'.tr),
            ),

            const Divider(height: 32),

            // Debug info
            Text('Active provider: ${AiSmartTranslate.activeProvider ?? "none"}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/meeting_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/app_initialization_service.dart';
import 'services/error_handler_service.dart';
import 'utils/app_theme.dart';

void main() {
  // 전역 에러 핸들링 설정
  _setupErrorHandling();

  WidgetsFlutterBinding.ensureInitialized();
  // 즉시 앱 실행 - 스플래시 화면 먼저 표시
  runApp(const SullaeApp());
}

/// 전역 에러 핸들링 설정 (Crashlytics 연동)
void _setupErrorHandling() {
  // Flutter 에러 핸들링 → Crashlytics로 전송
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Crashlytics로 에러 전송
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    ErrorHandlerService().handleError(
      details.exception,
      context: 'FlutterError: ${details.library}',
    );
  };

  // 비동기 에러 핸들링 → Crashlytics로 전송
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    ErrorHandlerService().handleError(
      error,
      context: 'PlatformDispatcher',
    );
    return true;
  };

  // Zone 에러 핸들링 (모든 비동기 에러 캐치)
  runZonedGuarded(() {
    // 앱 실행은 main()에서 처리
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
    ErrorHandlerService().handleError(
      error,
      context: 'ZonedGuarded',
    );
  });
}

class SullaeApp extends StatefulWidget {
  const SullaeApp({super.key});

  @override
  State<SullaeApp> createState() => _SullaeAppState();
}

class _SullaeAppState extends State<SullaeApp> {
  bool _servicesInitialized = false;
  AuthProvider? _authProvider;
  MeetingProvider? _meetingProvider;

  @override
  void initState() {
    super.initState();
    // 스플래시 화면이 먼저 표시된 후 서비스 초기화
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Firebase, Remote Config, AdMob, Kakao SDK 초기화
    await AppInitializationService().initialize();

    // Provider 생성 (Firebase 초기화 후)
    _authProvider = AuthProvider();
    _meetingProvider = MeetingProvider();

    if (mounted) {
      setState(() {
        _servicesInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 서비스 초기화 전: 스플래시 화면
    if (!_servicesInitialized) {
      return MaterialApp(
        title: '술래',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _SplashScreen(),
      );
    }

    // 서비스 초기화 완료: Provider와 함께 앱 시작
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider!),
        ChangeNotifierProvider.value(value: _meetingProvider!),
      ],
      child: MaterialApp(
        title: '술래',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // 인증 초기화 중: 스플래시 화면 유지
            if (!authProvider.isInitialized) {
              return const _SplashScreen();
            }
            // 로그인 완료: 홈 화면
            if (authProvider.isLoggedIn) {
              return const HomeScreen();
            }
            // 미로그인: 로그인 화면
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

/// 스플래시 화면 (자동 로그인 확인 중)
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _runnerController;
  late AnimationController _bounceController;
  late AnimationController _textController;
  late Animation<double> _runnerAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _textFadeAnimation;

  final List<String> _loadingTexts = [
    '술래가 오고 있어요...',
    '도망칠 준비 되셨나요?',
    '누가 술래일까요?',
    '숨을 곳을 찾는 중...',
    '게임 준비 중...',
  ];
  int _currentTextIndex = 0;

  @override
  void initState() {
    super.initState();

    // 달리는 캐릭터 애니메이션 (왼쪽에서 오른쪽으로)
    _runnerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _runnerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _runnerController, curve: Curves.easeInOut),
    );
    _runnerController.repeat();

    // 로고 바운스 애니메이션
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _bounceController.forward();

    // 텍스트 페이드 애니메이션
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textFadeAnimation = Tween<double>(begin: 0, end: 1).animate(_textController);
    _textController.forward();

    // 텍스트 변경 타이머
    Future.delayed(const Duration(milliseconds: 800), _changeText);
  }

  void _changeText() {
    if (!mounted) return;
    _textController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentTextIndex = (_currentTextIndex + 1) % _loadingTexts.length;
      });
      _textController.forward();
      Future.delayed(const Duration(milliseconds: 1500), _changeText);
    });
  }

  @override
  void dispose() {
    _runnerController.dispose();
    _bounceController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      body: Stack(
        children: [
          // 달리는 캐릭터들 (뒤에서 쫓아오는 연출)
          AnimatedBuilder(
            animation: _runnerAnimation,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: _runnerAnimation.value * screenWidth - 100,
                child: Row(
                  children: [
                    // 도망자
                    Transform.flip(
                      flipX: true,
                      child: const Text(
                        '🏃',
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(width: 30),
                    // 술래 (뒤에서 쫓아옴)
                    Transform.flip(
                      flipX: true,
                      child: const Text(
                        '🏃‍♂️',
                        style: TextStyle(fontSize: 48),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 메인 콘텐츠
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 바운스 로고
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _bounceAnimation.value,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          -20 * (1 - _bounceAnimation.value),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Text(
                            '👀',
                            style: const TextStyle(fontSize: 60),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 앱 이름 (글자 하나씩 바운스)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: const Text(
                        '술래',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // 서브타이틀
                Text(
                  '야외 술래잡기 게임',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 60),

                // 재미있는 로딩 텍스트
                AnimatedBuilder(
                  animation: _textFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _loadingTexts[_currentTextIndex],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 하단 발자국 (장식)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (index * 150)),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value * 0.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '👣',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

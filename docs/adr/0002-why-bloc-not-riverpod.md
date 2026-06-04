# ADR-0002: لماذا Bloc وليس Riverpod؟

## الحالة (Status)
**مقبول** - 2026-06-03

## السياق (Context)
نحتاج لاختيار state management للـ Flutter. الخيارات الرئيسية:
- Bloc / Cubit
- Riverpod
- Provider
- GetX
- Redux

## القرار (Decision)
نستخدم **flutter_bloc** + **Cubit** للحالات البسيطة.

## البدائل (Alternatives Considered)
1. **Riverpod** ❌ - قوي لكن:
   - منحنى تعلم حاد
   - أقل شيوعاً في الفرق
   - Provider-centric أقل تنظيماً
2. **GetX** ❌ - خدمات + state + DI معاً:
   - Spaghetti code
   - صعب الاختبار
   - يعارض Clean Architecture
3. **Provider** ❌ - بسيط جداً لمشروع معقد
4. **Bloc/Cubit** ✅ - مفضل لاختبار + Clean Architecture

## النتائج (Consequences)
### إيجابيات ✅
- **Testability**: `bloc_test` يعطي اختبارات ممتازة
- **Separation of Concerns**: events → states → UI
- **Time-travel debugging**: BlocObserver يلتقط كل تغيير
- **إدماج ممتاز** مع Clean Architecture
- **توثيق شامل** من Felix Angelov
- **Event-driven**: تطابق طبيعي مع Domain

### سلبيات ❌
- Boilerplate أكثر من Riverpod
- 3 ملفات (event, state, bloc) لكل feature

## أمثلة
```dart
// Event
sealed class AuthEvent extends Equatable {
  const AuthEvent();
}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

// State
sealed class AuthState extends Equatable {
  const AuthState();
}
class AuthInitial extends AuthState { const AuthInitial(); }
class AuthLoading extends AuthState { const AuthLoading(); }
class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  
  AuthBloc(this._loginUseCase) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }
  
  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(email: event.email, password: event.password);
    result.fold(
      (failure) => emit(AuthError(failure)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
```

## المراجع
- [Bloc Library](https://bloclibrary.dev/)
- [Flutter State Management](https://docs.flutter.dev/data-and-backend/state-mgmt/options)

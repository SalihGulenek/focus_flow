// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_viewmodel.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AuthViewModel on _AuthViewModelBase, Store {
  Computed<String>? _$displayNameComputed;

  @override
  String get displayName => (_$displayNameComputed ??= Computed<String>(
    () => super.displayName,
    name: '_AuthViewModelBase.displayName',
  )).value;
  Computed<String>? _$greetingComputed;

  @override
  String get greeting => (_$greetingComputed ??= Computed<String>(
    () => super.greeting,
    name: '_AuthViewModelBase.greeting',
  )).value;

  late final _$currentUserAtom = Atom(
    name: '_AuthViewModelBase.currentUser',
    context: context,
  );

  @override
  UserModel? get currentUser {
    _$currentUserAtom.reportRead();
    return super.currentUser;
  }

  @override
  set currentUser(UserModel? value) {
    _$currentUserAtom.reportWrite(value, super.currentUser, () {
      super.currentUser = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_AuthViewModelBase.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorAtom = Atom(
    name: '_AuthViewModelBase.error',
    context: context,
  );

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$isAuthenticatedAtom = Atom(
    name: '_AuthViewModelBase.isAuthenticated',
    context: context,
  );

  @override
  bool get isAuthenticated {
    _$isAuthenticatedAtom.reportRead();
    return super.isAuthenticated;
  }

  @override
  set isAuthenticated(bool value) {
    _$isAuthenticatedAtom.reportWrite(value, super.isAuthenticated, () {
      super.isAuthenticated = value;
    });
  }

  late final _$checkAuthStatusAsyncAction = AsyncAction(
    '_AuthViewModelBase.checkAuthStatus',
    context: context,
  );

  @override
  Future<void> checkAuthStatus() {
    return _$checkAuthStatusAsyncAction.run(() => super.checkAuthStatus());
  }

  late final _$loginAsyncAction = AsyncAction(
    '_AuthViewModelBase.login',
    context: context,
  );

  @override
  Future<bool> login(String email, String password) {
    return _$loginAsyncAction.run(() => super.login(email, password));
  }

  late final _$registerAsyncAction = AsyncAction(
    '_AuthViewModelBase.register',
    context: context,
  );

  @override
  Future<bool> register(String email, String password, String fullName) {
    return _$registerAsyncAction.run(
      () => super.register(email, password, fullName),
    );
  }

  late final _$logoutAsyncAction = AsyncAction(
    '_AuthViewModelBase.logout',
    context: context,
  );

  @override
  Future<void> logout() {
    return _$logoutAsyncAction.run(() => super.logout());
  }

  late final _$updateProfileAsyncAction = AsyncAction(
    '_AuthViewModelBase.updateProfile',
    context: context,
  );

  @override
  Future<void> updateProfile({String? fullName, String? avatarUrl}) {
    return _$updateProfileAsyncAction.run(
      () => super.updateProfile(fullName: fullName, avatarUrl: avatarUrl),
    );
  }

  late final _$_AuthViewModelBaseActionController = ActionController(
    name: '_AuthViewModelBase',
    context: context,
  );

  @override
  void clearError() {
    final _$actionInfo = _$_AuthViewModelBaseActionController.startAction(
      name: '_AuthViewModelBase.clearError',
    );
    try {
      return super.clearError();
    } finally {
      _$_AuthViewModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
currentUser: ${currentUser},
isLoading: ${isLoading},
error: ${error},
isAuthenticated: ${isAuthenticated},
displayName: ${displayName},
greeting: ${greeting}
    ''';
  }
}

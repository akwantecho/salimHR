import 'package:flutter/foundation.dart' show debugPrint, Uint8List;
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_document.dart';

import 'dart:async';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/notification.dart';
import '../../models/user.dart';
import '../../services/api_config.dart';
import '../../services/api_provider.dart';
import '../app_state.dart';
import '../i18n.dart';
import '../ui/blocks.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<UserRole> onRoleSelected;
  final ValueChanged<String> onLangChange;
  final String currentLang;

  const LoginScreen({
    super.key,
    required this.onRoleSelected,
    required this.onLangChange,
    required this.currentLang,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Determine the appropriate UserRole from the user's roles and permissions
  static UserRole _detectRole(User user) {
    // Admin/Manager role → manager view
    if (user.isManager || user.hasRole('Admin') || user.hasRole('Manager')) {
      return UserRole.manager;
    }
    // Reception role → reception (front desk) view
    if (user.hasRole('Receptionist')) {
      return UserRole.reception;
    }
    // Specialist role → specialist view
    if (user.hasRole('Specialist') || user.hasPermission('patients.manage')) {
      return UserRole.specialist;
    }
    // Default → worker view
    return UserRole.worker;
  }

  Future<void> _handleLogin() async {
    // Validate inputs
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = widget.currentLang == 'en'
            ? 'Please enter email and password'
            : 'الرجاء إدخال البريد وكلمة المرور';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.authService;
      final apiClient = context.apiClient;
      final pushService = context.firebasePushService;
      final success = await authService.login(email, password);

      if (!mounted) return;

      if (success) {
        final user = authService.currentUser;
        final role = _detectRole(user!);

        // Save role to storage for session persistence
        await apiClient.setRole(role.name);

        // Initialize and register FCM token for push notifications
        pushService.initialize().then((_) => pushService.registerToken());

        widget.onRoleSelected(role);
      } else {
        setState(() {
          _errorMessage =
              authService.error ??
              (widget.currentLang == 'en'
                  ? 'Login failed. Please try again.'
                  : 'فشل تسجيل الدخول. حاول مرة أخرى.');
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = widget.currentLang == 'en'
            ? 'Connection error. Check your network.'
            : 'خطأ في الاتصال. تحقق من الشبكة.';
        _isLoading = false;
      });
    }
  }

  /// Demo login — enters the app with the chosen role without a backend server.
  /// Turns on demo mode so all API calls are served from local mock data, and
  /// sets a local demo user so screens that read the current user work.
  /// Useful for previewing/editing the UI while the API is unavailable.
  void _handleDemoLogin(UserRole role) {
    ApiConfig.demoMode = true;
    context.authService.setDemoUser(
      User(
        id: 1,
        name: role == UserRole.manager
            ? 'مدير تجريبي'
            : role == UserRole.specialist
            ? 'أخصائي تجريبي'
            : 'موظف تجريبي',
        email: 'demo@salim.app',
        phone: '+968 9123 4567',
        employeeId: 1042,
        roles: const ['Specialist'],
        clinicName: 'مركز سالم للعلاج الطبيعي',
        createdAt: DateTime(2023, 3, 1),
      ),
    );
    widget.onRoleSelected(role);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final isArabic = widget.currentLang != 'en';
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Container(
      color: const Color(0xFF003C4B),
      child: Stack(
        children: [
          // Logo pattern background
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const logoSize = 60.0;
                  const spacing = 20.0;
                  final cols =
                      (constraints.maxWidth / (logoSize + spacing)).ceil() + 1;
                  final rows =
                      (constraints.maxHeight / (logoSize + spacing)).ceil() + 1;
                  return ClipRect(
                    child: Stack(
                      children: [
                        for (int r = 0; r < rows; r++)
                          for (int c = 0; c < cols; c++)
                            Positioned(
                              left:
                                  c * (logoSize + spacing) +
                                  (r.isOdd ? (logoSize + spacing) / 2 : 0),
                              top: r * (logoSize + spacing),
                              child: Image.asset(
                                'assets/logo/salimhr bg.png',
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/logo/salimhr bg.png',
                        width: ds.spacing.xl * 3.5,
                        height: ds.spacing.xl * 3.5,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: ds.spacing.md),
                      DSText(
                        t('نظام ادارة الموظفين', 'Salim HR'),
                        role: DSTextRole.display,
                        color: const Color(0xFFFFFFFF),
                      ),
                      SizedBox(height: ds.spacing.xs),
                      DSText(
                        t(
                          'إدارة متكاملة للعيادات',
                          'Complete Clinic Management',
                        ),
                        role: DSTextRole.caption,
                        color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                      ),
                      SizedBox(height: ds.spacing.xl),

                      // Login Card
                      DSCard(
                        padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                        shadows: ds.shadows.floating,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                DSText(
                                  t('تسجيل الدخول', 'Sign In'),
                                  role: DSTextRole.headline,
                                ),
                                _LangSwitcher(
                                  isArabic: isArabic,
                                  onSwitch: widget.onLangChange,
                                ),
                              ],
                            ),
                            SizedBox(height: ds.spacing.md),

                            // Error Message
                            if (_errorMessage != null) ...[
                              Container(
                                padding: EdgeInsetsDirectional.all(
                                  ds.spacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    ds.radii.medium,
                                  ),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    DSLineIcon(
                                      type: LineIconType.bell,
                                      color: const Color(0xFFEF4444),
                                      size: ds.spacing.md,
                                    ),
                                    SizedBox(width: ds.spacing.sm),
                                    Expanded(
                                      child: DSText(
                                        _errorMessage!,
                                        role: DSTextRole.caption,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: ds.spacing.md),
                            ],

                            // Email Input
                            _FunctionalInput(
                              controller: _emailController,
                              label: t('البريد الإلكتروني', 'Email'),
                              placeholder: 'name@clinic.com',
                              icon: LineIconType.chat,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isLoading,
                            ),
                            SizedBox(height: ds.spacing.md),

                            // Password Input
                            _FunctionalInput(
                              controller: _passwordController,
                              label: t('كلمة المرور', 'Password'),
                              placeholder: '••••••••',
                              icon: LineIconType.bookmark,
                              obscureText: true,
                              keyboardType: TextInputType.visiblePassword,
                              enabled: !_isLoading,
                              onSubmitted: (_) => _handleLogin(),
                            ),
                            SizedBox(height: ds.spacing.lg),
                          ],
                        ),
                      ),
                      SizedBox(height: ds.spacing.md),

                      // Login Button
                      GestureDetector(
                        onTap: _isLoading ? null : _handleLogin,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsetsDirectional.symmetric(
                            vertical: ds.spacing.md,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                              colors: _isLoading
                                  ? [
                                      ds.colors.textMuted,
                                      ds.colors.textMuted.withValues(
                                        alpha: 0.7,
                                      ),
                                    ]
                                  : [
                                      ds.colors.primary,
                                      ds.colors.primary.withValues(alpha: 0.8),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(ds.radii.large),
                            boxShadow: _isLoading
                                ? null
                                : [
                                    BoxShadow(
                                      color: ds.colors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: ds.spacing.md,
                                        height: ds.spacing.md,
                                        child: const _LoadingIndicator(),
                                      ),
                                      SizedBox(width: ds.spacing.sm),
                                      DSText(
                                        t('جاري الدخول...', 'Signing in...'),
                                        role: DSTextRole.title,
                                        color: const Color(0xFFFFFFFF),
                                      ),
                                    ],
                                  )
                                : DSText(
                                    t('تسجيل الدخول', 'Sign In'),
                                    role: DSTextRole.title,
                                    color: const Color(0xFFFFFFFF),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: ds.spacing.lg),

                      // ── Demo login (no server required) ──
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0x33FFFFFF),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: ds.spacing.sm,
                            ),
                            child: DSText(
                              t('دخول تجريبي', 'Demo access'),
                              role: DSTextRole.caption,
                              color: const Color(0xB3FFFFFF),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0x33FFFFFF),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ds.spacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _DemoRoleButton(
                              label: t('أخصائي', 'Specialist'),
                              onTap: () =>
                                  _handleDemoLogin(UserRole.specialist),
                            ),
                          ),
                          SizedBox(width: ds.spacing.sm),
                          Expanded(
                            child: _DemoRoleButton(
                              label: t('مدير', 'Manager'),
                              onTap: () => _handleDemoLogin(UserRole.manager),
                            ),
                          ),
                          SizedBox(width: ds.spacing.sm),
                          Expanded(
                            child: _DemoRoleButton(
                              label: t('موظف', 'Worker'),
                              onTap: () => _handleDemoLogin(UserRole.worker),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ds.spacing.lg),

                      // Footer
                      DSText(
                        t('© 2024 نظام العيادة', '© 2024 Clinic System'),
                        role: DSTextRole.caption,
                        color: ds.colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Demo role button used on the login screen to enter the app without a server.
class _DemoRoleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DemoRoleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(vertical: ds.spacing.md),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(ds.radii.large),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Center(
          child: DSText(
            label,
            role: DSTextRole.label,
            color: const Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}

/// Loading indicator widget
class _LoadingIndicator extends StatefulWidget {
  const _LoadingIndicator();

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Functional text input widget
class _FunctionalInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final LineIconType icon;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _FunctionalInput({
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(label, role: DSTextRole.label, color: ds.colors.textSecondary),
        SizedBox(height: ds.spacing.xs),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                ds.colors.surfaceAlt,
                ds.colors.surfaceAlt.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(ds.radii.large),
            border: Border.all(color: ds.colors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: ds.colors.primary.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: ds.spacing.md,
            vertical: ds.spacing.sm + 2,
          ),
          child: Row(
            children: [
              DSLineIcon(
                type: icon,
                color: ds.colors.primary.withValues(alpha: 0.6),
                size: ds.spacing.md,
              ),
              SizedBox(width: ds.spacing.sm),
              Expanded(
                child: EditableText(
                  controller: controller,
                  focusNode: FocusNode(),
                  style: ds.typography.body.copyWith(
                    color: enabled
                        ? ds.colors.textPrimary
                        : ds.colors.textMuted,
                  ),
                  cursorColor: ds.colors.primary,
                  backgroundCursorColor: ds.colors.textMuted,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  onSubmitted: onSubmitted,
                  readOnly: !enabled,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final UserRole role;

  const NotificationsScreen({
    super.key,
    required this.onBack,
    required this.role,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter =
      'all'; // all, unread, leave_request, payroll_pending, etc.

  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.notificationsService.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final notificationsService = context.notificationsService;
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return ListenableBuilder(
      listenable: notificationsService,
      builder: (context, _) {
        final allNotifications = notificationsService.notifications;
        final unreadCount = notificationsService.unreadCount;
        final todayCount = notificationsService.todayNotifications.length;
        final weekCount = notificationsService.thisWeekNotifications.length;
        final isLoading = notificationsService.isLoading;
        final error = notificationsService.error;

        // Apply filter
        final filteredNotifications = _filterNotifications(allNotifications);

        return Container(
          color: ds.colors.background,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsetsDirectional.all(ds.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  _NotificationHeader(
                    onBack: widget.onBack,
                    unreadCount: unreadCount,
                    onMarkAllRead: () async {
                      await notificationsService.markAllAsRead();
                    },
                  ),
                  SizedBox(height: ds.spacing.lg),

                  // Summary Stats
                  Row(
                    children: [
                      Expanded(
                        child: _NotificationStatCard(
                          title: t('غير مقروء', 'Unread'),
                          value: '$unreadCount',
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      SizedBox(width: ds.spacing.sm),
                      Expanded(
                        child: _NotificationStatCard(
                          title: t('اليوم', 'Today'),
                          value: '$todayCount',
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(width: ds.spacing.sm),
                      Expanded(
                        child: _NotificationStatCard(
                          title: t('هذا الأسبوع', 'This Week'),
                          value: '$weekCount',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ds.spacing.lg),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedFilter = 'all'),
                          child: _NotificationFilterChip(
                            label: t('الكل', 'All'),
                            isSelected: _selectedFilter == 'all',
                          ),
                        ),
                        SizedBox(width: ds.spacing.sm),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFilter = 'unread'),
                          child: _NotificationFilterChip(
                            label: t('غير مقروء', 'Unread'),
                            isSelected: _selectedFilter == 'unread',
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        SizedBox(width: ds.spacing.sm),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFilter = 'leave_request'),
                          child: _NotificationFilterChip(
                            label: t('إجازات', 'Leaves'),
                            isSelected: _selectedFilter == 'leave_request',
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        SizedBox(width: ds.spacing.sm),
                        GestureDetector(
                          onTap: () => setState(
                            () => _selectedFilter = 'payroll_pending',
                          ),
                          child: _NotificationFilterChip(
                            label: t('رواتب', 'Payroll'),
                            isSelected: _selectedFilter == 'payroll_pending',
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        SizedBox(width: ds.spacing.sm),
                        // Specialists see "Bonuses"; other roles see "Inventory".
                        if (widget.role == UserRole.specialist)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _selectedFilter = 'bonus'),
                            child: _NotificationFilterChip(
                              label: t('مكافآت', 'Bonuses'),
                              isSelected: _selectedFilter == 'bonus',
                              color: const Color(0xFF10B981),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => setState(
                              () => _selectedFilter = 'inventory_low',
                            ),
                            child: _NotificationFilterChip(
                              label: t('مخزون', 'Inventory'),
                              isSelected: _selectedFilter == 'inventory_low',
                              color: const Color(0xFF10B981),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: ds.spacing.md),

                  // Error message
                  if (error != null)
                    Container(
                      padding: EdgeInsetsDirectional.all(ds.spacing.sm),
                      margin: EdgeInsetsDirectional.only(bottom: ds.spacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(ds.radii.medium),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          DSLineIcon(
                            type: LineIconType.bell,
                            color: const Color(0xFFEF4444),
                            size: ds.spacing.md,
                          ),
                          SizedBox(width: ds.spacing.sm),
                          Expanded(
                            child: DSText(
                              error,
                              role: DSTextRole.caption,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              notificationsService.clearError();
                              notificationsService.fetchNotifications();
                            },
                            child: DSLineIcon(
                              type: LineIconType.calendar,
                              color: const Color(0xFFEF4444),
                              size: ds.spacing.md,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Notifications List
                  Expanded(
                    child: isLoading && allNotifications.isEmpty
                        ? const ShimmerLoading()
                        : filteredNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DSLineIcon(
                                  type: LineIconType.bell,
                                  color: ds.colors.textMuted,
                                  size: ds.spacing.xl * 2,
                                ),
                                SizedBox(height: ds.spacing.md),
                                DSText(
                                  t('لا توجد إشعارات', 'No notifications'),
                                  role: DSTextRole.title,
                                  color: ds.colors.textSecondary,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredNotifications.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: ds.spacing.sm),
                            itemBuilder: (context, index) {
                              final notification = filteredNotifications[index];
                              return GestureDetector(
                                onTap: () async {
                                  if (!notification.isRead) {
                                    await notificationsService.markAsRead(
                                      notification.id,
                                    );
                                  }
                                },
                                child: Dismissible(
                                  key: Key('notification_${notification.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: AlignmentDirectional.centerEnd,
                                    padding: EdgeInsetsDirectional.only(
                                      end: ds.spacing.lg,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(
                                        ds.radii.large,
                                      ),
                                    ),
                                    child: DSLineIcon(
                                      type: LineIconType.home,
                                      color: const Color(0xFFFFFFFF),
                                      size: ds.spacing.lg,
                                    ),
                                  ),
                                  onDismissed: (_) {
                                    notificationsService.deleteNotification(
                                      notification.id,
                                    );
                                  },
                                  child: _ApiNotificationCard(
                                    notification: notification,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<AppNotification> _filterNotifications(
    List<AppNotification> notifications,
  ) {
    switch (_selectedFilter) {
      case 'unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'leave_request':
        return notifications
            .where((n) => n.type == NotificationType.leaveRequest)
            .toList();
      case 'payroll_pending':
        return notifications
            .where((n) => n.type == NotificationType.payrollPending)
            .toList();
      case 'inventory_low':
        return notifications
            .where((n) => n.type == NotificationType.inventoryLow)
            .toList();
      case 'bonus':
        return notifications
            .where((n) => n.type == NotificationType.bonus)
            .toList();
      case 'medical_excuse':
        return notifications
            .where((n) => n.type == NotificationType.medicalExcuse)
            .toList();
      default:
        return notifications;
    }
  }
}

/// Notification card that displays API notification data
class _ApiNotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _ApiNotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final color = _getColorForType(notification.type);
    final icon = _getIconForType(notification.type);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: notification.isRead
            ? ds.colors.surface
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(
          color: notification.isRead
              ? ds.colors.border
              : color.withValues(alpha: 0.2),
        ),
        boxShadow: !notification.isRead
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(ds.radii.medium),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: DSLineIcon(
                type: icon,
                color: const Color(0xFFFFFFFF),
                size: ds.spacing.md,
              ),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DSText(notification.title, role: DSTextRole.title),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (notification.message != null) ...[
                  SizedBox(height: ds.spacing.xs / 2),
                  DSText(
                    notification.message!,
                    role: DSTextRole.body,
                    color: ds.colors.textSecondary,
                  ),
                ],
                if (notification.imageUrl != null &&
                    notification.imageUrl!.isNotEmpty) ...[
                  SizedBox(height: ds.spacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ds.radii.medium),
                    child: Image.network(
                      notification.imageUrl!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                SizedBox(height: ds.spacing.xs),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: ds.spacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(ds.radii.small),
                      ),
                      child: DSText(
                        _getTypeLabel(notification.type, t),
                        role: DSTextRole.caption,
                        color: color,
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    DSText(
                      _formatTime(notification.createdAt, t),
                      role: DSTextRole.caption,
                      color: ds.colors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.leaveRequest:
        return const Color(0xFF3B82F6); // Blue
      case NotificationType.medicalExcuse:
        return const Color(0xFF8B5CF6); // Violet
      case NotificationType.payrollPending:
        return const Color(0xFFEF4444); // Red
      case NotificationType.inventoryLow:
        return const Color(0xFFF59E0B); // Amber
      case NotificationType.bonus:
        return const Color(0xFF10B981); // Emerald
      case NotificationType.general:
        return const Color(0xFF10B981); // Emerald
    }
  }

  LineIconType _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.leaveRequest:
        return LineIconType.calendar;
      case NotificationType.medicalExcuse:
        return LineIconType.chat;
      case NotificationType.payrollPending:
        return LineIconType.bookmark;
      case NotificationType.inventoryLow:
        return LineIconType.chart;
      case NotificationType.bonus:
        return LineIconType.heart;
      case NotificationType.general:
        return LineIconType.bell;
    }
  }

  String _getTypeLabel(
    NotificationType type,
    String Function(String, String) t,
  ) {
    switch (type) {
      case NotificationType.leaveRequest:
        return t('إجازة', 'Leave');
      case NotificationType.medicalExcuse:
        return t('طبي', 'Medical');
      case NotificationType.payrollPending:
        return t('رواتب', 'Payroll');
      case NotificationType.inventoryLow:
        return t('مخزون', 'Inventory');
      case NotificationType.bonus:
        return t('مكافآت', 'Bonuses');
      case NotificationType.general:
        return t('عام', 'General');
    }
  }

  String _formatTime(DateTime dateTime, String Function(String, String) t) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return t('الآن', 'Just now');
    } else if (diff.inMinutes < 60) {
      return t('منذ ${diff.inMinutes} دقيقة', '${diff.inMinutes} min ago');
    } else if (diff.inHours < 24) {
      return t('منذ ${diff.inHours} ساعة', '${diff.inHours} hour ago');
    } else if (diff.inDays < 7) {
      return t('منذ ${diff.inDays} يوم', '${diff.inDays} days ago');
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _NotificationHeader extends StatelessWidget {
  final VoidCallback onBack;
  final int unreadCount;
  final VoidCallback? onMarkAllRead;

  const _NotificationHeader({
    required this.onBack,
    this.unreadCount = 0,
    this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.xLarge),
        border: Border.all(color: ds.colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: ds.colors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: ds.spacing.xl,
              height: ds.spacing.xl,
              decoration: BoxDecoration(
                color: ds.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ds.radii.medium),
              ),
              child: Center(
                child: DSLineIcon(
                  type: LineIconType.arrowBack,
                  color: ds.colors.primary,
                  size: ds.spacing.md,
                ),
              ),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  t('الإشعارات', 'Notifications'),
                  role: DSTextRole.headline,
                ),
                SizedBox(height: ds.spacing.xs / 2),
                DSText(
                  unreadCount > 0
                      ? t(
                          '$unreadCount إشعارات جديدة',
                          '$unreadCount new notifications',
                        )
                      : t('لا توجد إشعارات جديدة', 'No new notifications'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
          if (unreadCount > 0 && onMarkAllRead != null)
            GestureDetector(
              onTap: onMarkAllRead,
              child: Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.sm,
                  vertical: ds.spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ds.radii.pill),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  ),
                ),
                child: DSText(
                  t('قراءة الكل', 'Read All'),
                  role: DSTextRole.caption,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _NotificationStatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          DSText(value, role: DSTextRole.headline, color: color),
          SizedBox(height: ds.spacing.xs / 2),
          DSText(
            title,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _NotificationFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;

  const _NotificationFilterChip({
    required this.label,
    required this.isSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final chipColor = color ?? ds.colors.primary;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.md,
        vertical: ds.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? chipColor.withValues(alpha: 0.15)
            : ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.pill),
        border: Border.all(color: isSelected ? chipColor : ds.colors.border),
      ),
      child: DSText(
        label,
        role: DSTextRole.label,
        color: isSelected ? chipColor : ds.colors.textSecondary,
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final app = AppScope.of(context);
    final role = app.role;
    final user = context.authService.currentUser;
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    final roleColor = _roleColor(role);
    // Use actual user name from API if available
    final userName = user?.name ?? t('مستخدم', 'User');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [roleColor, roleColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(ds.radii.xLarge),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar (picked image, remote URL, or initials fallback)
                    ProfileAvatar(
                      size: ds.spacing.xl * 2,
                      bytes: context.authService.avatarBytes,
                      avatarUrl: user?.avatarUrl,
                      initials: _initials(userName),
                      background: const Color(0xFFFFFFFF).withValues(alpha: 0.22),
                      foreground: const Color(0xFFFFFFFF),
                      borderColor: const Color(0xFFFFFFFF).withValues(alpha: 0.4),
                    ),
                    SizedBox(width: ds.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DSText(
                            userName,
                            role: DSTextRole.headline,
                            color: const Color(0xFFFFFFFF),
                          ),
                          SizedBox(height: ds.spacing.xs),
                          Wrap(
                            spacing: ds.spacing.xs,
                            runSpacing: ds.spacing.xs,
                            children: [
                              _HeaderPill(
                                label: _roleName(
                                  role,
                                  isEn: app.locale.languageCode == 'en',
                                ),
                              ),
                              if (user?.employeeId != null)
                                _HeaderPill(
                                  label: t(
                                    'رقم الموظف ${user!.employeeId}',
                                    'ID ${user.employeeId}',
                                  ),
                                ),
                            ],
                          ),
                          if (user?.clinicName != null) ...[
                            SizedBox(height: ds.spacing.xs),
                            DSText(
                              user!.clinicName!,
                              role: DSTextRole.caption,
                              color: const Color(
                                0xFFFFFFFF,
                              ).withValues(alpha: 0.85),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ds.spacing.lg),

              // Account info
              SectionHeader(title: t('بيانات الحساب', 'Account Information')),
              _AccountInfoCard(
                rows: [
                  _AccountInfo(
                    icon: LineIconType.chat,
                    label: t('البريد الإلكتروني', 'Email'),
                    value: user?.email ?? '-',
                    color: const Color(0xFF10B981),
                  ),
                  _AccountInfo(
                    icon: LineIconType.bell,
                    label: t('رقم الجوال', 'Phone'),
                    value: user?.phone ?? t('غير مضاف', 'Not set'),
                    color: const Color(0xFF3B82F6),
                  ),
                  _AccountInfo(
                    icon: LineIconType.bookmark,
                    label: t('رقم الموظف', 'Employee ID'),
                    value: user?.employeeId != null ? '${user!.employeeId}' : '-',
                    color: const Color(0xFF8B5CF6),
                  ),
                  _AccountInfo(
                    icon: LineIconType.calendar,
                    label: t('عضو منذ', 'Member since'),
                    value: user?.createdAt != null
                        ? '${user!.createdAt!.year}'
                        : '-',
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              // Menu Items
              SectionHeader(title: t('الإعدادات', 'Settings')),
              _ProfileMenuItem(
                title: t('تعديل الملف الشخصي', 'Edit Profile'),
                subtitle: t('الاسم، البريد', 'Name, email'),
                icon: LineIconType.bookmark,
                color: const Color(0xFF6366F1),
                onTap: () => app.showProfileSub(ProfileSubScreen.editProfile),
              ),
              SizedBox(height: ds.spacing.sm),
              _ProfileMenuItem(
                title: t('مستنداتي', 'My Documents'),
                subtitle: t('البطاقات والشهادات', 'Cards & certificates'),
                icon: LineIconType.chart,
                color: const Color(0xFF06B6D4),
                onTap: () => app.showProfileSub(ProfileSubScreen.documents),
              ),
              SizedBox(height: ds.spacing.sm),
              _ProfileMenuItem(
                title: t('الإشعارات', 'Notifications'),
                subtitle: t('عرض جميع الإشعارات', 'View all notifications'),
                icon: LineIconType.bell,
                color: const Color(0xFF3B82F6),
                onTap: () => app.showNotifications(),
              ),
              SizedBox(height: ds.spacing.sm),
              _LanguageSwitchCard(
                isArabic: app.locale.languageCode != 'en',
                onSwitch: app.setLocale,
              ),
              SizedBox(height: ds.spacing.sm),
              _ProfileMenuItem(
                title: t('الأمان', 'Security'),
                subtitle: t('تغيير كلمة المرور', 'Change password'),
                icon: LineIconType.home,
                color: const Color(0xFF14B8A6),
                onTap: () =>
                    app.showProfileSub(ProfileSubScreen.changePassword),
              ),
              SizedBox(height: ds.spacing.lg),

              // Support Section
              SectionHeader(title: t('الدعم', 'Support')),
              _ProfileMenuItem(
                title: t('حول التطبيق', 'About App'),
                subtitle: t(
                  'الإصدار والشروط والخصوصية',
                  'Version, terms & privacy',
                ),
                icon: LineIconType.heart,
                color: const Color(0xFF6366F1),
                onTap: () => app.showProfileSub(ProfileSubScreen.about),
              ),
              SizedBox(height: ds.spacing.lg),

              // Logout Button
              GestureDetector(
                onTap: () {
                  // Unregister FCM token before logout
                  context.firebasePushService.unregisterToken();
                  // Logout from API and clear local state
                  context.authService.logout();
                  app.logout();
                },
                child: Container(
                  padding: EdgeInsetsDirectional.all(ds.spacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ds.radii.large),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DSLineIcon(
                        type: LineIconType.home,
                        color: const Color(0xFFEF4444),
                        size: ds.spacing.lg,
                      ),
                      SizedBox(width: ds.spacing.sm),
                      DSText(
                        t('تسجيل الخروج', 'Logout'),
                        role: DSTextRole.title,
                        color: const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: ds.spacing.lg),
            ],
          ),
        ),
      ],
    );
  }

  Color _roleColor(UserRole? role) {
    switch (role) {
      case UserRole.manager:
        return const Color(0xFF6366F1); // Indigo
      case UserRole.worker:
        return const Color(0xFF10B981); // Emerald
      case UserRole.specialist:
        return const Color(0xFFF59E0B); // Amber
      case UserRole.reception:
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _roleName(UserRole? role, {bool isEn = false}) {
    switch (role) {
      case UserRole.manager:
        return isEn ? 'Manager' : 'مدير';
      case UserRole.worker:
        return isEn ? 'Worker' : 'موظف';
      case UserRole.specialist:
        return isEn ? 'Specialist' : 'أخصائي';
      case UserRole.reception:
        return isEn ? 'Reception' : 'استقبال';
      default:
        return isEn ? 'Unset' : 'غير محدد';
    }
  }

  /// Up to two initials from the user's name for the avatar.
  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.characters.first;
    return parts.first.characters.first + parts.elementAt(1).characters.first;
  }
}

/// Circular profile avatar. Prefers a locally-picked image, then a remote
/// [avatarUrl]; falls back to the user's initials on a colored circle.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final Uint8List? bytes;
  final String? avatarUrl;
  final String initials;
  final Color background;
  final Color foreground;
  final Color? borderColor;

  const ProfileAvatar({
    super.key,
    required this.size,
    required this.initials,
    this.bytes,
    this.avatarUrl,
    required this.background,
    required this.foreground,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (bytes != null) {
      content = Image.memory(bytes!, width: size, height: size, fit: BoxFit.cover);
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      content = Image.network(
        avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialsView(),
      );
    } else {
      content = _initialsView();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
      ),
      child: ClipOval(child: content),
    );
  }

  Widget _initialsView() {
    return Container(
      color: background,
      alignment: Alignment.center,
      child: DSText(initials, role: DSTextRole.display, color: foreground),
    );
  }
}

/// Small translucent pill used in the profile header for role / ID chips.
class _HeaderPill extends StatelessWidget {
  final String label;

  const _HeaderPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.sm,
        vertical: ds.spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ds.radii.pill),
      ),
      child: DSText(
        label,
        role: DSTextRole.caption,
        color: const Color(0xFFFFFFFF),
      ),
    );
  }
}

/// One labelled row inside the account-information card.
class _AccountInfo {
  final LineIconType icon;
  final String label;
  final String value;
  final Color color;

  const _AccountInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Professional account-information card: a list of icon + label + value rows.
class _AccountInfoCard extends StatelessWidget {
  final List<_AccountInfo> rows;

  const _AccountInfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: EdgeInsetsDirectional.symmetric(
                  vertical: ds.spacing.sm,
                ),
                color: ds.colors.border.withValues(alpha: 0.5),
              ),
            Row(
              children: [
                Container(
                  width: ds.spacing.xl,
                  height: ds.spacing.xl,
                  decoration: BoxDecoration(
                    color: rows[i].color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(ds.radii.medium),
                  ),
                  child: Center(
                    child: DSLineIcon(
                      type: rows[i].icon,
                      color: rows[i].color,
                      size: ds.spacing.md,
                    ),
                  ),
                ),
                SizedBox(width: ds.spacing.md),
                Expanded(
                  child: DSText(
                    rows[i].label,
                    role: DSTextRole.caption,
                    color: ds.colors.textSecondary,
                  ),
                ),
                Flexible(
                  child: DSText(
                    rows[i].value,
                    role: DSTextRole.label,
                    color: ds.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


class _LanguageSwitchCard extends StatelessWidget {
  final bool isArabic;
  final ValueChanged<String> onSwitch;

  const _LanguageSwitchCard({required this.isArabic, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: Center(
              child: DSLineIcon(
                type: LineIconType.chart,
                color: const Color(0xFF8B5CF6),
                size: ds.spacing.md,
              ),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(t('اللغة', 'Language'), role: DSTextRole.title),
                SizedBox(height: ds.spacing.xs / 2),
                DSText(
                  t('اختر لغة التطبيق', 'Choose app language'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
          // Language Toggle
          Container(
            decoration: BoxDecoration(
              color: ds.colors.surfaceAlt,
              borderRadius: BorderRadius.circular(ds.radii.pill),
              border: Border.all(color: ds.colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onSwitch('ar'),
                  child: AnimatedContainer(
                    duration: ds.animation.fast,
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: ds.spacing.md,
                      vertical: ds.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isArabic
                          ? ds.colors.primary.withValues(alpha: 0.12)
                          : ds.colors.surface.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(ds.radii.pill),
                    ),
                    child: DSText(
                      'عربي',
                      role: DSTextRole.label,
                      color: isArabic
                          ? ds.colors.primary
                          : ds.colors.textSecondary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onSwitch('en'),
                  child: AnimatedContainer(
                    duration: ds.animation.fast,
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: ds.spacing.md,
                      vertical: ds.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: !isArabic
                          ? ds.colors.primary.withValues(alpha: 0.12)
                          : ds.colors.surface.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(ds.radii.pill),
                    ),
                    child: DSText(
                      'EN',
                      role: DSTextRole.label,
                      color: !isArabic
                          ? ds.colors.primary
                          : ds.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final LineIconType icon;
  final Color color;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.all(ds.spacing.md),
        decoration: BoxDecoration(
          color: ds.colors.surface,
          borderRadius: BorderRadius.circular(ds.radii.large),
          border: Border.all(color: ds.colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: ds.spacing.xl,
              height: ds.spacing.xl,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ds.radii.medium),
              ),
              child: Center(
                child: DSLineIcon(
                  type: icon,
                  color: color,
                  size: ds.spacing.md,
                ),
              ),
            ),
            SizedBox(width: ds.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText(title, role: DSTextRole.title),
                  SizedBox(height: ds.spacing.xs / 2),
                  DSText(
                    subtitle,
                    role: DSTextRole.caption,
                    color: ds.colors.textSecondary,
                  ),
                ],
              ),
            ),
            DSLineIcon(
              type: LineIconType.calendar,
              color: ds.colors.textMuted,
              size: ds.spacing.md,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PROFILE SUB-SCREENS ====================

class _SubScreenShell extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final Widget child;

  const _SubScreenShell({
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.all(ds.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsetsDirectional.all(ds.spacing.md),
                decoration: BoxDecoration(
                  color: ds.colors.surface,
                  borderRadius: BorderRadius.circular(ds.radii.xLarge),
                  border: Border.all(
                    color: ds.colors.border.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ds.colors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: ds.spacing.xl,
                        height: ds.spacing.xl,
                        decoration: BoxDecoration(
                          color: ds.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(ds.radii.medium),
                        ),
                        child: Center(
                          child: DSLineIcon(
                            type: LineIconType.arrowBack,
                            color: ds.colors.primary,
                            size: ds.spacing.md,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ds.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DSText(title, role: DSTextRole.headline),
                          SizedBox(height: ds.spacing.xs / 2),
                          DSText(
                            subtitle,
                            role: DSTextRole.caption,
                            color: ds.colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ds.spacing.lg),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final VoidCallback onBack;

  const EditProfileScreen({super.key, required this.onBack});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _avatarBytes;
  String? _message;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    final user = context.authService.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _avatarBytes = context.authService.avatarBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _avatarInitials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.characters.first;
    return parts.first.characters.first + parts.elementAt(1).characters.first;
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _avatarBytes = bytes);
      final auth = context.authService;
      auth.setAvatarBytes(bytes);
      // Upload to the server in the background; the local preview shows meanwhile.
      auth.uploadAvatar(bytes, filename: file.name);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSuccess = false;
        _message = tr(
          context,
          ar: 'تعذّر اختيار الصورة',
          en: 'Could not pick image',
        );
      });
    }
  }

  Future<void> _save() async {
    final authService = context.authService;
    final success = await authService.updateProfile(
      name: _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _isSuccess = success;
      _message = success
          ? tr(
              context,
              ar: 'تم تحديث الملف الشخصي',
              en: 'Profile updated successfully',
            )
          : (authService.error ??
                tr(context, ar: 'فشل التحديث', en: 'Update failed'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final authService = context.watchAuth;
    final user = authService.currentUser;
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return _SubScreenShell(
      onBack: widget.onBack,
      title: t('تعديل الملف الشخصي', 'Edit Profile'),
      subtitle: t('تعديل بياناتك الشخصية', 'Update your personal info'),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar picker
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ProfileAvatar(
                          size: ds.spacing.xxxl * 2,
                          bytes: _avatarBytes,
                          avatarUrl: user?.avatarUrl,
                          initials: _avatarInitials(
                            _nameController.text.trim().isNotEmpty
                                ? _nameController.text
                                : (user?.name ?? ''),
                          ),
                          background: ds.colors.primary,
                          foreground: const Color(0xFFFFFFFF),
                        ),
                        // Camera badge
                        PositionedDirectional(
                          bottom: 0,
                          end: 0,
                          child: Container(
                            padding: EdgeInsetsDirectional.all(ds.spacing.xs),
                            decoration: BoxDecoration(
                              color: ds.colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ds.colors.background,
                                width: 2,
                              ),
                            ),
                            child: SizedBox(
                              width: ds.spacing.md,
                              height: ds.spacing.md,
                              child: Center(
                                child: DSText(
                                  '+',
                                  role: DSTextRole.title,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: ds.spacing.sm),
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: DSText(
                      _avatarBytes != null
                          ? t('تغيير الصورة', 'Change photo')
                          : t('إضافة صورة', 'Add photo'),
                      role: DSTextRole.label,
                      color: ds.colors.primary,
                    ),
                  ),
                ),
                SizedBox(height: ds.spacing.lg),
                _FunctionalInput(
                  controller: _nameController,
                  label: t('الاسم', 'Name'),
                  placeholder: t('أدخل اسمك', 'Enter your name'),
                  icon: LineIconType.bookmark,
                ),
                SizedBox(height: ds.spacing.md),
                // Email (read-only)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(
                      t('البريد الإلكتروني', 'Email'),
                      role: DSTextRole.label,
                      color: ds.colors.textSecondary,
                    ),
                    SizedBox(height: ds.spacing.xs),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsetsDirectional.all(ds.spacing.md),
                      decoration: BoxDecoration(
                        color: ds.colors.surfaceAlt.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(ds.radii.large),
                        border: Border.all(color: ds.colors.border),
                      ),
                      child: Row(
                        children: [
                          DSLineIcon(
                            type: LineIconType.chat,
                            color: ds.colors.textMuted,
                            size: ds.spacing.md,
                          ),
                          SizedBox(width: ds.spacing.sm),
                          Expanded(
                            child: DSText(
                              user?.email ?? '-',
                              role: DSTextRole.body,
                              color: ds.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ds.spacing.lg),
                if (_message != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.all(ds.spacing.sm),
                    decoration: BoxDecoration(
                      color:
                          (_isSuccess
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ds.radii.medium),
                    ),
                    child: DSText(
                      _message!,
                      role: DSTextRole.caption,
                      color: _isSuccess
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(height: ds.spacing.md),
                ],
                GestureDetector(
                  onTap: authService.isLoading ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.all(ds.spacing.md),
                    decoration: BoxDecoration(
                      color: ds.colors.primary,
                      borderRadius: BorderRadius.circular(ds.radii.large),
                    ),
                    child: Center(
                      child: DSText(
                        authService.isLoading
                            ? t('جاري الحفظ...', 'Saving...')
                            : t('حفظ التغييرات', 'Save Changes'),
                        role: DSTextRole.title,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ChangePasswordScreen({super.key, required this.onBack});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_newController.text != _confirmController.text) {
      setState(() {
        _isSuccess = false;
        _message = t(
          'كلمة المرور الجديدة غير متطابقة',
          'New passwords do not match',
        );
      });
      return;
    }
    if (_newController.text.length < 8) {
      setState(() {
        _isSuccess = false;
        _message = t(
          'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
          'Password must be at least 8 characters',
        );
      });
      return;
    }

    final authService = context.authService;
    final success = await authService.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      confirmPassword: _confirmController.text,
    );
    if (!mounted) return;
    setState(() {
      _isSuccess = success;
      _message = success
          ? t('تم تغيير كلمة المرور', 'Password changed successfully')
          : (authService.error ??
                t('فشل تغيير كلمة المرور', 'Password change failed'));
    });
    if (success) {
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final authService = context.watchAuth;
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return _SubScreenShell(
      onBack: widget.onBack,
      title: t('الأمان', 'Security'),
      subtitle: t('تغيير كلمة المرور', 'Change your password'),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FunctionalInput(
                  controller: _currentController,
                  label: t('كلمة المرور الحالية', 'Current Password'),
                  placeholder: t(
                    'أدخل كلمة المرور الحالية',
                    'Enter current password',
                  ),
                  icon: LineIconType.home,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                ),
                SizedBox(height: ds.spacing.md),
                _FunctionalInput(
                  controller: _newController,
                  label: t('كلمة المرور الجديدة', 'New Password'),
                  placeholder: t(
                    'أدخل كلمة المرور الجديدة',
                    'Enter new password',
                  ),
                  icon: LineIconType.home,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                ),
                SizedBox(height: ds.spacing.md),
                _FunctionalInput(
                  controller: _confirmController,
                  label: t('تأكيد كلمة المرور', 'Confirm Password'),
                  placeholder: t('أعد إدخال كلمة المرور', 'Re-enter password'),
                  icon: LineIconType.home,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                ),
                SizedBox(height: ds.spacing.lg),
                if (_message != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.all(ds.spacing.sm),
                    decoration: BoxDecoration(
                      color:
                          (_isSuccess
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ds.radii.medium),
                    ),
                    child: DSText(
                      _message!,
                      role: DSTextRole.caption,
                      color: _isSuccess
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(height: ds.spacing.md),
                ],
                GestureDetector(
                  onTap: authService.isLoading ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.all(ds.spacing.md),
                    decoration: BoxDecoration(
                      color: ds.colors.primary,
                      borderRadius: BorderRadius.circular(ds.radii.large),
                    ),
                    child: Center(
                      child: DSText(
                        authService.isLoading
                            ? t('جاري الحفظ...', 'Saving...')
                            : t('تغيير كلمة المرور', 'Change Password'),
                        role: DSTextRole.title,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AboutAppScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final VoidCallback onDeleteAccount;

  const AboutAppScreen({
    super.key,
    required this.onBack,
    required this.onPrivacy,
    required this.onTerms,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return _SubScreenShell(
      onBack: onBack,
      title: t('حول التطبيق', 'About App'),
      subtitle: t('معلومات التطبيق والشروط', 'App info & policies'),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: ds.spacing.lg),
                // Logo
                Image.asset(
                  'assets/logo/salimhr bg.png',
                  width: ds.spacing.xl * 4,
                  height: ds.spacing.xl * 4,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: ds.spacing.md),
                DSText(
                  t('نظام ادارة الموظفين', 'Salim HR'),
                  role: DSTextRole.headline,
                ),
                SizedBox(height: ds.spacing.xs),
                DSText(
                  t('الإصدار 1.0.0', 'Version 1.0.0'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
                SizedBox(height: ds.spacing.xs),
                DSText(
                  t('إدارة متكاملة للعيادات', 'Complete Clinic Management'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
                SizedBox(height: ds.spacing.xl),
                // Menu Items
                _ProfileMenuItem(
                  title: t('سياسة الخصوصية', 'Privacy Policy'),
                  subtitle: t('كيف نحمي بياناتك', 'How we protect your data'),
                  icon: LineIconType.home,
                  color: const Color(0xFF3B82F6),
                  onTap: onPrivacy,
                ),
                SizedBox(height: ds.spacing.sm),
                _ProfileMenuItem(
                  title: t('شروط الاستخدام', 'Terms of Service'),
                  subtitle: t('شروط وأحكام التطبيق', 'App terms & conditions'),
                  icon: LineIconType.calendar,
                  color: const Color(0xFF10B981),
                  onTap: onTerms,
                ),
                SizedBox(height: ds.spacing.xl),
                // Delete Account
                GestureDetector(
                  onTap: onDeleteAccount,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.all(ds.spacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ds.radii.large),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DSLineIcon(
                          type: LineIconType.heart,
                          color: const Color(0xFFEF4444),
                          size: ds.spacing.md,
                        ),
                        SizedBox(width: ds.spacing.sm),
                        DSText(
                          t('حذف الحساب', 'Delete Account'),
                          role: DSTextRole.title,
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: ds.spacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  final VoidCallback onBack;

  const PrivacyPolicyScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final isEn = AppScope.of(context).locale.languageCode == 'en';
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    final content = isEn
        ? '''Privacy Policy for Salim HR

Last Updated: February 2026

1. Information We Collect
We collect personal information you provide when creating an account, including your name, email address, and employment details. We also collect usage data to improve our services.

2. How We Use Your Information
Your information is used to:
- Provide and maintain our clinic management services
- Process payroll and HR operations
- Send notifications about your account
- Improve and personalize the app experience

3. Data Storage and Security
Your data is stored securely on our servers. We use industry-standard encryption to protect your personal information during transmission and storage.

4. Data Sharing
We do not sell your personal information. We may share data with:
- Your clinic administrator for HR management purposes
- Service providers who assist in operating our platform

5. Your Rights
You have the right to:
- Access your personal data
- Correct inaccurate data
- Request deletion of your account and data
- Export your data

6. Data Retention
We retain your data for as long as your account is active. Upon account deletion, your personal data will be permanently removed within 30 days.

7. Contact Us
For questions about this privacy policy, please contact your clinic administrator.'''
        : '''سياسة الخصوصية لنظام إدارة الموظفين

آخر تحديث: فبراير 2026

1. المعلومات التي نجمعها
نجمع المعلومات الشخصية التي تقدمها عند إنشاء حسابك، بما في ذلك الاسم والبريد الإلكتروني وبيانات التوظيف. كما نجمع بيانات الاستخدام لتحسين خدماتنا.

2. كيف نستخدم معلوماتك
تُستخدم معلوماتك من أجل:
- تقديم وصيانة خدمات إدارة العيادة
- معالجة الرواتب وعمليات الموارد البشرية
- إرسال إشعارات حول حسابك
- تحسين وتخصيص تجربة التطبيق

3. تخزين البيانات والأمان
يتم تخزين بياناتك بشكل آمن على خوادمنا. نستخدم التشفير المتوافق مع معايير الصناعة لحماية معلوماتك الشخصية أثناء النقل والتخزين.

4. مشاركة البيانات
نحن لا نبيع معلوماتك الشخصية. قد نشارك البيانات مع:
- مدير العيادة لأغراض إدارة الموارد البشرية
- مزودي الخدمات الذين يساعدون في تشغيل منصتنا

5. حقوقك
لديك الحق في:
- الوصول إلى بياناتك الشخصية
- تصحيح البيانات غير الدقيقة
- طلب حذف حسابك وبياناتك
- تصدير بياناتك

6. الاحتفاظ بالبيانات
نحتفظ ببياناتك طالما أن حسابك نشط. عند حذف الحساب، سيتم إزالة بياناتك الشخصية نهائياً خلال 30 يوماً.

7. اتصل بنا
للاستفسارات حول سياسة الخصوصية، يرجى التواصل مع مدير العيادة.''';

    return _SubScreenShell(
      onBack: onBack,
      title: t('سياسة الخصوصية', 'Privacy Policy'),
      subtitle: t('كيف نحمي بياناتك', 'How we protect your data'),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsetsDirectional.all(ds.spacing.md),
              decoration: BoxDecoration(
                color: ds.colors.surface,
                borderRadius: BorderRadius.circular(ds.radii.large),
                border: Border.all(color: ds.colors.border),
              ),
              child: DSText(
                content,
                role: DSTextRole.body,
                color: ds.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  final VoidCallback onBack;

  const TermsOfServiceScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final isEn = AppScope.of(context).locale.languageCode == 'en';
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    final content = isEn
        ? '''Terms of Service for Salim HR

Last Updated: February 2026

1. Acceptance of Terms
By using Salim HR, you agree to be bound by these Terms of Service. If you do not agree, please do not use the application.

2. Description of Service
Salim HR is a clinic management platform providing HR, payroll, inventory, and appointment management services.

3. User Accounts
- You are responsible for maintaining the confidentiality of your account credentials
- You must provide accurate and complete information
- You must notify us of any unauthorized use of your account

4. Acceptable Use
You agree not to:
- Use the service for any unlawful purpose
- Attempt to gain unauthorized access to our systems
- Share your account credentials with others
- Interfere with or disrupt the service

5. Data and Content
- You retain ownership of your personal data
- You grant us a license to use your data to provide the service
- We may remove content that violates these terms

6. Termination
- You may delete your account at any time
- We may suspend or terminate accounts that violate these terms
- Upon termination, your data will be handled according to our Privacy Policy

7. Limitation of Liability
The service is provided "as is" without warranties of any kind. We are not liable for any indirect, incidental, or consequential damages.

8. Changes to Terms
We may update these terms from time to time. Continued use of the service constitutes acceptance of the updated terms.

9. Contact
For questions about these terms, please contact your clinic administrator.'''
        : '''شروط الاستخدام لنظام إدارة الموظفين

آخر تحديث: فبراير 2026

1. قبول الشروط
باستخدام نظام إدارة الموظفين، فإنك توافق على الالتزام بشروط الاستخدام هذه. إذا كنت لا توافق، يرجى عدم استخدام التطبيق.

2. وصف الخدمة
نظام إدارة الموظفين هو منصة إدارة عيادات توفر خدمات الموارد البشرية والرواتب والمخزون وإدارة المواعيد.

3. حسابات المستخدمين
- أنت مسؤول عن الحفاظ على سرية بيانات حسابك
- يجب عليك تقديم معلومات دقيقة وكاملة
- يجب إبلاغنا بأي استخدام غير مصرح به لحسابك

4. الاستخدام المقبول
توافق على عدم:
- استخدام الخدمة لأي غرض غير قانوني
- محاولة الوصول غير المصرح به إلى أنظمتنا
- مشاركة بيانات حسابك مع آخرين
- التدخل في الخدمة أو تعطيلها

5. البيانات والمحتوى
- تحتفظ بملكية بياناتك الشخصية
- تمنحنا ترخيصاً لاستخدام بياناتك لتقديم الخدمة
- يجوز لنا إزالة المحتوى الذي ينتهك هذه الشروط

6. الإنهاء
- يمكنك حذف حسابك في أي وقت
- يجوز لنا تعليق أو إنهاء الحسابات التي تنتهك هذه الشروط
- عند الإنهاء، ستتم معالجة بياناتك وفقاً لسياسة الخصوصية

7. تحديد المسؤولية
يتم تقديم الخدمة "كما هي" دون أي ضمانات من أي نوع. نحن لسنا مسؤولين عن أي أضرار غير مباشرة أو عرضية أو تبعية.

8. تغييرات على الشروط
قد نقوم بتحديث هذه الشروط من وقت لآخر. يعتبر الاستمرار في استخدام الخدمة قبولاً للشروط المحدثة.

9. الاتصال
للاستفسارات حول هذه الشروط، يرجى التواصل مع مدير العيادة.''';

    return _SubScreenShell(
      onBack: onBack,
      title: t('شروط الاستخدام', 'Terms of Service'),
      subtitle: t('شروط وأحكام التطبيق', 'App terms & conditions'),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsetsDirectional.all(ds.spacing.md),
              decoration: BoxDecoration(
                color: ds.colors.surface,
                borderRadius: BorderRadius.circular(ds.radii.large),
                border: Border.all(color: ds.colors.border),
              ),
              child: DSText(
                content,
                role: DSTextRole.body,
                color: ds.colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeleteAccountScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onDeleted;

  const DeleteAccountScreen({
    super.key,
    required this.onBack,
    required this.onDeleted,
  });

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_passwordController.text.isEmpty) {
      setState(() {
        _error = t('أدخل كلمة المرور', 'Enter your password');
      });
      return;
    }

    final authService = context.authService;
    final success = await authService.deleteAccount(_passwordController.text);
    if (!mounted) return;

    if (success) {
      widget.onDeleted();
    } else {
      setState(() {
        _error =
            authService.error ??
            t('فشل حذف الحساب', 'Failed to delete account');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final authService = context.watchAuth;
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return _SubScreenShell(
      onBack: widget.onBack,
      title: t('حذف الحساب', 'Delete Account'),
      subtitle: t(
        'هذا الإجراء لا يمكن التراجع عنه',
        'This action cannot be undone',
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning
                Container(
                  width: double.infinity,
                  padding: EdgeInsetsDirectional.all(ds.spacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ds.radii.large),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DSText(
                        t('تحذير', 'Warning'),
                        role: DSTextRole.title,
                        color: const Color(0xFFEF4444),
                      ),
                      SizedBox(height: ds.spacing.xs),
                      DSText(
                        t(
                          'سيتم حذف حسابك وجميع بياناتك نهائياً. لا يمكن التراجع عن هذا الإجراء.',
                          'Your account and all associated data will be permanently deleted. This action cannot be undone.',
                        ),
                        role: DSTextRole.body,
                        color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ds.spacing.lg),
                DSText(
                  t(
                    'أدخل كلمة المرور للتأكيد',
                    'Enter your password to confirm',
                  ),
                  role: DSTextRole.label,
                  color: ds.colors.textSecondary,
                ),
                SizedBox(height: ds.spacing.sm),
                _FunctionalInput(
                  controller: _passwordController,
                  label: t('كلمة المرور', 'Password'),
                  placeholder: t('أدخل كلمة المرور', 'Enter password'),
                  icon: LineIconType.home,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                ),
                SizedBox(height: ds.spacing.lg),
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.all(ds.spacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ds.radii.medium),
                    ),
                    child: DSText(
                      _error!,
                      role: DSTextRole.caption,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(height: ds.spacing.md),
                ],
                GestureDetector(
                  onTap: authService.isLoading ? null : _delete,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsetsDirectional.all(ds.spacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(ds.radii.large),
                    ),
                    child: Center(
                      child: DSText(
                        authService.isLoading
                            ? t('جاري الحذف...', 'Deleting...')
                            : t(
                                'حذف الحساب نهائياً',
                                'Permanently Delete Account',
                              ),
                        role: DSTextRole.title,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  final ValueChanged<UserRole>? onRestoreRole;

  const SplashScreen({super.key, required this.onDone, this.onRestoreRole});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSession());
  }

  Future<void> _initSession() async {
    // Run auth check and minimum splash delay in parallel
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 1200));

    try {
      final authService = context.authService;
      final apiClient = context.apiClient;

      final isAuthenticated = await authService.checkAuth();
      if (!mounted) return;

      if (isAuthenticated) {
        final savedRole = await apiClient.getRole();
        if (savedRole != null && mounted) {
          final role = UserRole.values.firstWhere(
            (r) => r.name == savedRole,
            orElse: () => UserRole.worker,
          );

          // Re-register FCM token for push notifications
          final pushService = context.firebasePushService;
          pushService.initialize().then((_) => pushService.registerToken());

          widget.onRestoreRole?.call(role);
        }
      }
    } catch (e, st) {
      // Auth restore failure is non-blocking — proceed to login. Surface
      // the error in debugPrint so genuine outages (token revoked, server
      // returning 500) don't disappear silently in TestFlight.
      debugPrint('Auth restore failed: $e\n$st');
    }

    await minDelay;
    if (mounted) {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      color: const Color(0xFF003C4B),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo/salimhr bg.png',
              width: ds.spacing.xl * 5,
              height: ds.spacing.xl * 5,
              fit: BoxFit.contain,
            ),
            SizedBox(height: ds.spacing.lg),
            DSText(
              tr(context, ar: 'نظام ادارة الموظفين', en: 'Salim HR'),
              role: DSTextRole.display,
              color: const Color(0xFFFFFFFF),
            ),
            SizedBox(height: ds.spacing.xs),
            DSText(
              tr(
                context,
                ar: 'إدارة متكاملة للعيادات',
                en: 'Complete Clinic Management',
              ),
              role: DSTextRole.caption,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangSwitcher extends StatelessWidget {
  final bool isArabic;
  final ValueChanged<String> onSwitch;

  const _LangSwitcher({required this.isArabic, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      decoration: BoxDecoration(
        color: ds.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(ds.radii.pill),
        border: Border.all(color: ds.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(
            label: 'AR',
            selected: isArabic,
            onTap: () => onSwitch('ar'),
          ),
          _LangChip(
            label: 'EN',
            selected: !isArabic,
            onTap: () => onSwitch('en'),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ds.animation.fast,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.md,
          vertical: ds.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ds.colors.primary.withValues(alpha: 0.12)
              : ds.colors.surface.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(ds.radii.pill),
        ),
        child: DSText(
          label,
          role: DSTextRole.label,
          color: selected ? ds.colors.primary : ds.colors.textSecondary,
        ),
      ),
    );
  }
}

// ==================== MY DOCUMENTS ====================

class DocumentsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const DocumentsScreen({super.key, required this.onBack});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _loading = true;
  final Map<String, UserDocument> _docs = {};

  // Fixed document slots (type → Arabic/English label).
  static const List<(String, String, String)> _types = [
    ('national_id', 'البطاقة الشخصية', 'National ID'),
    ('practice_license', 'بطاقة ممارسة المهنة', 'Practice License'),
    ('employee_card', 'بطاقة الموظف', 'Employee Card'),
    ('bls_certificate', 'شهادة BLS', 'BLS Certificate'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final docs = await context.authService.fetchDocuments();
    if (!mounted) return;
    setState(() {
      _docs.clear();
      for (final d in docs) {
        _docs[d.type] = d;
      }
      _loading = false;
    });
  }

  Future<void> _open(UserDocument doc) async {
    final uri = Uri.tryParse(doc.url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _view(UserDocument doc) {
    if (doc.isPdf) {
      _open(doc);
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, _) {
          final ds = DSProvider.of(context);
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: const Color(0xE6000000),
              alignment: Alignment.center,
              padding: EdgeInsets.all(ds.spacing.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ds.radii.large),
                child: Image.network(doc.url, fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return _SubScreenShell(
      onBack: widget.onBack,
      title: t('مستنداتي', 'My Documents'),
      subtitle: t('البطاقات والشهادات', 'Cards & certificates'),
      child: _loading
          ? const ShimmerLoading()
          : ListView(
              children: [
                Container(
                  padding: EdgeInsetsDirectional.all(ds.spacing.md),
                  margin: EdgeInsetsDirectional.only(bottom: ds.spacing.md),
                  decoration: BoxDecoration(
                    color: ds.colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(ds.radii.large),
                  ),
                  child: DSText(
                    t(
                      'المستندات تُضاف من قِبل الإدارة. يمكنك عرضها وتحميلها فقط.',
                      'Documents are added by the administration. You can only view and download them.',
                    ),
                    role: DSTextRole.caption,
                    color: ds.colors.textSecondary,
                  ),
                ),
                for (final entry in _types)
                  Padding(
                    padding: EdgeInsetsDirectional.only(bottom: ds.spacing.md),
                    child: _DocumentTile(
                      title: t(entry.$2, entry.$3),
                      doc: _docs[entry.$1],
                      onView: () => _view(_docs[entry.$1]!),
                      onDownload: () => _open(_docs[entry.$1]!),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String title;
  final UserDocument? doc;
  final VoidCallback onView;
  final VoidCallback onDownload;

  const _DocumentTile({
    required this.title,
    required this.doc,
    required this.onView,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final has = doc != null;
    final color = has ? const Color(0xFF10B981) : ds.colors.textMuted;

    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ds.spacing.xl,
                height: ds.spacing.xl,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                ),
                child: Center(
                  child: DSLineIcon(type: LineIconType.bookmark, color: color, size: ds.spacing.md),
                ),
              ),
              SizedBox(width: ds.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(title, role: DSTextRole.title, maxLines: 1),
                    SizedBox(height: 2),
                    DSText(
                      has ? t('تم الرفع', 'Uploaded') : t('لم يُضف بعد', 'Not added yet'),
                      role: DSTextRole.caption,
                      color: has ? const Color(0xFF10B981) : ds.colors.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (has) ...[
            SizedBox(height: ds.spacing.sm),
            Container(height: 1, color: ds.colors.border.withValues(alpha: 0.5)),
            SizedBox(height: ds.spacing.sm),
            Row(
              children: [
                Expanded(
                  child: _DocAction(
                    label: t('عرض', 'View'),
                    icon: LineIconType.search,
                    color: const Color(0xFF6366F1),
                    onTap: onView,
                  ),
                ),
                SizedBox(width: ds.spacing.sm),
                Expanded(
                  child: _DocAction(
                    label: t('تحميل', 'Download'),
                    icon: LineIconType.chart,
                    color: const Color(0xFF10B981),
                    onTap: onDownload,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DocAction extends StatelessWidget {
  final String? label;
  final LineIconType icon;
  final Color color;
  final VoidCallback onTap;

  const _DocAction({
    this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(vertical: ds.spacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(ds.radii.medium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DSLineIcon(type: icon, color: color, size: ds.spacing.md),
            if (label != null) ...[
              SizedBox(width: ds.spacing.xs),
              DSText(label!, role: DSTextRole.caption, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

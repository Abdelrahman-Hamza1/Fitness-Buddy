import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/today/application/today_controller.dart';
import 'package:fb_mobile/features/today/application/today_date.dart';
import 'package:fb_mobile/features/today/presentation/day_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The Today tab (UX-010, HM-001, HM-007, HM-008, HM-009): the date header,
/// one page per day (swipe sideways, ‹ ›, or pick a date) and the input bar
/// at the bottom. Today is the last page; nothing comes after it (DY-003).
/// No title bar: the date header takes its place (backlog #35).
///
/// The screen keeps the viewed day and its two neighbours loaded (A08 D3), so
/// a swipe finds the next page's data already there. It follows midnight and
/// the app coming back to the front (A08 D4).
class TodayScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final PageController _pages;
  late final AppLifecycleListener _lifecycle;

  /// The loaded days: the viewed one and its neighbours.
  final Map<LocalDate, ProviderSubscription<AsyncValue<DayView>>> _window = {};

  LocalDate get _today =>
      ref.read(todayProvider).value ??
      EntryTime.now(ref.read(clockProvider)).localDate;

  LocalDate get _viewed => ref.read(todayControllerProvider) ?? _today;

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: DayPager(_today).indexOf(_viewed));
    // Back from the background: the day may have changed, and so may the
    // time zone (A08 D4).
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(todayProvider),
    );
    _afterFrame(_syncWindow);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    for (final subscription in _window.values) {
      subscription.close();
    }
    _window.clear();
    _pages.dispose();
    super.dispose();
  }

  void _afterFrame(VoidCallback action) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });

  /// Moves the pager to the viewed day when ‹ › or the picker changed it.
  void _syncPage() {
    if (!_pages.hasClients || !_pages.position.haveDimensions) return;
    final target = DayPager(_today).indexOf(_viewed);
    final current = _pages.page!.round();
    if (current == target) return;
    final duration = FbMotion.of(context);
    if ((current - target).abs() == 1 && duration > Duration.zero) {
      _pages.animateToPage(target, duration: duration, curve: FbMotion.curve);
    } else {
      _pages.jumpToPage(target);
    }
  }

  /// Keeps exactly the viewed day and its neighbours subscribed. The
  /// neighbours wait for the viewed day's first data, so they never slow it.
  void _syncWindow() {
    final viewed = _viewed;
    final wanted = _subscribe(viewed).read().hasValue
        ? DayPager(_today).window(viewed)
        : {viewed};
    for (final date in {...wanted, ..._window.keys}) {
      if (wanted.contains(date)) {
        _subscribe(date);
      } else {
        _window.remove(date)?.close();
      }
    }
  }

  ProviderSubscription<AsyncValue<DayView>> _subscribe(LocalDate date) =>
      _window[date] ??= ref.listenManual(dayViewProvider(date), (
        previous,
        next,
      ) {
        if (date == _viewed &&
            next.hasValue &&
            !(previous?.hasValue ?? false)) {
          _syncWindow();
        }
      });

  Future<void> _pickDate(LocalDate viewed, LocalDate today) async {
    final first = DayPager(today).dateAt(0);
    final picked = await showFbDatePicker(
      context,
      initialDate: DateTime(viewed.year, viewed.month, viewed.day),
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked == null || !mounted) return;
    ref
        .read(todayControllerProvider.notifier)
        .goTo(LocalDate(picked.year, picked.month, picked.day));
  }

  void _comingSoon() => showFbSnackBar(context, context.l10n.devComingSoon);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today =
        ref.watch(todayProvider).value ??
        EntryTime.now(ref.watch(clockProvider)).localDate;
    final viewed = ref.watch(todayControllerProvider) ?? today;
    final pager = DayPager(today);
    final controller = ref.read(todayControllerProvider.notifier);
    final dev = ref.watch(appConfigProvider).flavor == AppFlavor.dev;

    ref
      ..listen(todayProvider, (_, next) {
        if (next.value case final date?) {
          controller.onTodayChanged(date);
          // The pages' dates shift with today: a past day keeps its page by
          // following its new index, without animation (A08 D4).
          final stays = ref.read(todayControllerProvider);
          if (stays != null && _pages.hasClients) {
            _pages.jumpToPage(DayPager(date).indexOf(stays));
          }
          _afterFrame(_syncWindow);
        }
      })
      ..listen(todayControllerProvider, (_, _) {
        _afterFrame(() {
          _syncPage();
          _syncWindow();
        });
      });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FbDateHeader(
              label: dayLabel(context, viewed, today),
              onPrevious: controller.previous,
              onNext: pager.canGoNext(viewed) ? controller.next : null,
              onLabelTap: () => unawaited(_pickDate(viewed, today)),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: pager.pageCount,
                // Today as it is now: a jump made while today changes reports
                // its page against the new today, not the one built last.
                onPageChanged: (index) =>
                    controller.goTo(DayPager(_today).dateAt(index)),
                findChildIndexCallback: (key) => switch (key) {
                  ValueKey<LocalDate>(:final value) => pager.indexOf(value),
                  _ => null,
                },
                itemBuilder: (context, index) {
                  final date = pager.dateAt(index);
                  return DayPage(
                    key: ValueKey(date),
                    date: date,
                    isToday: date == today,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                FbSpace.s4,
                FbSpace.s2,
                FbSpace.s4,
                FbSpace.s2,
              ),
              child: FbInputBar(
                hint: l10n.todayInputHintSearch,
                onTap: () => ref
                    .read(appNavigatorProvider)
                    .push(FoodSearchRoute(date: viewed)),
                // Not built yet (A22, A28): in the dev flavor only.
                onCamera: dev ? _comingSoon : null,
                onBarcode: dev ? _comingSoon : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

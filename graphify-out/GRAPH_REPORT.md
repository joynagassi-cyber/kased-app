# Graph Report - kased-app-new  (2026-08-26)

## Corpus Check
- 186 files · ~512,580 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1305 nodes · 1769 edges · 43 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 10 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 67 edges
2. `package:flutter_riverpod/flutter_riverpod.dart` - 35 edges
3. `package:kased_app/models/membre.dart` - 35 edges
4. `package:kased_app/models/culte.dart` - 29 edges
5. `package:flutter_test/flutter_test.dart` - 29 edges
6. `package:kased_app/models/cotisation.dart` - 28 edges
7. `package:kased_app/core/theme/app_theme.dart` - 27 edges
8. `package:kased_app/providers/kased_app_provider.dart` - 24 edges
9. `package:flutter/foundation.dart` - 20 edges
10. `dart:async` - 18 edges

## Surprising Connections (you probably didn't know these)
- `RegisterPlugins()` --calls--> `OnCreate()`  [INFERRED]
  cotis_app\windows\flutter\generated_plugin_registrant.cc → cotis_app\windows\runner\flutter_window.cpp
- `OnCreate()` --calls--> `Show()`  [INFERRED]
  cotis_app\windows\runner\flutter_window.cpp → cotis_app\windows\runner\win32_window.cpp
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  cotis_app\windows\runner\main.cpp → cotis_app\windows\runner\utils.cpp
- `wWinMain()` --calls--> `SetQuitOnClose()`  [INFERRED]
  cotis_app\windows\runner\main.cpp → cotis_app\windows\runner\win32_window.cpp
- `fetchAllUserEmails()` --calls--> `Text`  [INFERRED]
  cotis_app\functions\push-notify.js → cotis_app\lib\widgets\custom_google_signin_button.dart

## Communities

### Community 0 - "Community 0"
Cohesion: 0.02
Nodes (142): KasedExportService, IsarLocalCache, _pickCotisation, _pickCulte, _pickMembre, LocalCache, DashboardStats, _getCollecteMoisPrecedent (+134 more)

### Community 1 - "Community 1"
Cohesion: 0.03
Nodes (90): ThemeModeNotifier, build, Divider, Icon, KasedCard, ProgressSectionWidget, SizedBox, Spacer (+82 more)

### Community 2 - "Community 2"
Cohesion: 0.02
Nodes (94): AlertDialog, build, _confirmDeleteCulte, Container, CultesScreen, _CultesScreenState, CustomScrollView, _DatePickerTile (+86 more)

### Community 3 - "Community 3"
Cohesion: 0.02
Nodes (65): AnimatedAppear, build, AvatarService, Color, colorFromEmail, generateFromEmail, initialsFromEmail, ConfirmActionDialog (+57 more)

### Community 4 - "Community 4"
Cohesion: 0.03
Nodes (56): AppPrefs, AppPrefsKey, _check, addListener, cleanup, init, markOffline, _onPresenceUpdate (+48 more)

### Community 5 - "Community 5"
Cohesion: 0.04
Nodes (46): app_update_model.dart, _notificationIdFor, NotificationService, AuthService, Duration, Exception, _requireAnonKey, addListener (+38 more)

### Community 6 - "Community 6"
Cohesion: 0.04
Nodes (46): AppColors, AppTheme, _buildTheme, _displayStyle, ThemeData, AnimatedContainer, build, _buildBottomBar (+38 more)

### Community 7 - "Community 7"
Cohesion: 0.04
Nodes (45): build, _Card, Container, dispose, GestureDetector, initState, Padding, ProfileScreen (+37 more)

### Community 8 - "Community 8"
Cohesion: 0.04
Nodes (47): build, Center, Consumer, DashboardScreen, _DashboardScreenState, Divider, DraggableScrollableSheet, initState (+39 more)

### Community 9 - "Community 9"
Cohesion: 0.04
Nodes (43): addNotificationClickListener, addPushSubscriptionObserver, OneSignalService, setLogLevel, _BouncingScrollBehavior, BouncingScrollPhysics, build, didChangeAppLifecycleState (+35 more)

### Community 10 - "Community 10"
Cohesion: 0.05
Nodes (39): _asList, _asSingle, InsForgeService, StateError, build, dispose, initState, LoginScreen (+31 more)

### Community 11 - "Community 11"
Cohesion: 0.05
Nodes (38): calculerMontantDu, calculerNombreRetards, CotisationLogic, determinerStatut, _AuthNotifier, _buildFadeSlidePage, FadeTransition, GoRouter (+30 more)

### Community 12 - "Community 12"
Cohesion: 0.07
Nodes (34): CotisationExportService, _saveAndShareCsv, _getStatutText, MemberReportExportService, _getStatutColor, _getStatutText, MemberReportPdfService, _saveAndShare (+26 more)

### Community 13 - "Community 13"
Cohesion: 0.09
Nodes (25): FlutterWindow(), OnCreate(), RegisterPlugins(), wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), Create() (+17 more)

### Community 14 - "Community 14"
Cohesion: 0.06
Nodes (28): CorbeilleItem, copyWith, Cotisation, fromJson, _statutToString, _stringToStatut, Culte, fromJson (+20 more)

### Community 15 - "Community 15"
Cohesion: 0.06
Nodes (28): build, CulteDetailScreen, _CulteDetailScreenState, EmptyState, MemberPayTile, Padding, Scaffold, SizedBox (+20 more)

### Community 16 - "Community 16"
Cohesion: 0.08
Nodes (22): build, didUpdateWidget, dispose, initState, ScaleTransition, SpringNavIcon, _SpringNavIconState, _triggerSpring (+14 more)

### Community 17 - "Community 17"
Cohesion: 0.08
Nodes (24): _cotisationAttach, _cotisationDeserialize, _cotisationEstimateSize, _cotisationGetId, _cotisationSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+16 more)

### Community 18 - "Community 18"
Cohesion: 0.08
Nodes (23): AddPaymentAdvance, BulkSetPaiements, CreateCulte, CreateMember, DeleteCulte, DeleteMember, EmptyTrash, GetCotisationsDuCulte (+15 more)

### Community 19 - "Community 19"
Cohesion: 0.09
Nodes (21): _culteAttach, _culteDeserialize, _culteEstimateSize, _culteGetId, _culteSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+13 more)

### Community 20 - "Community 20"
Cohesion: 0.09
Nodes (21): deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync, deleteByIdSync, deleteByIndex, deleteByIndexSync, getAllByIndex, getAllByIndexSync (+13 more)

### Community 21 - "Community 21"
Cohesion: 0.12
Nodes (13): build, _buildPermissionItem, Container, CustomGoogleSignInButton, GoogleConsentInfo, Icon, Padding, SizedBox (+5 more)

### Community 22 - "Community 22"
Cohesion: 0.12
Nodes (15): build, _CadenceCard, Container, _HistoriqueItem, MembreDetailScreen, _MembreDetailScreenState, Padding, paint (+7 more)

### Community 23 - "Community 23"
Cohesion: 0.12
Nodes (15): AnimatedBuilder, build, Container, CulteDetailSkeleton, DashboardSkeleton, dispose, initState, ListView (+7 more)

### Community 24 - "Community 24"
Cohesion: 0.12
Nodes (15): Auth, AuthState, build, _checkPersistedAuth, copyWith, Exception, FlutterSecureStorage, _isTokenExpired (+7 more)

### Community 25 - "Community 25"
Cohesion: 0.13
Nodes (14): AnimatedContainer, BatchPaymentDialog, _BatchPaymentDialogState, build, Dialog, dispose, Function, Icon (+6 more)

### Community 26 - "Community 26"
Cohesion: 0.17
Nodes (9): FakeNotifyAdapter, hasEventType, NoOpNotifyAdapter, NotificationEvent, NotifyPort, RealNotifyAdapter, send, toString (+1 more)

### Community 27 - "Community 27"
Cohesion: 0.25
Nodes (6): CulteLock, isLocked, isPaymentLocked, main, package:kased_app/core/constants.dart, package:kased_app/core/logic/culte_lock.dart

### Community 28 - "Community 28"
Cohesion: 0.29
Nodes (6): _corbeilleItemAttach, _corbeilleItemDeserialize, _corbeilleItemEstimateSize, _corbeilleItemGetId, _corbeilleItemSerialize, IsarError

### Community 29 - "Community 29"
Cohesion: 0.29
Nodes (6): IsarError, _syncOperationAttach, _syncOperationDeserialize, _syncOperationEstimateSize, _syncOperationGetId, _syncOperationSerialize

### Community 30 - "Community 30"
Cohesion: 0.33
Nodes (1): AppUpdatePlugin

### Community 31 - "Community 31"
Cohesion: 0.33
Nodes (5): DeviceServicePort, FakeDeviceService, NoOpDeviceService, RealDeviceService, package:kased_app/core/sync/device_service.dart

### Community 32 - "Community 32"
Cohesion: 0.4
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 33 - "Community 33"
Cohesion: 0.4
Nodes (4): copyWith, DevicePresence, PresenceState, RealtimeEvent

### Community 34 - "Community 34"
Cohesion: 0.5
Nodes (1): MainActivity

### Community 35 - "Community 35"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 36 - "Community 36"
Cohesion: 0.5
Nodes (3): AppUpdate, AppUpdateCheckResult, copyWith

### Community 37 - "Community 37"
Cohesion: 0.5
Nodes (3): generate, UuidUtils, dart:math

### Community 38 - "Community 38"
Cohesion: 1.0
Nodes (2): main(), sha1_du_keystore()

### Community 39 - "Community 39"
Cohesion: 1.0
Nodes (1): KasedConstants

### Community 40 - "Community 40"
Cohesion: 1.0
Nodes (1): InsForgeConfig

### Community 41 - "Community 41"
Cohesion: 1.0
Nodes (1): InsForgeServicePort

### Community 42 - "Community 42"
Cohesion: 1.0
Nodes (1): AppNotification

## Knowledge Gaps
- **978 isolated node(s):** `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `KasedApp`, `_KasedAppState`, `_BouncingScrollBehavior` (+973 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 30`** (6 nodes): `AppUpdatePlugin`, `.installApk()`, `.onAttachedToEngine()`, `.onDetachedFromEngine()`, `.onMethodCall()`, `AppUpdatePlugin.kt`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 32`** (5 nodes): `GeneratedPluginRegistrant.java`, `GeneratedPluginRegistrant.m`, `GeneratedPluginRegistrant`, `.registerWith()`, `-registerWithRegistry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 34`** (4 nodes): `MainActivity.kt`, `MainActivity.kt`, `MainActivity`, `.configureFlutterEngine()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 35`** (4 nodes): `flutter_lldb_helper.py`, `handle_new_rx_page()`, `__lldb_init_module()`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 38`** (3 nodes): `verifier-google-signin.py`, `main()`, `sha1_du_keystore()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 39`** (2 nodes): `KasedConstants`, `constants.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 40`** (2 nodes): `InsForgeConfig`, `insforge_config.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (2 nodes): `InsForgeServicePort`, `insforge_service_port.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (2 nodes): `AppNotification`, `app_notification.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 3` to `Community 1`, `Community 2`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 14`, `Community 15`, `Community 16`, `Community 21`, `Community 22`, `Community 23`, `Community 25`?**
  _High betweenness centrality (0.256) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Community 1` to `Community 0`, `Community 2`, `Community 4`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 14`, `Community 15`, `Community 22`?**
  _High betweenness centrality (0.094) - this node is a cross-community bridge._
- **Why does `dart:async` connect `Community 4` to `Community 0`, `Community 1`, `Community 5`, `Community 8`, `Community 9`, `Community 11`, `Community 24`?**
  _High betweenness centrality (0.069) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `KasedApp` to the rest of the system?**
  _978 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
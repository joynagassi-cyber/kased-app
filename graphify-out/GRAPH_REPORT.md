# Graph Report - kased-app-new  (2026-08-26)

## Corpus Check
- 169 files · ~506,852 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1239 nodes · 1702 edges · 34 communities detected
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

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 57 edges
2. `package:flutter_riverpod/flutter_riverpod.dart` - 37 edges
3. `package:kased_app/models/membre.dart` - 34 edges
4. `package:kased_app/models/cotisation.dart` - 29 edges
5. `package:flutter_test/flutter_test.dart` - 29 edges
6. `package:kased_app/models/culte.dart` - 28 edges
7. `package:kased_app/providers/kased_app_provider.dart` - 27 edges
8. `package:kased_app/core/theme/app_theme.dart` - 22 edges
9. `package:flutter/foundation.dart` - 19 edges
10. `package:kased_app/store/app_state.dart` - 18 edges

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
Nodes (128): CotisationController, CulteIntrouvableException, enregistrerPaiement, Function, MontantInsuffisantException, PaiementVerrouilleException, toString, CulteController (+120 more)

### Community 1 - "Community 1"
Cohesion: 0.03
Nodes (95): Function, getDashboardStats, SyncDataResult, SyncEnCoursException, SystemController, toString, CotisationExportService, _getStatutText (+87 more)

### Community 2 - "Community 2"
Cohesion: 0.03
Nodes (88): ThemeModeNotifier, main, buildApp, FakeAppData, getDashboardStats, main, MockAuthService, MockSecureStorage (+80 more)

### Community 3 - "Community 3"
Cohesion: 0.02
Nodes (87): AnimatedAppear, build, AvatarService, Color, colorFromEmail, generateFromEmail, initialsFromEmail, AppColors (+79 more)

### Community 4 - "Community 4"
Cohesion: 0.02
Nodes (84): build, CulteDetailScreen, _CulteDetailScreenState, EmptyState, MemberPayTile, Padding, Scaffold, SizedBox (+76 more)

### Community 5 - "Community 5"
Cohesion: 0.03
Nodes (65): calculerMontantDu, calculerNombreRetards, CotisationLogic, determinerStatut, _AuthNotifier, _buildFadeSlidePage, FadeTransition, GoRouter (+57 more)

### Community 6 - "Community 6"
Cohesion: 0.03
Nodes (58): _notificationIdFor, NotificationService, addListener, cleanup, init, markOffline, _onPresenceUpdate, PresenceService (+50 more)

### Community 7 - "Community 7"
Cohesion: 0.03
Nodes (60): AppPrefs, AppPrefsKey, _check, DeviceService, _ActionButton, build, Center, Chip (+52 more)

### Community 8 - "Community 8"
Cohesion: 0.03
Nodes (58): _asList, _asSingle, InsForgeService, StateError, build, dispose, initState, LoginScreen (+50 more)

### Community 9 - "Community 9"
Cohesion: 0.04
Nodes (48): addNotificationClickListener, addPushSubscriptionObserver, OneSignalService, setLogLevel, _BouncingScrollBehavior, BouncingScrollPhysics, build, didChangeAppLifecycleState (+40 more)

### Community 10 - "Community 10"
Cohesion: 0.04
Nodes (47): AuthService, Duration, Exception, _requireAnonKey, build, didUpdateWidget, dispose, initState (+39 more)

### Community 11 - "Community 11"
Cohesion: 0.09
Nodes (25): FlutterWindow(), OnCreate(), RegisterPlugins(), wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), Create() (+17 more)

### Community 12 - "Community 12"
Cohesion: 0.06
Nodes (28): CorbeilleItem, copyWith, Cotisation, fromJson, _statutToString, _stringToStatut, Culte, fromJson (+20 more)

### Community 13 - "Community 13"
Cohesion: 0.08
Nodes (25): build, _Card, Container, dispose, GestureDetector, initState, Padding, ProfileScreen (+17 more)

### Community 14 - "Community 14"
Cohesion: 0.08
Nodes (24): _cotisationAttach, _cotisationDeserialize, _cotisationEstimateSize, _cotisationGetId, _cotisationSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+16 more)

### Community 15 - "Community 15"
Cohesion: 0.09
Nodes (21): _culteAttach, _culteDeserialize, _culteEstimateSize, _culteGetId, _culteSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+13 more)

### Community 16 - "Community 16"
Cohesion: 0.09
Nodes (21): deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync, deleteByIdSync, deleteByIndex, deleteByIndexSync, getAllByIndex, getAllByIndexSync (+13 more)

### Community 17 - "Community 17"
Cohesion: 0.1
Nodes (20): AddPaymentAdvance, BulkSetPaiements, CreateCulte, CreateMember, DeleteCulte, DeleteMember, EmptyTrash, GetCotisationsDuCulte (+12 more)

### Community 18 - "Community 18"
Cohesion: 0.12
Nodes (13): build, _buildPermissionItem, Container, CustomGoogleSignInButton, GoogleConsentInfo, Icon, Padding, SizedBox (+5 more)

### Community 19 - "Community 19"
Cohesion: 0.12
Nodes (15): build, _CadenceCard, Container, _HistoriqueItem, MembreDetailScreen, _MembreDetailScreenState, Padding, paint (+7 more)

### Community 20 - "Community 20"
Cohesion: 0.17
Nodes (9): FakeNotifyAdapter, hasEventType, NoOpNotifyAdapter, NotificationEvent, NotifyPort, RealNotifyAdapter, send, toString (+1 more)

### Community 21 - "Community 21"
Cohesion: 0.25
Nodes (6): CulteLock, isLocked, isPaymentLocked, main, package:kased_app/core/constants.dart, package:kased_app/core/logic/culte_lock.dart

### Community 22 - "Community 22"
Cohesion: 0.29
Nodes (6): _corbeilleItemAttach, _corbeilleItemDeserialize, _corbeilleItemEstimateSize, _corbeilleItemGetId, _corbeilleItemSerialize, IsarError

### Community 23 - "Community 23"
Cohesion: 0.29
Nodes (6): IsarError, _syncOperationAttach, _syncOperationDeserialize, _syncOperationEstimateSize, _syncOperationGetId, _syncOperationSerialize

### Community 24 - "Community 24"
Cohesion: 0.33
Nodes (5): DeviceServicePort, FakeDeviceService, NoOpDeviceService, RealDeviceService, package:kased_app/core/sync/device_service.dart

### Community 25 - "Community 25"
Cohesion: 0.4
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 26 - "Community 26"
Cohesion: 0.4
Nodes (4): copyWith, DevicePresence, PresenceState, RealtimeEvent

### Community 27 - "Community 27"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 28 - "Community 28"
Cohesion: 0.5
Nodes (3): generate, UuidUtils, dart:math

### Community 29 - "Community 29"
Cohesion: 0.67
Nodes (1): MainActivity

### Community 30 - "Community 30"
Cohesion: 1.0
Nodes (2): main(), sha1_du_keystore()

### Community 31 - "Community 31"
Cohesion: 1.0
Nodes (1): KasedConstants

### Community 32 - "Community 32"
Cohesion: 1.0
Nodes (1): InsForgeConfig

### Community 33 - "Community 33"
Cohesion: 1.0
Nodes (1): AppNotification

## Knowledge Gaps
- **935 isolated node(s):** `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `KasedApp`, `_KasedAppState`, `_BouncingScrollBehavior` (+930 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 25`** (5 nodes): `GeneratedPluginRegistrant.java`, `GeneratedPluginRegistrant.m`, `GeneratedPluginRegistrant`, `.registerWith()`, `-registerWithRegistry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (4 nodes): `flutter_lldb_helper.py`, `handle_new_rx_page()`, `__lldb_init_module()`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 29`** (3 nodes): `MainActivity.kt`, `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 30`** (3 nodes): `verifier-google-signin.py`, `main()`, `sha1_du_keystore()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 31`** (2 nodes): `KasedConstants`, `constants.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 32`** (2 nodes): `InsForgeConfig`, `insforge_config.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 33`** (2 nodes): `AppNotification`, `app_notification.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 3` to `Community 1`, `Community 2`, `Community 4`, `Community 5`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 12`, `Community 13`, `Community 18`, `Community 19`?**
  _High betweenness centrality (0.221) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Community 9` to `Community 0`, `Community 1`, `Community 2`, `Community 4`, `Community 5`, `Community 7`, `Community 8`, `Community 12`, `Community 13`, `Community 19`?**
  _High betweenness centrality (0.095) - this node is a cross-community bridge._
- **Why does `package:kased_app/models/cotisation.dart` connect `Community 1` to `Community 0`, `Community 2`, `Community 4`, `Community 5`, `Community 17`, `Community 19`?**
  _High betweenness centrality (0.070) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `KasedApp` to the rest of the system?**
  _935 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
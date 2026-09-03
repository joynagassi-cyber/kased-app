# Graph Report - kased-app-new  (2026-09-03)

## Corpus Check
- 194 files · ~564,684 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1380 nodes · 1866 edges · 49 communities detected
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
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 72|Community 72]]
- [[_COMMUNITY_Community 73|Community 73]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 66 edges
2. `package:kased_app/models/membre.dart` - 38 edges
3. `package:flutter_riverpod/flutter_riverpod.dart` - 35 edges
4. `package:kased_app/models/cotisation.dart` - 33 edges
5. `package:flutter_test/flutter_test.dart` - 32 edges
6. `package:kased_app/models/culte.dart` - 31 edges
7. `package:kased_app/core/theme/app_theme.dart` - 27 edges
8. `package:kased_app/providers/kased_app_provider.dart` - 25 edges
9. `package:flutter/foundation.dart` - 20 edges
10. `dart:async` - 17 edges

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
Nodes (131): _notificationIdFor, NotificationService, KasedExportService, IsarLocalCache, _pickCotisation, _pickCulte, _pickMembre, LocalCache (+123 more)

### Community 1 - "Community 1"
Cohesion: 0.03
Nodes (102): ThemeModeNotifier, build, initState, _isRegistered, _maybeShowDialog, OneSignalVerificationGate, _OneSignalVerificationGateState, _setupSubscriptionObserver (+94 more)

### Community 2 - "Community 2"
Cohesion: 0.02
Nodes (88): AnimatedAppear, build, AvatarService, Color, colorFromEmail, generateFromEmail, initialsFromEmail, AppColors (+80 more)

### Community 3 - "Community 3"
Cohesion: 0.03
Nodes (77): AlertDialog, build, _buildFilterBar, _confirmDeleteCulte, Container, CultesScreen, _CultesScreenState, _DatePickerTile (+69 more)

### Community 4 - "Community 4"
Cohesion: 0.03
Nodes (54): app_update_model.dart, AppPrefs, AppPrefsKey, _check, addListener, addPresenceListener, disconnect, _handleDataEvent (+46 more)

### Community 5 - "Community 5"
Cohesion: 0.04
Nodes (47): AppAnimDurations, AppSprings, AnimatedContainer, build, _buildBottomBar, _buildTopBar, dispose, _finish (+39 more)

### Community 6 - "Community 6"
Cohesion: 0.04
Nodes (45): _asList, _asSingle, InsForgeService, StateError, calculerMontantDu, calculerNombreRetards, CotisationLogic, determinerStatut (+37 more)

### Community 7 - "Community 7"
Cohesion: 0.04
Nodes (47): build, Center, Consumer, DashboardScreen, _DashboardScreenState, Divider, DraggableScrollableSheet, initState (+39 more)

### Community 8 - "Community 8"
Cohesion: 0.05
Nodes (43): build, dispose, initState, LoginScreen, _LoginScreenState, MotionAware, Scaffold, SizedBox (+35 more)

### Community 9 - "Community 9"
Cohesion: 0.05
Nodes (40): addNotificationClickListener, addPushSubscriptionObserver, OneSignalService, setLogLevel, _BouncingScrollBehavior, BouncingScrollPhysics, build, didChangeAppLifecycleState (+32 more)

### Community 10 - "Community 10"
Cohesion: 0.06
Nodes (34): CotisationExportService, _saveAndShareCsv, _getStatutText, MemberReportExportService, _getStatutColor, _getStatutText, MemberReportPdfService, _saveAndShare (+26 more)

### Community 11 - "Community 11"
Cohesion: 0.05
Nodes (36): AlertDialog, build, _buildFilterBar, _checkForNewMember, Column, _confirmDelete, Container, dispose (+28 more)

### Community 12 - "Community 12"
Cohesion: 0.05
Nodes (36): AddPaymentAdvance, BulkSetPaiements, connectRealtime, CreateCulte, CreateMember, DeleteCulte, DeleteMember, disconnectRealtime (+28 more)

### Community 13 - "Community 13"
Cohesion: 0.06
Nodes (32): build, _Card, Container, dispose, GestureDetector, initState, Padding, ProfileScreen (+24 more)

### Community 14 - "Community 14"
Cohesion: 0.09
Nodes (25): FlutterWindow(), OnCreate(), RegisterPlugins(), wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), Create() (+17 more)

### Community 15 - "Community 15"
Cohesion: 0.06
Nodes (28): CorbeilleItem, copyWith, Cotisation, fromJson, _statutToString, _stringToStatut, Culte, fromJson (+20 more)

### Community 16 - "Community 16"
Cohesion: 0.06
Nodes (30): annulerAnniversaireMembre, Function, NotificationCoordinator, notifierAbsentMarque, notifierAbsentMarqueFull, notifierCreationCulte, notifierCreationCulteFull, notifierCreationMembre (+22 more)

### Community 17 - "Community 17"
Cohesion: 0.06
Nodes (28): build, CulteDetailScreen, _CulteDetailScreenState, EmptyState, MemberPayTile, Padding, Scaffold, SizedBox (+20 more)

### Community 18 - "Community 18"
Cohesion: 0.08
Nodes (24): _cotisationAttach, _cotisationDeserialize, _cotisationEstimateSize, _cotisationGetId, _cotisationSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+16 more)

### Community 19 - "Community 19"
Cohesion: 0.08
Nodes (23): AddPaymentAdvance, BulkSetPaiements, CreateCulte, CreateMember, DeleteCulte, DeleteMember, EmptyTrash, GetCotisationsDuCulte (+15 more)

### Community 20 - "Community 20"
Cohesion: 0.09
Nodes (21): _culteAttach, _culteDeserialize, _culteEstimateSize, _culteGetId, _culteSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+13 more)

### Community 21 - "Community 21"
Cohesion: 0.09
Nodes (21): deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync, deleteByIdSync, deleteByIndex, deleteByIndexSync, getAllByIndex, getAllByIndexSync (+13 more)

### Community 22 - "Community 22"
Cohesion: 0.11
Nodes (18): addListener, cleanup, init, markOffline, _onPresenceUpdate, PresenceService, removeListener, build (+10 more)

### Community 23 - "Community 23"
Cohesion: 0.12
Nodes (13): build, _buildPermissionItem, Container, CustomGoogleSignInButton, GoogleConsentInfo, Icon, Padding, SizedBox (+5 more)

### Community 24 - "Community 24"
Cohesion: 0.12
Nodes (15): Auth, AuthState, build, _checkPersistedAuth, copyWith, Exception, FlutterSecureStorage, _isTokenExpired (+7 more)

### Community 25 - "Community 25"
Cohesion: 0.13
Nodes (14): build, Container, HistoriqueItem, MembreDetailScreen, _MembreDetailScreenState, Padding, Scaffold, SizedBox (+6 more)

### Community 26 - "Community 26"
Cohesion: 0.12
Nodes (15): AnimatedBuilder, build, Container, CulteDetailSkeleton, DashboardSkeleton, dispose, initState, ListView (+7 more)

### Community 27 - "Community 27"
Cohesion: 0.13
Nodes (14): AnimatedContainer, BatchPaymentDialog, _BatchPaymentDialogState, build, Dialog, dispose, Function, Icon (+6 more)

### Community 28 - "Community 28"
Cohesion: 0.17
Nodes (9): FakeNotifyAdapter, hasEventType, NoOpNotifyAdapter, NotificationEvent, NotifyPort, RealNotifyAdapter, send, toString (+1 more)

### Community 29 - "Community 29"
Cohesion: 0.24
Nodes (11): find_dependencies(), find_dependents(), load_graph(), main(), query_edges(), query_nodes(), Query the extended graph for specific questions. Usage: python3 graphify-out/que, Filter nodes by criteria. (+3 more)

### Community 30 - "Community 30"
Cohesion: 0.25
Nodes (6): CulteLock, isLocked, isPaymentLocked, main, package:kased_app/core/constants.dart, package:kased_app/core/logic/culte_lock.dart

### Community 31 - "Community 31"
Cohesion: 0.29
Nodes (6): _corbeilleItemAttach, _corbeilleItemDeserialize, _corbeilleItemEstimateSize, _corbeilleItemGetId, _corbeilleItemSerialize, IsarError

### Community 32 - "Community 32"
Cohesion: 0.29
Nodes (6): IsarError, _syncOperationAttach, _syncOperationDeserialize, _syncOperationEstimateSize, _syncOperationGetId, _syncOperationSerialize

### Community 33 - "Community 33"
Cohesion: 0.33
Nodes (1): AppUpdatePlugin

### Community 34 - "Community 34"
Cohesion: 0.4
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 35 - "Community 35"
Cohesion: 0.4
Nodes (4): copyWith, DevicePresence, PresenceState, RealtimeEvent

### Community 36 - "Community 36"
Cohesion: 0.5
Nodes (4): node_label_to_file(), normalize_path(), Build an extended semantic graph for the Kased App project. Combines the existin, Some nodes have label = the file path itself.

### Community 37 - "Community 37"
Cohesion: 0.5
Nodes (1): MainActivity

### Community 38 - "Community 38"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 39 - "Community 39"
Cohesion: 0.5
Nodes (3): AppUpdate, AppUpdateCheckResult, copyWith

### Community 40 - "Community 40"
Cohesion: 0.5
Nodes (3): generate, UuidUtils, dart:math

### Community 41 - "Community 41"
Cohesion: 0.67
Nodes (2): apkAssetName, UpdateConfig

### Community 42 - "Community 42"
Cohesion: 1.0
Nodes (2): main(), sha1_du_keystore()

### Community 43 - "Community 43"
Cohesion: 1.0
Nodes (1): KasedConstants

### Community 44 - "Community 44"
Cohesion: 1.0
Nodes (1): InsForgeConfig

### Community 45 - "Community 45"
Cohesion: 1.0
Nodes (1): InsForgeServicePort

### Community 46 - "Community 46"
Cohesion: 1.0
Nodes (1): AppNotification

### Community 72 - "Community 72"
Cohesion: 1.0
Nodes (1): /cotis_app/lib/... or ../... -> relative lib path or null.

### Community 73 - "Community 73"
Cohesion: 1.0
Nodes (1): Return the short lib-path label for a node, if it belongs to lib/functions.

## Knowledge Gaps
- **1032 isolated node(s):** `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `KasedApp`, `_KasedAppState`, `_BouncingScrollBehavior` (+1027 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 33`** (6 nodes): `AppUpdatePlugin`, `.installApk()`, `.onAttachedToEngine()`, `.onDetachedFromEngine()`, `.onMethodCall()`, `AppUpdatePlugin.kt`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 34`** (5 nodes): `GeneratedPluginRegistrant.java`, `GeneratedPluginRegistrant.m`, `GeneratedPluginRegistrant`, `.registerWith()`, `-registerWithRegistry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 37`** (4 nodes): `MainActivity.kt`, `MainActivity.kt`, `MainActivity`, `.configureFlutterEngine()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 38`** (4 nodes): `flutter_lldb_helper.py`, `handle_new_rx_page()`, `__lldb_init_module()`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (3 nodes): `apkAssetName`, `UpdateConfig`, `update_config.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (3 nodes): `verifier-google-signin.py`, `main()`, `sha1_du_keystore()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (2 nodes): `KasedConstants`, `constants.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 44`** (2 nodes): `InsForgeConfig`, `insforge_config.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 45`** (2 nodes): `InsForgeServicePort`, `insforge_service_port.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 46`** (2 nodes): `AppNotification`, `app_notification.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 72`** (1 nodes): `/cotis_app/lib/... or ../... -> relative lib path or null.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 73`** (1 nodes): `Return the short lib-path label for a node, if it belongs to lib/functions.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 2` to `Community 1`, `Community 3`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 13`, `Community 15`, `Community 17`, `Community 23`, `Community 25`, `Community 26`, `Community 27`?**
  _High betweenness centrality (0.278) - this node is a cross-community bridge._
- **Why does `package:kased_app/models/membre.dart` connect `Community 0` to `Community 1`, `Community 3`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 16`, `Community 17`, `Community 25`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Community 1` to `Community 0`, `Community 3`, `Community 4`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 13`, `Community 15`, `Community 17`, `Community 25`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `KasedApp` to the rest of the system?**
  _1032 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
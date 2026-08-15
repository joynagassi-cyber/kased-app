# Graph Report - kased-app-new  (2026-08-16)

## Corpus Check
- 138 files · ~394,621 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1014 nodes · 1370 edges · 32 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 9 edges (avg confidence: 0.8)
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

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 56 edges
2. `package:flutter_riverpod/flutter_riverpod.dart` - 36 edges
3. `package:kased_app/providers/app_data_provider.dart` - 28 edges
4. `package:flutter_test/flutter_test.dart` - 24 edges
5. `package:kased_app/models/membre.dart` - 20 edges
6. `package:kased_app/core/theme/app_theme.dart` - 20 edges
7. `package:kased_app/models/culte.dart` - 19 edges
8. `package:kased_app/models/cotisation.dart` - 18 edges
9. `package:mocktail/mocktail.dart` - 17 edges
10. `package:kased_app/providers/auth_provider.dart` - 14 edges

## Surprising Connections (you probably didn't know these)
- `RegisterPlugins()` --calls--> `OnCreate()`  [INFERRED]
  C:\Users\joyda\ZCodeProject\kased-app\cotis_app\windows\flutter\generated_plugin_registrant.cc → cotis_app\windows\runner\flutter_window.cpp
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
Cohesion: 0.03
Nodes (95): getPendingSyncOpsSync, IsarLocalCache, _pickCotisation, _pickCulte, _pickMembre, getPendingSyncOpsSync, LocalCache, _notificationIdFor (+87 more)

### Community 1 - "Community 1"
Cohesion: 0.03
Nodes (92): addNotificationClickListener, addPushSubscriptionObserver, OneSignalService, setLogLevel, CollecteParMois, DonneesGraphiques, MembreAssidu, ParticipationParCulte (+84 more)

### Community 2 - "Community 2"
Cohesion: 0.02
Nodes (81): AnimatedAppear, build, AvatarService, Color, colorFromEmail, generateFromEmail, initialsFromEmail, AppColors (+73 more)

### Community 3 - "Community 3"
Cohesion: 0.03
Nodes (79): AlertDialog, build, _confirmDeleteCulte, Container, CultesScreen, CustomScrollView, _DatePickerTile, EmptyState (+71 more)

### Community 4 - "Community 4"
Cohesion: 0.04
Nodes (56): AlertDialog, build, _buildStatCard, FlDotCirclePainter, FlLine, FlSpot, KasedCard, LineTooltipItem (+48 more)

### Community 5 - "Community 5"
Cohesion: 0.04
Nodes (50): calculerMontantDu, calculerNombreRetards, CotisationLogic, determinerStatut, _AuthNotifier, _buildFadeSlidePage, FadeTransition, GoRouter (+42 more)

### Community 6 - "Community 6"
Cohesion: 0.04
Nodes (47): AuthService, Duration, Exception, _requireAnonKey, build, didUpdateWidget, dispose, initState (+39 more)

### Community 7 - "Community 7"
Cohesion: 0.05
Nodes (38): _asList, _asSingle, InsForgeService, StateError, build, dispose, initState, LoginScreen (+30 more)

### Community 8 - "Community 8"
Cohesion: 0.06
Nodes (29): AppNotification, CorbeilleItem, copyWith, Cotisation, fromJson, _statutToString, _stringToStatut, Culte (+21 more)

### Community 9 - "Community 9"
Cohesion: 0.06
Nodes (32): _BouncingScrollBehavior, BouncingScrollPhysics, build, Duration, getScrollPhysics, initializeDateFormatting, KasedApp, ProviderScope (+24 more)

### Community 10 - "Community 10"
Cohesion: 0.09
Nodes (25): FlutterWindow(), OnCreate(), RegisterPlugins(), wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), Create() (+17 more)

### Community 11 - "Community 11"
Cohesion: 0.07
Nodes (29): CotisationExportService, MembrePaiementStatus, PdfService, _saveAndShare, RegistrePdfService, annulerAnniversaireMembre, getMembreNom, NotificationCoordinator (+21 more)

### Community 12 - "Community 12"
Cohesion: 0.08
Nodes (25): build, _Card, Container, dispose, GestureDetector, initState, Padding, ProfileScreen (+17 more)

### Community 13 - "Community 13"
Cohesion: 0.08
Nodes (24): _cotisationAttach, _cotisationDeserialize, _cotisationEstimateSize, _cotisationGetId, _cotisationSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+16 more)

### Community 14 - "Community 14"
Cohesion: 0.09
Nodes (21): _appNotificationAttach, _appNotificationDeserialize, _appNotificationEstimateSize, _appNotificationGetId, _appNotificationSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+13 more)

### Community 15 - "Community 15"
Cohesion: 0.09
Nodes (21): _culteAttach, _culteDeserialize, _culteEstimateSize, _culteGetId, _culteSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+13 more)

### Community 16 - "Community 16"
Cohesion: 0.09
Nodes (21): deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync, deleteByIdSync, deleteByIndex, deleteByIndexSync, getAllByIndex, getAllByIndexSync (+13 more)

### Community 17 - "Community 17"
Cohesion: 0.12
Nodes (13): build, _buildPermissionItem, Container, CustomGoogleSignInButton, GoogleConsentInfo, Icon, Padding, SizedBox (+5 more)

### Community 18 - "Community 18"
Cohesion: 0.12
Nodes (14): AppPrefs, AppPrefsKey, _check, DeviceService, build, marquerLue, marquerToutesLues, NotificationsNotifier (+6 more)

### Community 19 - "Community 19"
Cohesion: 0.12
Nodes (15): AnimatedBuilder, build, Container, CulteDetailSkeleton, DashboardSkeleton, dispose, initState, ListView (+7 more)

### Community 20 - "Community 20"
Cohesion: 0.13
Nodes (14): AnimatedContainer, BatchPaymentDialog, _BatchPaymentDialogState, build, Dialog, dispose, Function, Icon (+6 more)

### Community 21 - "Community 21"
Cohesion: 0.15
Nodes (12): build, _CadenceCard, Container, _HistoriqueItem, MembreDetailScreen, Padding, paint, _ProgressPainter (+4 more)

### Community 22 - "Community 22"
Cohesion: 0.18
Nodes (10): build, _ensureQueue, Icon, SaisieRapideScreen, _SaisieRapideScreenState, Scaffold, SizedBox, _skipCurrent (+2 more)

### Community 23 - "Community 23"
Cohesion: 0.29
Nodes (6): _corbeilleItemAttach, _corbeilleItemDeserialize, _corbeilleItemEstimateSize, _corbeilleItemGetId, _corbeilleItemSerialize, IsarError

### Community 24 - "Community 24"
Cohesion: 0.29
Nodes (6): IsarError, _syncOperationAttach, _syncOperationDeserialize, _syncOperationEstimateSize, _syncOperationGetId, _syncOperationSerialize

### Community 25 - "Community 25"
Cohesion: 0.4
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 26 - "Community 26"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 27 - "Community 27"
Cohesion: 0.5
Nodes (3): generate, UuidUtils, dart:math

### Community 28 - "Community 28"
Cohesion: 0.67
Nodes (1): MainActivity

### Community 29 - "Community 29"
Cohesion: 1.0
Nodes (2): main(), sha1_du_keystore()

### Community 30 - "Community 30"
Cohesion: 1.0
Nodes (1): KasedConstants

### Community 31 - "Community 31"
Cohesion: 1.0
Nodes (1): InsForgeConfig

## Knowledge Gaps
- **756 isolated node(s):** `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `KasedApp`, `_BouncingScrollBehavior`, `runZonedGuarded` (+751 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 25`** (5 nodes): `GeneratedPluginRegistrant.java`, `GeneratedPluginRegistrant.m`, `GeneratedPluginRegistrant`, `.registerWith()`, `-registerWithRegistry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 26`** (4 nodes): `flutter_lldb_helper.py`, `handle_new_rx_page()`, `__lldb_init_module()`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 28`** (3 nodes): `MainActivity.kt`, `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 29`** (3 nodes): `verifier-google-signin.py`, `main()`, `sha1_du_keystore()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 30`** (2 nodes): `KasedConstants`, `constants.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 31`** (2 nodes): `InsForgeConfig`, `insforge_config.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 2` to `Community 1`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 12`, `Community 17`, `Community 19`, `Community 20`, `Community 21`, `Community 22`?**
  _High betweenness centrality (0.320) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Community 1` to `Community 0`, `Community 3`, `Community 4`, `Community 5`, `Community 7`, `Community 8`, `Community 9`, `Community 12`, `Community 18`, `Community 21`, `Community 22`?**
  _High betweenness centrality (0.106) - this node is a cross-community bridge._
- **Why does `package:kased_app/providers/app_data_provider.dart` connect `Community 1` to `Community 0`, `Community 3`, `Community 4`, `Community 8`, `Community 9`, `Community 11`, `Community 21`, `Community 22`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `KasedApp` to the rest of the system?**
  _756 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
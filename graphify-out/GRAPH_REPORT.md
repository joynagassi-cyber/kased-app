# Graph Report - kased-app  (2026-08-12)

## Corpus Check
- 124 files · ~316,911 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 935 nodes · 1213 edges · 30 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
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

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 49 edges
2. `package:flutter_riverpod/flutter_riverpod.dart` - 29 edges
3. `package:kased_app/providers/app_data_provider.dart` - 22 edges
4. `package:kased_app/models/membre.dart` - 20 edges
5. `package:kased_app/models/culte.dart` - 17 edges
6. `package:kased_app/models/cotisation.dart` - 17 edges
7. `package:flutter_test/flutter_test.dart` - 17 edges
8. `package:kased_app/core/theme/app_theme.dart` - 16 edges
9. `package:go_router/go_router.dart` - 12 edges
10. `package:intl/intl.dart` - 10 edges

## Surprising Connections (you probably didn't know these)
- `OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  cotis_app\windows\runner\flutter_window.cpp → cotis_app\windows\flutter\generated_plugin_registrant.cc
- `OnCreate()` --calls--> `Show()`  [INFERRED]
  cotis_app\windows\runner\flutter_window.cpp → cotis_app\windows\runner\win32_window.cpp
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  cotis_app\windows\runner\main.cpp → cotis_app\windows\runner\utils.cpp
- `wWinMain()` --calls--> `SetQuitOnClose()`  [INFERRED]
  cotis_app\windows\runner\main.cpp → cotis_app\windows\runner\win32_window.cpp
- `OnCreate()` --calls--> `GetClientArea()`  [INFERRED]
  cotis_app\windows\runner\flutter_window.cpp → cotis_app\windows\runner\win32_window.cpp

## Communities

### Community 0 - "Community 0"
Cohesion: 0.03
Nodes (85): CotisationExportService, IsarLocalCache, _pickCotisation, _pickCulte, _pickMembre, LocalCache, MembrePaiementStatus, PdfService (+77 more)

### Community 1 - "Community 1"
Cohesion: 0.03
Nodes (69): build, CulteDetailScreen, _CulteDetailScreenState, EmptyState, MemberPayTile, Padding, Scaffold, SizedBox (+61 more)

### Community 2 - "Community 2"
Cohesion: 0.03
Nodes (63): ajouter, build, marquerLue, marquerToutesLues, NotificationsNotifier, NotificationsState, supprimer, ThemeModeNotifier (+55 more)

### Community 3 - "Community 3"
Cohesion: 0.03
Nodes (63): _asList, _asSingle, InsForgeService, StateError, calculerMontantDu, calculerNombreRetards, CotisationLogic, determinerStatut (+55 more)

### Community 4 - "Community 4"
Cohesion: 0.04
Nodes (47): AppColors, AppTheme, _buildTheme, _displayStyle, ThemeData, build, dispose, initState (+39 more)

### Community 5 - "Community 5"
Cohesion: 0.04
Nodes (50): _ActionButton, build, Center, Column, Consumer, Container, DashboardScreen, _DashboardScreenState (+42 more)

### Community 6 - "Community 6"
Cohesion: 0.04
Nodes (41): AvatarService, Color, colorFromEmail, generateFromEmail, initialsFromEmail, ConfirmActionDialog, ConfirmActionResult, Icon (+33 more)

### Community 7 - "Community 7"
Cohesion: 0.04
Nodes (44): AlertDialog, build, _confirmDeleteCulte, Container, CultesScreen, CustomScrollView, _DatePickerTile, EmptyState (+36 more)

### Community 8 - "Community 8"
Cohesion: 0.05
Nodes (41): generate, UuidUtils, AnimatedBuilder, build, _buildCounterChip, _buildFlight, _buildGlow, _buildGoalChip (+33 more)

### Community 9 - "Community 9"
Cohesion: 0.06
Nodes (29): AppNotification, CorbeilleItem, copyWith, Cotisation, fromJson, _statutToString, _stringToStatut, Culte (+21 more)

### Community 10 - "Community 10"
Cohesion: 0.06
Nodes (33): annulerAnniversaireMembre, NotificationCoordinator, notifierCreationCulte, notifierCreationMembre, notifierDonEnregistre, notifierPaiementsEnMasse, planifierAnniversaireMembre, planifierAnniversairesMembres (+25 more)

### Community 11 - "Community 11"
Cohesion: 0.09
Nodes (25): FlutterWindow(), OnCreate(), RegisterPlugins(), wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), Create() (+17 more)

### Community 12 - "Community 12"
Cohesion: 0.06
Nodes (29): AppAnimDurations, AppSprings, AuthService, Duration, Exception, _requireAnonKey, build, dispose (+21 more)

### Community 13 - "Community 13"
Cohesion: 0.07
Nodes (27): AnimatedSwitcher, build, _buildBottomBar, _buildPage, _celebrate, _ConfettiPainter, _ConfettiPiece, dispose (+19 more)

### Community 14 - "Community 14"
Cohesion: 0.08
Nodes (24): _cotisationAttach, _cotisationDeserialize, _cotisationEstimateSize, _cotisationGetId, _cotisationSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+16 more)

### Community 15 - "Community 15"
Cohesion: 0.09
Nodes (21): _BouncingScrollBehavior, BouncingScrollPhysics, build, Duration, getScrollPhysics, initializeDateFormatting, KasedApp, ProviderScope (+13 more)

### Community 16 - "Community 16"
Cohesion: 0.09
Nodes (21): _culteAttach, _culteDeserialize, _culteEstimateSize, _culteGetId, _culteSerialize, deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync (+13 more)

### Community 17 - "Community 17"
Cohesion: 0.09
Nodes (21): deleteAllByIdSync, deleteAllByIndex, deleteAllByIndexSync, deleteByIdSync, deleteByIndex, deleteByIndexSync, getAllByIndex, getAllByIndexSync (+13 more)

### Community 18 - "Community 18"
Cohesion: 0.12
Nodes (16): _barHeight, build, _buildBar, _buildHeader, _buildProgress, Container, _DashedLinePainter, GestureDetector (+8 more)

### Community 19 - "Community 19"
Cohesion: 0.12
Nodes (15): AnimatedBuilder, build, Container, CulteDetailSkeleton, DashboardSkeleton, dispose, initState, ListView (+7 more)

### Community 20 - "Community 20"
Cohesion: 0.18
Nodes (10): build, _buildPermissionItem, Container, CustomGoogleSignInButton, GoogleConsentInfo, Icon, Padding, SizedBox (+2 more)

### Community 21 - "Community 21"
Cohesion: 0.25
Nodes (6): AppPrefs, AppPrefsKey, _check, DeviceService, package:shared_preferences/shared_preferences.dart, package:uuid/uuid.dart

### Community 22 - "Community 22"
Cohesion: 0.29
Nodes (6): _appNotificationAttach, _appNotificationDeserialize, _appNotificationEstimateSize, _appNotificationGetId, _appNotificationSerialize, IsarError

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
Cohesion: 0.67
Nodes (1): MainActivity

### Community 28 - "Community 28"
Cohesion: 1.0
Nodes (1): KasedConstants

### Community 29 - "Community 29"
Cohesion: 1.0
Nodes (1): InsForgeConfig

## Knowledge Gaps
- **705 isolated node(s):** `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `KasedApp`, `_BouncingScrollBehavior`, `runZonedGuarded` (+700 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 25`** (5 nodes): `GeneratedPluginRegistrant.java`, `GeneratedPluginRegistrant`, `.registerWith()`, `-registerWithRegistry`, `GeneratedPluginRegistrant.m`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 26`** (4 nodes): `handle_new_rx_page()`, `__lldb_init_module()`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `flutter_lldb_helper.py`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (3 nodes): `MainActivity.kt`, `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 28`** (2 nodes): `KasedConstants`, `constants.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 29`** (2 nodes): `InsForgeConfig`, `insforge_config.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 6` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 7`, `Community 8`, `Community 9`, `Community 12`, `Community 13`, `Community 15`, `Community 18`, `Community 19`, `Community 20`?**
  _High betweenness centrality (0.373) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Community 2` to `Community 0`, `Community 1`, `Community 3`, `Community 4`, `Community 5`, `Community 7`, `Community 9`, `Community 15`?**
  _High betweenness centrality (0.098) - this node is a cross-community bridge._
- **Why does `package:kased_app/models/membre.dart` connect `Community 0` to `Community 2`, `Community 1`, `Community 10`, `Community 3`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `KasedApp` to the rest of the system?**
  _705 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
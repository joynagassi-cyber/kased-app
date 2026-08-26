import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/models/culte.dart';
import 'package:kased_app/models/membre.dart';

/// État global de l'application Kased.
///
/// Ce value object est immutable — toutes les mutations créent une nouvelle
/// instance via [copyWith].
class AppState {
  final List<Membre> membres;
  final List<Culte> cultes;
  final List<Cotisation> cotisations;
  final Map<String, dynamic>? dashboard;
  final List<Map<String, dynamic>> retardsMembres;
  final List<Map<String, dynamic>> membresAJour;
  final List<Map<String, dynamic>> historiqueMembre;
  final String? historiqueMembreId;
  final bool isLoading;
  final bool isOffline;
  final String? error;

  AppState({
    this.membres = const [],
    this.cultes = const [],
    this.cotisations = const [],
    this.dashboard,
    this.retardsMembres = const [],
    this.membresAJour = const [],
    this.historiqueMembre = const [],
    this.historiqueMembreId,
    this.isLoading = false,
    this.isOffline = false,
    this.error,
  });

  AppState copyWith({
    List<Membre>? membres,
    List<Culte>? cultes,
    List<Cotisation>? cotisations,
    Map<String, dynamic>? dashboard,
    List<Map<String, dynamic>>? retardsMembres,
    List<Map<String, dynamic>>? membresAJour,
    List<Map<String, dynamic>>? historiqueMembre,
    String? historiqueMembreId,
    bool? isLoading,
    bool? isOffline,
    String? error,
  }) {
    return AppState(
      membres: membres ?? this.membres,
      cultes: cultes ?? this.cultes,
      cotisations: cotisations ?? this.cotisations,
      dashboard: dashboard ?? this.dashboard,
      retardsMembres: retardsMembres ?? this.retardsMembres,
      membresAJour: membresAJour ?? this.membresAJour,
      historiqueMembre: historiqueMembre ?? this.historiqueMembre,
      historiqueMembreId: historiqueMembreId ?? this.historiqueMembreId,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      error: error,
    );
  }
}

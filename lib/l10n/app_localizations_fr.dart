import 'app_localizations.dart';

class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([super.locale = 'fr']);

  @override
  String get appName => 'ParkUp Agent';

  @override
  String get signInToContinue => 'Connectez-vous pour continuer';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get enterUsername => 'Entrez votre nom d\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get enterPassword => 'Entrez votre mot de passe';

  @override
  String get pleaseEnterUsername => 'Veuillez entrer votre nom d\'utilisateur';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get contactAdminForPassword => 'Contactez votre administrateur si vous avez oublie votre mot de passe';

  @override
  String get loginFailed => 'Echec de la connexion. Veuillez reessayer.';

  @override
  String welcomeUser(String name) => 'Bienvenue, $name';

  @override
  String get whatWouldYouLikeToDo => 'Que voulez-vous faire ?';

  @override
  String get checkVehicle => 'Verifier vehicule';

  @override
  String get checkStatusCreateTickets => 'Verifier le statut et creer des contraventions';

  @override
  String get removeSabots => 'Retirer les sabots';

  @override
  String get paidSabotsToRemove => 'Sabots payes a retirer';

  @override
  String get history => 'Historique';

  @override
  String get viewPastTickets => 'Voir les contraventions passees';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String get logout => 'Deconnexion';

  @override
  String get logoutConfirmation => 'Etes-vous sur de vouloir vous deconnecter ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get licensePlate => 'Plaque d\'immatriculation';

  @override
  String get gpsLocationUpdated => 'Position GPS mise a jour';

  @override
  String get couldNotGetGpsLocation => 'Impossible d\'obtenir la position GPS';

  @override
  String get pleaseEnterValidPlate => 'Veuillez entrer une plaque d\'immatriculation valide';

  @override
  String get failedToCheckVehicle => 'Echec de la verification du vehicule. Veuillez reessayer.';

  @override
  String get pleaseSelectParkingZone => 'Veuillez selectionner une zone de stationnement';

  @override
  String get usingZoneLocation => 'Utilisation de la position de la zone (GPS indisponible)';

  @override
  String ticketCreated(String number) => 'Contravention #$number creee';

  @override
  String get failedToCreateTicket => 'Echec de la creation de la contravention. Veuillez reessayer.';

  @override
  String get checking => 'Verification...';

  @override
  String get check => 'Verifier';

  @override
  String get recheck => 'Reverifier';

  @override
  String get newSearch => 'Nouvelle recherche';

  @override
  String get enterPlateThenCheck => 'Entrez la plaque, puis appuyez sur Verifier';

  @override
  String get selectZone => 'Selectionner la zone';

  @override
  String get refreshGps => 'Actualiser le GPS';

  @override
  String expired(String date) => 'Expire : $date';

  @override
  String get error => 'Erreur';

  @override
  String get somethingWentWrong => 'Une erreur s\'est produite';

  @override
  String get tryAgain => 'Reessayer';

  @override
  String get noTicketsYet => 'Aucune contravention';

  @override
  String get ticketsWillAppearHere => 'Les contraventions que vous creez apparaitront ici';

  @override
  String ticketCount(int count) => count == 1 ? '1 contravention' : '$count contraventions';

  @override
  String get goToLocation => 'Aller a l\'emplacement';

  @override
  String get print => 'Imprimer';

  @override
  String get yesterday => 'Hier';

  @override
  String minutesAgo(int count) => 'il y a ${count} min';

  @override
  String hoursAgo(int count) => 'il y a ${count}h';

  @override
  String get printPreview => 'Apercu avant impression';

  @override
  String get shareAsImage => 'Partager comme image';

  @override
  String get parkingTicket => 'CONTRAVENTION DE STATIONNEMENT';

  @override
  String get scanToPay => 'Scanner pour payer';

  @override
  String get viewOnMap => 'Voir sur la carte';

  @override
  String get share => 'Partager';

  @override
  String get bluetoothPrintingComingSoon => 'Impression Bluetooth bientot disponible !';

  @override
  String get failedToShare => 'Echec du partage';

  @override
  String get failedToLoadPrintData => 'Echec du chargement des donnees d\'impression';

  @override
  String get pendingRemovals => 'Retraits en attente';

  @override
  String get confirmRemoval => 'Confirmer le retrait';

  @override
  String markSabotAsRemoved(String plate) => 'Marquer le sabot pour $plate comme retire ?';

  @override
  String get sabotMarkedAsRemoved => 'Sabot marque comme retire';

  @override
  String get allClear => 'Tout est en ordre !';

  @override
  String get noSabotsPendingRemoval => 'Aucun sabot en attente de retrait';

  @override
  String sabotCount(int count) => count == 1 ? '1 sabot a retirer' : '$count sabots a retirer';

  @override
  String get paid => 'PAYE';

  @override
  String paidTime(String time) => 'Paye $time';

  @override
  String get navigate => 'Naviguer';

  @override
  String get removed => 'Retire';

  @override
  String get failedToLoadPendingRemovals => 'Echec du chargement des retraits en attente';

  @override
  String get failedToLoadTickets => 'Echec du chargement des contraventions';

  @override
  String get refresh => 'Actualiser';
}

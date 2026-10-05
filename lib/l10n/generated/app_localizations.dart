import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'GWENT'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'The Witcher Card Game'**
  String get appTagline;

  /// No description provided for @appAbout.
  ///
  /// In en, this message translates to:
  /// **'A cross-platform Flutter implementation of classic Gwent: three rounds, two armies, one deck.'**
  String get appAbout;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @newMatch.
  ///
  /// In en, this message translates to:
  /// **'New match'**
  String get newMatch;

  /// No description provided for @continueMatch.
  ///
  /// In en, this message translates to:
  /// **'Continue match'**
  String get continueMatch;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @threeDifficultyLevels.
  ///
  /// In en, this message translates to:
  /// **'3 difficulty levels'**
  String get threeDifficultyLevels;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @classicRules.
  ///
  /// In en, this message translates to:
  /// **'Classic rules'**
  String get classicRules;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'v0.1.0'**
  String get version;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @deckCollection.
  ///
  /// In en, this message translates to:
  /// **'Deck collection'**
  String get deckCollection;

  /// No description provided for @manageDecks.
  ///
  /// In en, this message translates to:
  /// **'Manage decks'**
  String get manageDecks;

  /// No description provided for @recentDecks.
  ///
  /// In en, this message translates to:
  /// **'Recent decks'**
  String get recentDecks;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get backToMenu;

  /// No description provided for @opponentDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Opponent difficulty'**
  String get opponentDifficulty;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @difficultyEasyDescription.
  ///
  /// In en, this message translates to:
  /// **'Plays greedily and passes late; a forgiving opponent.'**
  String get difficultyEasyDescription;

  /// No description provided for @difficultyNormalDescription.
  ///
  /// In en, this message translates to:
  /// **'Competent trades and sensible passing decisions.'**
  String get difficultyNormalDescription;

  /// No description provided for @difficultyHardDescription.
  ///
  /// In en, this message translates to:
  /// **'Strong sequencing, holds finishers and passes at the right time.'**
  String get difficultyHardDescription;

  /// No description provided for @faction.
  ///
  /// In en, this message translates to:
  /// **'Faction'**
  String get faction;

  /// No description provided for @factionRealms.
  ///
  /// In en, this message translates to:
  /// **'Northern Realms'**
  String get factionRealms;

  /// No description provided for @factionNilfgaard.
  ///
  /// In en, this message translates to:
  /// **'Nilfgaard'**
  String get factionNilfgaard;

  /// No description provided for @factionMonsters.
  ///
  /// In en, this message translates to:
  /// **'Monsters'**
  String get factionMonsters;

  /// No description provided for @factionScoiatael.
  ///
  /// In en, this message translates to:
  /// **'Scoia\'tael'**
  String get factionScoiatael;

  /// No description provided for @factionSkellige.
  ///
  /// In en, this message translates to:
  /// **'Skellige'**
  String get factionSkellige;

  /// No description provided for @startMatch.
  ///
  /// In en, this message translates to:
  /// **'Start match'**
  String get startMatch;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start game'**
  String get startGame;

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @won.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get won;

  /// No description provided for @losses.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get losses;

  /// No description provided for @draws.
  ///
  /// In en, this message translates to:
  /// **'Drawn'**
  String get draws;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get winRate;

  /// No description provided for @noMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches played yet'**
  String get noMatchesYet;

  /// No description provided for @resetStats.
  ///
  /// In en, this message translates to:
  /// **'Reset statistics'**
  String get resetStats;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'cards'**
  String get cards;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'strength'**
  String get strength;

  /// No description provided for @deckEditor.
  ///
  /// In en, this message translates to:
  /// **'Deck editor'**
  String get deckEditor;

  /// No description provided for @deck.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get deck;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// No description provided for @deckStats.
  ///
  /// In en, this message translates to:
  /// **'Deck stats'**
  String get deckStats;

  /// No description provided for @leader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get leader;

  /// No description provided for @changeLeader.
  ///
  /// In en, this message translates to:
  /// **'Change leader'**
  String get changeLeader;

  /// No description provided for @leaderAbility.
  ///
  /// In en, this message translates to:
  /// **'Leader ability'**
  String get leaderAbility;

  /// No description provided for @previousLeader.
  ///
  /// In en, this message translates to:
  /// **'Previous leader'**
  String get previousLeader;

  /// No description provided for @nextLeader.
  ///
  /// In en, this message translates to:
  /// **'Next leader'**
  String get nextLeader;

  /// No description provided for @factionAbility.
  ///
  /// In en, this message translates to:
  /// **'Faction ability'**
  String get factionAbility;

  /// No description provided for @saveDeck.
  ///
  /// In en, this message translates to:
  /// **'Save deck'**
  String get saveDeck;

  /// No description provided for @addCopy.
  ///
  /// In en, this message translates to:
  /// **'Add copy'**
  String get addCopy;

  /// No description provided for @removeCopy.
  ///
  /// In en, this message translates to:
  /// **'Remove one'**
  String get removeCopy;

  /// No description provided for @atCopyLimit.
  ///
  /// In en, this message translates to:
  /// **'At copy limit'**
  String get atCopyLimit;

  /// No description provided for @inDeckCount.
  ///
  /// In en, this message translates to:
  /// **'{copies} of {max} in deck'**
  String inDeckCount(int copies, int max);

  /// No description provided for @deckEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to add · long-press for the full ability'**
  String get deckEditorHint;

  /// No description provided for @noCardsFound.
  ///
  /// In en, this message translates to:
  /// **'No cards match your filters'**
  String get noCardsFound;

  /// No description provided for @localMatch.
  ///
  /// In en, this message translates to:
  /// **'Local match'**
  String get localMatch;

  /// No description provided for @lanMatch.
  ///
  /// In en, this message translates to:
  /// **'LAN match'**
  String get lanMatch;

  /// No description provided for @hostMatch.
  ///
  /// In en, this message translates to:
  /// **'Host match'**
  String get hostMatch;

  /// No description provided for @joinMatch.
  ///
  /// In en, this message translates to:
  /// **'Join match'**
  String get joinMatch;

  /// No description provided for @hosting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a guest to join…'**
  String get hosting;

  /// No description provided for @searchingHosts.
  ///
  /// In en, this message translates to:
  /// **'Searching the local network…'**
  String get searchingHosts;

  /// No description provided for @joinAddress.
  ///
  /// In en, this message translates to:
  /// **'Host address'**
  String get joinAddress;

  /// No description provided for @noHostsFound.
  ///
  /// In en, this message translates to:
  /// **'No match found on this network'**
  String get noHostsFound;

  /// No description provided for @lobbyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the match'**
  String get lobbyFailed;

  /// No description provided for @cancelHosting.
  ///
  /// In en, this message translates to:
  /// **'Stop hosting'**
  String get cancelHosting;

  /// No description provided for @playerSeat.
  ///
  /// In en, this message translates to:
  /// **'Player {seat}'**
  String playerSeat(int seat);

  /// No description provided for @passDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Pass the device to {name}'**
  String passDeviceTitle(String name);

  /// No description provided for @passDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'The next hand stays hidden until the next player is ready.'**
  String get passDeviceHint;

  /// No description provided for @passDeviceReady.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready'**
  String get passDeviceReady;

  /// No description provided for @commandWrongPhase.
  ///
  /// In en, this message translates to:
  /// **'This action is not available right now.'**
  String get commandWrongPhase;

  /// No description provided for @commandNotYourTurn.
  ///
  /// In en, this message translates to:
  /// **'It is not your turn.'**
  String get commandNotYourTurn;

  /// No description provided for @commandPlayerPassed.
  ///
  /// In en, this message translates to:
  /// **'You have already passed this round.'**
  String get commandPlayerPassed;

  /// No description provided for @commandUnknownCard.
  ///
  /// In en, this message translates to:
  /// **'That card is no longer in play.'**
  String get commandUnknownCard;

  /// No description provided for @commandCardNotInHand.
  ///
  /// In en, this message translates to:
  /// **'That card is not in your hand.'**
  String get commandCardNotInHand;

  /// No description provided for @commandRowOccupied.
  ///
  /// In en, this message translates to:
  /// **'That row already has a card in its special slot.'**
  String get commandRowOccupied;

  /// No description provided for @commandNoTarget.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid target first.'**
  String get commandNoTarget;

  /// No description provided for @commandLeaderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your leader ability is no longer available.'**
  String get commandLeaderUnavailable;

  /// No description provided for @commandNoRedrawsLeft.
  ///
  /// In en, this message translates to:
  /// **'You have no redraws left.'**
  String get commandNoRedrawsLeft;

  /// No description provided for @commandAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'You have already confirmed that step.'**
  String get commandAlreadyDone;

  /// No description provided for @commandChoiceNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'That decision is not yours to make.'**
  String get commandChoiceNotAllowed;

  /// No description provided for @commandInvalidChoice.
  ///
  /// In en, this message translates to:
  /// **'That choice is not valid.'**
  String get commandInvalidChoice;

  /// No description provided for @commandInvalidTargetRow.
  ///
  /// In en, this message translates to:
  /// **'That card cannot be placed on the chosen row.'**
  String get commandInvalidTargetRow;

  /// No description provided for @searchCollection.
  ///
  /// In en, this message translates to:
  /// **'Search collection'**
  String get searchCollection;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get filterUnits;

  /// No description provided for @filterSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get filterSpecial;

  /// No description provided for @filterWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get filterWeather;

  /// No description provided for @filterHeroes.
  ///
  /// In en, this message translates to:
  /// **'Heroes'**
  String get filterHeroes;

  /// No description provided for @filterOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get filterOwned;

  /// No description provided for @totalCards.
  ///
  /// In en, this message translates to:
  /// **'Total cards'**
  String get totalCards;

  /// No description provided for @unitCards.
  ///
  /// In en, this message translates to:
  /// **'Unit cards'**
  String get unitCards;

  /// No description provided for @specialCards.
  ///
  /// In en, this message translates to:
  /// **'Special cards'**
  String get specialCards;

  /// No description provided for @heroCards.
  ///
  /// In en, this message translates to:
  /// **'Hero cards'**
  String get heroCards;

  /// No description provided for @totalStrength.
  ///
  /// In en, this message translates to:
  /// **'Total strength'**
  String get totalStrength;

  /// No description provided for @deckValid.
  ///
  /// In en, this message translates to:
  /// **'Deck is valid — ready to play'**
  String get deckValid;

  /// No description provided for @deckInvalid.
  ///
  /// In en, this message translates to:
  /// **'Deck is not valid yet'**
  String get deckInvalid;

  /// No description provided for @deckIssueTooFewUnits.
  ///
  /// In en, this message translates to:
  /// **'Needs at least {min} unit cards'**
  String deckIssueTooFewUnits(int min);

  /// No description provided for @deckIssueTooManySpecial.
  ///
  /// In en, this message translates to:
  /// **'At most {max} special cards'**
  String deckIssueTooManySpecial(int max);

  /// No description provided for @deckIssueTooManyCards.
  ///
  /// In en, this message translates to:
  /// **'At most {max} cards in total'**
  String deckIssueTooManyCards(int max);

  /// No description provided for @deckIssueLeaderFaction.
  ///
  /// In en, this message translates to:
  /// **'The leader does not match the faction'**
  String get deckIssueLeaderFaction;

  /// No description provided for @deckIssueCardNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Some cards are not allowed in this faction'**
  String get deckIssueCardNotAllowed;

  /// No description provided for @deckIssueTooManyCopies.
  ///
  /// In en, this message translates to:
  /// **'Some cards exceed the owned copies'**
  String get deckIssueTooManyCopies;

  /// No description provided for @deckIssueUnknownCard.
  ///
  /// In en, this message translates to:
  /// **'The deck contains an unknown card'**
  String get deckIssueUnknownCard;

  /// No description provided for @invalidDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'Deck not playable'**
  String get invalidDeckTitle;

  /// No description provided for @openDeckEditor.
  ///
  /// In en, this message translates to:
  /// **'Open deck editor'**
  String get openDeckEditor;

  /// No description provided for @cardsOwned.
  ///
  /// In en, this message translates to:
  /// **'{owned} cards owned · {distinct} distinct'**
  String cardsOwned(int owned, int distinct);

  /// No description provided for @cardsInDeck.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} cards'**
  String cardsInDeck(int count, int max);

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get round;

  /// No description provided for @roundOf.
  ///
  /// In en, this message translates to:
  /// **'Round {current} of {total}'**
  String roundOf(int current, int total);

  /// No description provided for @roundShort.
  ///
  /// In en, this message translates to:
  /// **'R{round}'**
  String roundShort(int round);

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @opponentTurn.
  ///
  /// In en, this message translates to:
  /// **'Opponent turn'**
  String get opponentTurn;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @passRound.
  ///
  /// In en, this message translates to:
  /// **'Pass round'**
  String get passRound;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @cardsInHand.
  ///
  /// In en, this message translates to:
  /// **'Cards in hand'**
  String get cardsInHand;

  /// No description provided for @deckPile.
  ///
  /// In en, this message translates to:
  /// **'Deck'**
  String get deckPile;

  /// No description provided for @gravePile.
  ///
  /// In en, this message translates to:
  /// **'Grave'**
  String get gravePile;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @leaderReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get leaderReady;

  /// No description provided for @leaderUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get leaderUsed;

  /// No description provided for @leaderPassive.
  ///
  /// In en, this message translates to:
  /// **'Passive'**
  String get leaderPassive;

  /// No description provided for @cardPreview.
  ///
  /// In en, this message translates to:
  /// **'Card preview'**
  String get cardPreview;

  /// No description provided for @matchScore.
  ///
  /// In en, this message translates to:
  /// **'Match score'**
  String get matchScore;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @playCard.
  ///
  /// In en, this message translates to:
  /// **'Play card'**
  String get playCard;

  /// No description provided for @tapCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap a card for details'**
  String get tapCardDetails;

  /// No description provided for @selectRowHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a row'**
  String get selectRowHint;

  /// No description provided for @selectTargetHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a target'**
  String get selectTargetHint;

  /// No description provided for @selectDiscardHint.
  ///
  /// In en, this message translates to:
  /// **'Discard {count} cards'**
  String selectDiscardHint(int count);

  /// No description provided for @selectDrawHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a card to draw'**
  String get selectDrawHint;

  /// No description provided for @confirmSelection.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmSelection;

  /// No description provided for @mulliganTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {count} cards to redraw'**
  String mulliganTitle(int count);

  /// No description provided for @mulliganConfirm.
  ///
  /// In en, this message translates to:
  /// **'Keep hand'**
  String get mulliganConfirm;

  /// No description provided for @waitingAi.
  ///
  /// In en, this message translates to:
  /// **'Opponent is thinking…'**
  String get waitingAi;

  /// No description provided for @roundWon.
  ///
  /// In en, this message translates to:
  /// **'Round won'**
  String get roundWon;

  /// No description provided for @roundLost.
  ///
  /// In en, this message translates to:
  /// **'Round lost'**
  String get roundLost;

  /// No description provided for @roundDrawn.
  ///
  /// In en, this message translates to:
  /// **'Round drawn'**
  String get roundDrawn;

  /// No description provided for @victory.
  ///
  /// In en, this message translates to:
  /// **'Victory'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get defeat;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @winnerYou.
  ///
  /// In en, this message translates to:
  /// **'You win the match'**
  String get winnerYou;

  /// No description provided for @winnerOpponent.
  ///
  /// In en, this message translates to:
  /// **'{name} wins the match'**
  String winnerOpponent(String name);

  /// No description provided for @matchDrawn.
  ///
  /// In en, this message translates to:
  /// **'The match is a draw'**
  String get matchDrawn;

  /// No description provided for @finalScore.
  ///
  /// In en, this message translates to:
  /// **'Final score'**
  String get finalScore;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @notPlayed.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get notPlayed;

  /// No description provided for @clearWeatherNotPlayed.
  ///
  /// In en, this message translates to:
  /// **'Clear Weather not played'**
  String get clearWeatherNotPlayed;

  /// No description provided for @weatherRowAtOne.
  ///
  /// In en, this message translates to:
  /// **'{row} at 1'**
  String weatherRowAtOne(String row);

  /// No description provided for @pointsAbbrev.
  ///
  /// In en, this message translates to:
  /// **'{value} str'**
  String pointsAbbrev(int value);

  /// No description provided for @opponentSummary.
  ///
  /// In en, this message translates to:
  /// **'{faction} · {difficulty} AI'**
  String opponentSummary(String faction, String difficulty);

  /// No description provided for @handAndDeckHint.
  ///
  /// In en, this message translates to:
  /// **'{name} has {hand} cards in hand · {deck} in deck'**
  String handAndDeckHint(String name, int hand, int deck);

  /// No description provided for @spyDraw.
  ///
  /// In en, this message translates to:
  /// **'Spy: drawing 2 cards'**
  String get spyDraw;

  /// No description provided for @muster.
  ///
  /// In en, this message translates to:
  /// **'Muster: playing matching cards'**
  String get muster;

  /// No description provided for @medic.
  ///
  /// In en, this message translates to:
  /// **'Medic: choosing a card to revive'**
  String get medic;

  /// No description provided for @scorch.
  ///
  /// In en, this message translates to:
  /// **'Scorch!'**
  String get scorch;

  /// No description provided for @decoy.
  ///
  /// In en, this message translates to:
  /// **'Decoy swapped'**
  String get decoy;

  /// No description provided for @rowClose.
  ///
  /// In en, this message translates to:
  /// **'Close Combat'**
  String get rowClose;

  /// No description provided for @rowRanged.
  ///
  /// In en, this message translates to:
  /// **'Ranged Combat'**
  String get rowRanged;

  /// No description provided for @rowSiege.
  ///
  /// In en, this message translates to:
  /// **'Siege Combat'**
  String get rowSiege;

  /// No description provided for @rowAgile.
  ///
  /// In en, this message translates to:
  /// **'Agile'**
  String get rowAgile;

  /// No description provided for @rowWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get rowWeather;

  /// No description provided for @cardTypeSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special Card'**
  String get cardTypeSpecial;

  /// No description provided for @cardTypeWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather Card'**
  String get cardTypeWeather;

  /// No description provided for @cardTypeHero.
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get cardTypeHero;

  /// No description provided for @cardTypeLeader.
  ///
  /// In en, this message translates to:
  /// **'Leader Ability'**
  String get cardTypeLeader;

  /// No description provided for @tagHero.
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get tagHero;

  /// No description provided for @tagSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get tagSpecial;

  /// No description provided for @tagWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get tagWeather;

  /// No description provided for @abilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Ability'**
  String get abilityLabel;

  /// No description provided for @abilityTagBond.
  ///
  /// In en, this message translates to:
  /// **'Tight Bond'**
  String get abilityTagBond;

  /// No description provided for @abilityTagSpy.
  ///
  /// In en, this message translates to:
  /// **'Spy'**
  String get abilityTagSpy;

  /// No description provided for @abilityTagMedic.
  ///
  /// In en, this message translates to:
  /// **'Medic'**
  String get abilityTagMedic;

  /// No description provided for @abilityTagMorale.
  ///
  /// In en, this message translates to:
  /// **'Morale'**
  String get abilityTagMorale;

  /// No description provided for @abilityTagMuster.
  ///
  /// In en, this message translates to:
  /// **'Muster'**
  String get abilityTagMuster;

  /// No description provided for @abilityTagAvenger.
  ///
  /// In en, this message translates to:
  /// **'Avenger'**
  String get abilityTagAvenger;

  /// No description provided for @abilityTagBerserker.
  ///
  /// In en, this message translates to:
  /// **'Berserker'**
  String get abilityTagBerserker;

  /// No description provided for @abilityTagHorn.
  ///
  /// In en, this message translates to:
  /// **'Commander\'s Horn'**
  String get abilityTagHorn;

  /// No description provided for @abilityTagMardroeme.
  ///
  /// In en, this message translates to:
  /// **'Mardroeme'**
  String get abilityTagMardroeme;

  /// No description provided for @abilityTagScorch.
  ///
  /// In en, this message translates to:
  /// **'Scorch'**
  String get abilityTagScorch;

  /// No description provided for @abilityTagAgile.
  ///
  /// In en, this message translates to:
  /// **'Agile'**
  String get abilityTagAgile;

  /// No description provided for @abilityHero.
  ///
  /// In en, this message translates to:
  /// **'Not affected by any Special Cards or abilities.'**
  String get abilityHero;

  /// No description provided for @abilityDecoy.
  ///
  /// In en, this message translates to:
  /// **'Swap with a card on the battlefield to return it to your hand.'**
  String get abilityDecoy;

  /// No description provided for @abilityHorn.
  ///
  /// In en, this message translates to:
  /// **'Doubles the strength of all unit cards in that row. Limited to 1 per row.'**
  String get abilityHorn;

  /// No description provided for @abilityMardroeme.
  ///
  /// In en, this message translates to:
  /// **'Triggers transformation of all Berserker cards on the same row.'**
  String get abilityMardroeme;

  /// No description provided for @abilityBerserker.
  ///
  /// In en, this message translates to:
  /// **'Transforms into a bear when a Mardroeme card is on its row.'**
  String get abilityBerserker;

  /// No description provided for @abilityScorch.
  ///
  /// In en, this message translates to:
  /// **'Discard after playing. Kills the strongest card(s) on the battlefield.'**
  String get abilityScorch;

  /// No description provided for @abilityScorchClose.
  ///
  /// In en, this message translates to:
  /// **'Destroy your enemy\'s strongest Close Combat unit(s) if the combined strength of all their Close Combat units is 10 or more.'**
  String get abilityScorchClose;

  /// No description provided for @abilityScorchRanged.
  ///
  /// In en, this message translates to:
  /// **'Destroy your enemy\'s strongest Ranged Combat unit(s) if the combined strength of all their Ranged Combat units is 10 or more.'**
  String get abilityScorchRanged;

  /// No description provided for @abilityScorchSiege.
  ///
  /// In en, this message translates to:
  /// **'Destroy your enemy\'s strongest Siege Combat unit(s) if the combined strength of all their Siege Combat units is 10 or more.'**
  String get abilityScorchSiege;

  /// No description provided for @abilityAgile.
  ///
  /// In en, this message translates to:
  /// **'Can be placed in either the Close Combat or the Ranged Combat row. Cannot be moved once placed.'**
  String get abilityAgile;

  /// No description provided for @abilityMuster.
  ///
  /// In en, this message translates to:
  /// **'Find any cards with the same name in your deck and play them instantly.'**
  String get abilityMuster;

  /// No description provided for @abilitySpy.
  ///
  /// In en, this message translates to:
  /// **'Place on your opponent\'s battlefield (counts towards your opponent\'s total) and draw 2 cards from your deck.'**
  String get abilitySpy;

  /// No description provided for @abilityMedic.
  ///
  /// In en, this message translates to:
  /// **'Choose one card from your discard pile and play it instantly (no Heroes or Special Cards).'**
  String get abilityMedic;

  /// No description provided for @abilityMorale.
  ///
  /// In en, this message translates to:
  /// **'Adds +1 to all units in the row (excluding itself).'**
  String get abilityMorale;

  /// No description provided for @abilityBond.
  ///
  /// In en, this message translates to:
  /// **'Place next to a card with the same name to double the strength of both cards.'**
  String get abilityBond;

  /// No description provided for @abilityAvenger.
  ///
  /// In en, this message translates to:
  /// **'When this card is removed from the battlefield, it summons a powerful new Unit Card to take its place.'**
  String get abilityAvenger;

  /// No description provided for @abilityFrost.
  ///
  /// In en, this message translates to:
  /// **'Sets the strength of all Close Combat cards to 1 for both players.'**
  String get abilityFrost;

  /// No description provided for @abilityFog.
  ///
  /// In en, this message translates to:
  /// **'Sets the strength of all Ranged Combat cards to 1 for both players.'**
  String get abilityFog;

  /// No description provided for @abilityRain.
  ///
  /// In en, this message translates to:
  /// **'Sets the strength of all Siege Combat cards to 1 for both players.'**
  String get abilityRain;

  /// No description provided for @abilityClear.
  ///
  /// In en, this message translates to:
  /// **'Removes all Weather Cards (Biting Frost, Impenetrable Fog and Torrential Rain) effects.'**
  String get abilityClear;

  /// No description provided for @leaderFoltestKing.
  ///
  /// In en, this message translates to:
  /// **'Pick an Impenetrable Fog card from your deck and play it instantly.'**
  String get leaderFoltestKing;

  /// No description provided for @leaderFoltestLord.
  ///
  /// In en, this message translates to:
  /// **'Clear any weather effects in play.'**
  String get leaderFoltestLord;

  /// No description provided for @leaderFoltestSiegemaster.
  ///
  /// In en, this message translates to:
  /// **'Doubles the strength of all your Siege units (unless a Commander\'s Horn is also present on that row).'**
  String get leaderFoltestSiegemaster;

  /// No description provided for @leaderFoltestSteelforged.
  ///
  /// In en, this message translates to:
  /// **'Destroy your enemy\'s strongest Siege unit(s) if the combined strength of all their Siege units is 10 or more.'**
  String get leaderFoltestSteelforged;

  /// No description provided for @leaderFoltestSon.
  ///
  /// In en, this message translates to:
  /// **'Destroy your enemy\'s strongest Ranged Combat unit(s) if the combined strength of all their Ranged units is 10 or more.'**
  String get leaderFoltestSon;

  /// No description provided for @leaderEmhyrImperial.
  ///
  /// In en, this message translates to:
  /// **'Pick a Torrential Rain card from your deck and play it instantly.'**
  String get leaderEmhyrImperial;

  /// No description provided for @leaderEmhyrEmperor.
  ///
  /// In en, this message translates to:
  /// **'Look at 3 random cards from your opponent\'s hand.'**
  String get leaderEmhyrEmperor;

  /// No description provided for @leaderEmhyrWhiteflame.
  ///
  /// In en, this message translates to:
  /// **'Cancel your opponent\'s Leader Ability.'**
  String get leaderEmhyrWhiteflame;

  /// No description provided for @leaderEmhyrRelentless.
  ///
  /// In en, this message translates to:
  /// **'Draw a card from your opponent\'s discard pile.'**
  String get leaderEmhyrRelentless;

  /// No description provided for @leaderEmhyrInvader.
  ///
  /// In en, this message translates to:
  /// **'Abilities that restore a unit to the battlefield restore a randomly-chosen unit. Affects both players.'**
  String get leaderEmhyrInvader;

  /// No description provided for @leaderEredinCommander.
  ///
  /// In en, this message translates to:
  /// **'Double the strength of all your Close Combat units (unless a Commander\'s Horn is also present on that row).'**
  String get leaderEredinCommander;

  /// No description provided for @leaderEredinBringer.
  ///
  /// In en, this message translates to:
  /// **'Restore a card from your discard pile to your hand.'**
  String get leaderEredinBringer;

  /// No description provided for @leaderEredinDestroyer.
  ///
  /// In en, this message translates to:
  /// **'Discard 2 cards and draw 1 card of your choice from your deck.'**
  String get leaderEredinDestroyer;

  /// No description provided for @leaderEredinKing.
  ///
  /// In en, this message translates to:
  /// **'Pick any weather card from your deck and play it instantly.'**
  String get leaderEredinKing;

  /// No description provided for @leaderEredinTreacherous.
  ///
  /// In en, this message translates to:
  /// **'Doubles the strength of all spy cards (affects both players).'**
  String get leaderEredinTreacherous;

  /// No description provided for @leaderFrancescaQueen.
  ///
  /// In en, this message translates to:
  /// **'Destroy your enemy\'s strongest Close Combat unit(s) if the combined strength of all their Close Combat units is 10 or more.'**
  String get leaderFrancescaQueen;

  /// No description provided for @leaderFrancescaBeautiful.
  ///
  /// In en, this message translates to:
  /// **'Doubles the strength of all your Ranged Combat units (unless a Commander\'s Horn is also present on that row).'**
  String get leaderFrancescaBeautiful;

  /// No description provided for @leaderFrancescaDaisy.
  ///
  /// In en, this message translates to:
  /// **'Draw an extra card at the beginning of the battle.'**
  String get leaderFrancescaDaisy;

  /// No description provided for @leaderFrancescaPureblood.
  ///
  /// In en, this message translates to:
  /// **'Pick a Biting Frost card from your deck and play it instantly.'**
  String get leaderFrancescaPureblood;

  /// No description provided for @leaderFrancescaHope.
  ///
  /// In en, this message translates to:
  /// **'Move agile units to whichever valid row maximizes their strength.'**
  String get leaderFrancescaHope;

  /// No description provided for @leaderCrachAnCraite.
  ///
  /// In en, this message translates to:
  /// **'Shuffle all cards from each player\'s graveyard back into their decks.'**
  String get leaderCrachAnCraite;

  /// No description provided for @leaderKingBran.
  ///
  /// In en, this message translates to:
  /// **'Units only lose half their Strength in bad weather conditions.'**
  String get leaderKingBran;

  /// No description provided for @factionAbilityRealms.
  ///
  /// In en, this message translates to:
  /// **'Draw a card from your deck whenever you win a round.'**
  String get factionAbilityRealms;

  /// No description provided for @factionAbilityNilfgaard.
  ///
  /// In en, this message translates to:
  /// **'Wins any round that ends in a draw.'**
  String get factionAbilityNilfgaard;

  /// No description provided for @factionAbilityMonsters.
  ///
  /// In en, this message translates to:
  /// **'Keeps a random Unit Card out after each round.'**
  String get factionAbilityMonsters;

  /// No description provided for @factionAbilityScoiatael.
  ///
  /// In en, this message translates to:
  /// **'Decides who takes the first turn.'**
  String get factionAbilityScoiatael;

  /// No description provided for @factionAbilitySkellige.
  ///
  /// In en, this message translates to:
  /// **'2 random cards from the graveyard are placed on the battlefield at the start of the third round.'**
  String get factionAbilitySkellige;

  /// No description provided for @aiOpponent.
  ///
  /// In en, this message translates to:
  /// **'AI opponent'**
  String get aiOpponent;

  /// No description provided for @opponentName.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get opponentName;

  /// No description provided for @opponentDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Opponent disconnected'**
  String get opponentDisconnected;

  /// No description provided for @waitingForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for them to reconnect…'**
  String get waitingForOpponent;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @reconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the host. Try again.'**
  String get reconnectFailed;

  /// No description provided for @opponentGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Opponent lost'**
  String get opponentGoneTitle;

  /// No description provided for @opponentGoneBody.
  ///
  /// In en, this message translates to:
  /// **'The other player did not come back, so the match was abandoned.'**
  String get opponentGoneBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

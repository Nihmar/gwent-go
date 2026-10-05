// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GWENT';

  @override
  String get appTagline => 'The Witcher Card Game';

  @override
  String get appAbout =>
      'A cross-platform Flutter implementation of classic Gwent: three rounds, two armies, one deck.';

  @override
  String get play => 'Play';

  @override
  String get newMatch => 'New match';

  @override
  String get continueMatch => 'Continue match';

  @override
  String get stats => 'Stats';

  @override
  String get threeDifficultyLevels => '3 difficulty levels';

  @override
  String get offline => 'Offline';

  @override
  String get classicRules => 'Classic rules';

  @override
  String get version => 'v0.1.0';

  @override
  String get english => 'English';

  @override
  String get deckCollection => 'Deck collection';

  @override
  String get manageDecks => 'Manage decks';

  @override
  String get recentDecks => 'Recent decks';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get sound => 'Sound';

  @override
  String get menu => 'Menu';

  @override
  String get backToMenu => 'Main menu';

  @override
  String get opponentDifficulty => 'Opponent difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get normal => 'Normal';

  @override
  String get hard => 'Hard';

  @override
  String get difficultyEasyDescription =>
      'Plays greedily and passes late; a forgiving opponent.';

  @override
  String get difficultyNormalDescription =>
      'Competent trades and sensible passing decisions.';

  @override
  String get difficultyHardDescription =>
      'Strong sequencing, holds finishers and passes at the right time.';

  @override
  String get faction => 'Faction';

  @override
  String get factionRealms => 'Northern Realms';

  @override
  String get factionNilfgaard => 'Nilfgaard';

  @override
  String get factionMonsters => 'Monsters';

  @override
  String get factionScoiatael => 'Scoia\'tael';

  @override
  String get factionSkellige => 'Skellige';

  @override
  String get startMatch => 'Start match';

  @override
  String get startGame => 'Start game';

  @override
  String get matches => 'Matches';

  @override
  String get won => 'Won';

  @override
  String get losses => 'Lost';

  @override
  String get draws => 'Drawn';

  @override
  String get winRate => 'Win rate';

  @override
  String get noMatchesYet => 'No matches played yet';

  @override
  String get resetStats => 'Reset statistics';

  @override
  String get language => 'Language';

  @override
  String get pause => 'Pause';

  @override
  String get cards => 'cards';

  @override
  String get strength => 'strength';

  @override
  String get deckEditor => 'Deck editor';

  @override
  String get deck => 'Deck';

  @override
  String get collection => 'Collection';

  @override
  String get deckStats => 'Deck stats';

  @override
  String get leader => 'Leader';

  @override
  String get changeLeader => 'Change leader';

  @override
  String get leaderAbility => 'Leader ability';

  @override
  String get previousLeader => 'Previous leader';

  @override
  String get nextLeader => 'Next leader';

  @override
  String get factionAbility => 'Faction ability';

  @override
  String get saveDeck => 'Save deck';

  @override
  String get addCopy => 'Add copy';

  @override
  String get removeCopy => 'Remove one';

  @override
  String get atCopyLimit => 'At copy limit';

  @override
  String inDeckCount(int copies, int max) {
    return '$copies of $max in deck';
  }

  @override
  String get deckEditorHint => 'Tap to add · long-press for the full ability';

  @override
  String get noCardsFound => 'No cards match your filters';

  @override
  String get localMatch => 'Local match';

  @override
  String get lanMatch => 'LAN match';

  @override
  String get hostMatch => 'Host match';

  @override
  String get joinMatch => 'Join match';

  @override
  String get hosting => 'Waiting for a guest to join…';

  @override
  String get searchingHosts => 'Searching the local network…';

  @override
  String get joinAddress => 'Host address';

  @override
  String get noHostsFound => 'No match found on this network';

  @override
  String get lobbyFailed => 'Could not start the match';

  @override
  String get cancelHosting => 'Stop hosting';

  @override
  String playerSeat(int seat) {
    return 'Player $seat';
  }

  @override
  String passDeviceTitle(String name) {
    return 'Pass the device to $name';
  }

  @override
  String get passDeviceHint =>
      'The next hand stays hidden until the next player is ready.';

  @override
  String get passDeviceReady => 'I\'m ready';

  @override
  String get commandWrongPhase => 'This action is not available right now.';

  @override
  String get commandNotYourTurn => 'It is not your turn.';

  @override
  String get commandPlayerPassed => 'You have already passed this round.';

  @override
  String get commandUnknownCard => 'That card is no longer in play.';

  @override
  String get commandCardNotInHand => 'That card is not in your hand.';

  @override
  String get commandRowOccupied =>
      'That row already has a card in its special slot.';

  @override
  String get commandNoTarget => 'Choose a valid target first.';

  @override
  String get commandLeaderUnavailable =>
      'Your leader ability is no longer available.';

  @override
  String get commandNoRedrawsLeft => 'You have no redraws left.';

  @override
  String get commandAlreadyDone => 'You have already confirmed that step.';

  @override
  String get commandChoiceNotAllowed => 'That decision is not yours to make.';

  @override
  String get commandInvalidChoice => 'That choice is not valid.';

  @override
  String get commandInvalidTargetRow =>
      'That card cannot be placed on the chosen row.';

  @override
  String get searchCollection => 'Search collection';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnits => 'Units';

  @override
  String get filterSpecial => 'Special';

  @override
  String get filterWeather => 'Weather';

  @override
  String get filterHeroes => 'Heroes';

  @override
  String get filterOwned => 'Owned';

  @override
  String get totalCards => 'Total cards';

  @override
  String get unitCards => 'Unit cards';

  @override
  String get specialCards => 'Special cards';

  @override
  String get heroCards => 'Hero cards';

  @override
  String get totalStrength => 'Total strength';

  @override
  String get deckValid => 'Deck is valid — ready to play';

  @override
  String get deckInvalid => 'Deck is not valid yet';

  @override
  String deckIssueTooFewUnits(int min) {
    return 'Needs at least $min unit cards';
  }

  @override
  String deckIssueTooManySpecial(int max) {
    return 'At most $max special cards';
  }

  @override
  String deckIssueTooManyCards(int max) {
    return 'At most $max cards in total';
  }

  @override
  String get deckIssueLeaderFaction => 'The leader does not match the faction';

  @override
  String get deckIssueCardNotAllowed =>
      'Some cards are not allowed in this faction';

  @override
  String get deckIssueTooManyCopies => 'Some cards exceed the owned copies';

  @override
  String get deckIssueUnknownCard => 'The deck contains an unknown card';

  @override
  String get invalidDeckTitle => 'Deck not playable';

  @override
  String get openDeckEditor => 'Open deck editor';

  @override
  String cardsOwned(int owned, int distinct) {
    return '$owned cards owned · $distinct distinct';
  }

  @override
  String cardsInDeck(int count, int max) {
    return '$count / $max cards';
  }

  @override
  String get round => 'Round';

  @override
  String roundOf(int current, int total) {
    return 'Round $current of $total';
  }

  @override
  String roundShort(int round) {
    return 'R$round';
  }

  @override
  String get yourTurn => 'Your turn';

  @override
  String get opponentTurn => 'Opponent turn';

  @override
  String get pass => 'Pass';

  @override
  String get passRound => 'Pass round';

  @override
  String get points => 'Points';

  @override
  String get cardsInHand => 'Cards in hand';

  @override
  String get deckPile => 'Deck';

  @override
  String get gravePile => 'Grave';

  @override
  String get weather => 'Weather';

  @override
  String get leaderReady => 'Ready';

  @override
  String get leaderUsed => 'Used';

  @override
  String get leaderPassive => 'Passive';

  @override
  String get cardPreview => 'Card preview';

  @override
  String get matchScore => 'Match score';

  @override
  String get you => 'You';

  @override
  String get playCard => 'Play card';

  @override
  String get tapCardDetails => 'Tap a card for details';

  @override
  String get selectRowHint => 'Choose a row';

  @override
  String get selectTargetHint => 'Choose a target';

  @override
  String selectDiscardHint(int count) {
    return 'Discard $count cards';
  }

  @override
  String get selectDrawHint => 'Choose a card to draw';

  @override
  String get confirmSelection => 'Confirm';

  @override
  String mulliganTitle(int count) {
    return 'Choose up to $count cards to redraw';
  }

  @override
  String get mulliganConfirm => 'Keep hand';

  @override
  String get waitingAi => 'Opponent is thinking…';

  @override
  String get roundWon => 'Round won';

  @override
  String get roundLost => 'Round lost';

  @override
  String get roundDrawn => 'Round drawn';

  @override
  String get victory => 'Victory';

  @override
  String get defeat => 'Defeat';

  @override
  String get draw => 'Draw';

  @override
  String get winnerYou => 'You win the match';

  @override
  String winnerOpponent(String name) {
    return '$name wins the match';
  }

  @override
  String get matchDrawn => 'The match is a draw';

  @override
  String get finalScore => 'Final score';

  @override
  String get playAgain => 'Play again';

  @override
  String get notPlayed => '—';

  @override
  String get clearWeatherNotPlayed => 'Clear Weather not played';

  @override
  String weatherRowAtOne(String row) {
    return '$row at 1';
  }

  @override
  String pointsAbbrev(int value) {
    return '$value str';
  }

  @override
  String opponentSummary(String faction, String difficulty) {
    return '$faction · $difficulty AI';
  }

  @override
  String handAndDeckHint(String name, int hand, int deck) {
    return '$name has $hand cards in hand · $deck in deck';
  }

  @override
  String get spyDraw => 'Spy: drawing 2 cards';

  @override
  String get muster => 'Muster: playing matching cards';

  @override
  String get medic => 'Medic: choosing a card to revive';

  @override
  String get scorch => 'Scorch!';

  @override
  String get decoy => 'Decoy swapped';

  @override
  String get rowClose => 'Close Combat';

  @override
  String get rowRanged => 'Ranged Combat';

  @override
  String get rowSiege => 'Siege Combat';

  @override
  String get rowAgile => 'Agile';

  @override
  String get rowWeather => 'Weather';

  @override
  String get cardTypeSpecial => 'Special Card';

  @override
  String get cardTypeWeather => 'Weather Card';

  @override
  String get cardTypeHero => 'Hero';

  @override
  String get cardTypeLeader => 'Leader Ability';

  @override
  String get tagHero => 'Hero';

  @override
  String get tagSpecial => 'Special';

  @override
  String get tagWeather => 'Weather';

  @override
  String get abilityLabel => 'Ability';

  @override
  String get abilityTagBond => 'Tight Bond';

  @override
  String get abilityTagSpy => 'Spy';

  @override
  String get abilityTagMedic => 'Medic';

  @override
  String get abilityTagMorale => 'Morale';

  @override
  String get abilityTagMuster => 'Muster';

  @override
  String get abilityTagAvenger => 'Avenger';

  @override
  String get abilityTagBerserker => 'Berserker';

  @override
  String get abilityTagHorn => 'Commander\'s Horn';

  @override
  String get abilityTagMardroeme => 'Mardroeme';

  @override
  String get abilityTagScorch => 'Scorch';

  @override
  String get abilityTagAgile => 'Agile';

  @override
  String get abilityHero => 'Not affected by any Special Cards or abilities.';

  @override
  String get abilityDecoy =>
      'Swap with a card on the battlefield to return it to your hand.';

  @override
  String get abilityHorn =>
      'Doubles the strength of all unit cards in that row. Limited to 1 per row.';

  @override
  String get abilityMardroeme =>
      'Triggers transformation of all Berserker cards on the same row.';

  @override
  String get abilityBerserker =>
      'Transforms into a bear when a Mardroeme card is on its row.';

  @override
  String get abilityScorch =>
      'Discard after playing. Kills the strongest card(s) on the battlefield.';

  @override
  String get abilityScorchClose =>
      'Destroy your enemy\'s strongest Close Combat unit(s) if the combined strength of all their Close Combat units is 10 or more.';

  @override
  String get abilityScorchRanged =>
      'Destroy your enemy\'s strongest Ranged Combat unit(s) if the combined strength of all their Ranged Combat units is 10 or more.';

  @override
  String get abilityScorchSiege =>
      'Destroy your enemy\'s strongest Siege Combat unit(s) if the combined strength of all their Siege Combat units is 10 or more.';

  @override
  String get abilityAgile =>
      'Can be placed in either the Close Combat or the Ranged Combat row. Cannot be moved once placed.';

  @override
  String get abilityMuster =>
      'Find any cards with the same name in your deck and play them instantly.';

  @override
  String get abilitySpy =>
      'Place on your opponent\'s battlefield (counts towards your opponent\'s total) and draw 2 cards from your deck.';

  @override
  String get abilityMedic =>
      'Choose one card from your discard pile and play it instantly (no Heroes or Special Cards).';

  @override
  String get abilityMorale =>
      'Adds +1 to all units in the row (excluding itself).';

  @override
  String get abilityBond =>
      'Place next to a card with the same name to double the strength of both cards.';

  @override
  String get abilityAvenger =>
      'When this card is removed from the battlefield, it summons a powerful new Unit Card to take its place.';

  @override
  String get abilityFrost =>
      'Sets the strength of all Close Combat cards to 1 for both players.';

  @override
  String get abilityFog =>
      'Sets the strength of all Ranged Combat cards to 1 for both players.';

  @override
  String get abilityRain =>
      'Sets the strength of all Siege Combat cards to 1 for both players.';

  @override
  String get abilityClear =>
      'Removes all Weather Cards (Biting Frost, Impenetrable Fog and Torrential Rain) effects.';

  @override
  String get leaderFoltestKing =>
      'Pick an Impenetrable Fog card from your deck and play it instantly.';

  @override
  String get leaderFoltestLord => 'Clear any weather effects in play.';

  @override
  String get leaderFoltestSiegemaster =>
      'Doubles the strength of all your Siege units (unless a Commander\'s Horn is also present on that row).';

  @override
  String get leaderFoltestSteelforged =>
      'Destroy your enemy\'s strongest Siege unit(s) if the combined strength of all their Siege units is 10 or more.';

  @override
  String get leaderFoltestSon =>
      'Destroy your enemy\'s strongest Ranged Combat unit(s) if the combined strength of all their Ranged units is 10 or more.';

  @override
  String get leaderEmhyrImperial =>
      'Pick a Torrential Rain card from your deck and play it instantly.';

  @override
  String get leaderEmhyrEmperor =>
      'Look at 3 random cards from your opponent\'s hand.';

  @override
  String get leaderEmhyrWhiteflame => 'Cancel your opponent\'s Leader Ability.';

  @override
  String get leaderEmhyrRelentless =>
      'Draw a card from your opponent\'s discard pile.';

  @override
  String get leaderEmhyrInvader =>
      'Abilities that restore a unit to the battlefield restore a randomly-chosen unit. Affects both players.';

  @override
  String get leaderEredinCommander =>
      'Double the strength of all your Close Combat units (unless a Commander\'s Horn is also present on that row).';

  @override
  String get leaderEredinBringer =>
      'Restore a card from your discard pile to your hand.';

  @override
  String get leaderEredinDestroyer =>
      'Discard 2 cards and draw 1 card of your choice from your deck.';

  @override
  String get leaderEredinKing =>
      'Pick any weather card from your deck and play it instantly.';

  @override
  String get leaderEredinTreacherous =>
      'Doubles the strength of all spy cards (affects both players).';

  @override
  String get leaderFrancescaQueen =>
      'Destroy your enemy\'s strongest Close Combat unit(s) if the combined strength of all their Close Combat units is 10 or more.';

  @override
  String get leaderFrancescaBeautiful =>
      'Doubles the strength of all your Ranged Combat units (unless a Commander\'s Horn is also present on that row).';

  @override
  String get leaderFrancescaDaisy =>
      'Draw an extra card at the beginning of the battle.';

  @override
  String get leaderFrancescaPureblood =>
      'Pick a Biting Frost card from your deck and play it instantly.';

  @override
  String get leaderFrancescaHope =>
      'Move agile units to whichever valid row maximizes their strength.';

  @override
  String get leaderCrachAnCraite =>
      'Shuffle all cards from each player\'s graveyard back into their decks.';

  @override
  String get leaderKingBran =>
      'Units only lose half their Strength in bad weather conditions.';

  @override
  String get factionAbilityRealms =>
      'Draw a card from your deck whenever you win a round.';

  @override
  String get factionAbilityNilfgaard => 'Wins any round that ends in a draw.';

  @override
  String get factionAbilityMonsters =>
      'Keeps a random Unit Card out after each round.';

  @override
  String get factionAbilityScoiatael => 'Decides who takes the first turn.';

  @override
  String get factionAbilitySkellige =>
      '2 random cards from the graveyard are placed on the battlefield at the start of the third round.';

  @override
  String get aiOpponent => 'AI opponent';

  @override
  String get opponentName => 'Opponent';

  @override
  String get opponentDisconnected => 'Opponent disconnected';

  @override
  String get waitingForOpponent => 'Waiting for them to reconnect…';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get reconnectFailed => 'Could not reach the host. Try again.';

  @override
  String get opponentGoneTitle => 'Opponent lost';

  @override
  String get opponentGoneBody =>
      'The other player did not come back, so the match was abandoned.';
}

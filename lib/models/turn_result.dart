import 'piece_model.dart';

class TurnResult {
  bool pocketedOwn;
  bool pocketedOpponent;
  bool pocketedQueen;
  bool pocketedStriker;
  List<PieceType> piecesPocketedThisTurn;
  List<PieceModel> pocketedPieces;

  TurnResult({
    this.pocketedOwn = false,
    this.pocketedOpponent = false,
    this.pocketedQueen = false,
    this.pocketedStriker = false,
    List<PieceType>? piecesPocketedThisTurn,
    List<PieceModel>? pocketedPieces,
  })  : piecesPocketedThisTurn = piecesPocketedThisTurn ?? [],
        pocketedPieces = pocketedPieces ?? [];

  void reset() {
    pocketedOwn = false;
    pocketedOpponent = false;
    pocketedQueen = false;
    pocketedStriker = false;
    piecesPocketedThisTurn.clear();
    pocketedPieces.clear();
  }
}

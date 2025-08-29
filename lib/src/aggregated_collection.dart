part of '../aggregated_collection.dart';

class AggregatedCollection {
  static const String subIdsKey = "sub_ids";
  static const String subCountKey = "sub_count";
  static const int maximumDocsPerAggregationVal = 100;
  static const bool cacheLastDocReferenceFromSnapshotDataVal = false;

  final CollectionReference<Map<String, dynamic>> _collectionReference;
  final int maximumDocsPerAggregation;
  final bool cacheLastDocReferenceFromSnapshotData;

  DocumentReference? _documentReference;

  AggregatedCollection(this._collectionReference,
      {this.maximumDocsPerAggregation = maximumDocsPerAggregationVal,
      this.cacheLastDocReferenceFromSnapshotData =
          cacheLastDocReferenceFromSnapshotDataVal});

  Future<DocumentSnapshot?> _getDocFromSubId(String id) async {
    return (await _collectionReference
            .where(subIdsKey, arrayContains: id)
            .limit(1)
            .get())
        .docs
        .firstOrNull;
  }

  Future<AggregatedDocumentReference?> doc(String id) async {
    final document = await _getDocFromSubId(id);
    if (document == null) return null;
    return AggregatedDocumentReference(document.reference, id: id);
  }

  Future<AggregatedDocumentData?> docGet(String id) async {
    final document = await _getDocFromSubId(id);
    if (document == null) return null;
    return AggregatedDocumentData(
        reference: AggregatedDocumentReference(document.reference, id: id),
        data: document.get(id));
  }

  List<AggregatedDocumentData> _expandQuerySnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.expand((pDoc) {
      final subDocs = pDoc
          .data()
          .entries
          .where((e) => !{subIdsKey, subCountKey}.contains(e.key));
      return subDocs
          .map((sDoc) => AggregatedDocumentData(
              reference:
                  AggregatedDocumentReference(pDoc.reference, id: sDoc.key),
              data: Map<String, dynamic>.from(sDoc.value)))
          .toList();
    }).toList();
  }

  Stream<List<AggregatedDocumentData>> snapshots() {
    return _collectionReference.snapshots().map((snapshot) {
      if (cacheLastDocReferenceFromSnapshotData) {
        _documentReference = snapshot.docs
            .where((e) => e.get(subCountKey) < maximumDocsPerAggregation)
            .firstOrNull
            ?.reference;
      }
      return _expandQuerySnapshot(snapshot);
    });
  }

  Future<List<AggregatedDocumentData>> get() async {
    final documents = await _collectionReference.get();
    return _expandQuerySnapshot(documents);
  }

  Future<void> add(Map<String, dynamic> data, [String? id]) async {
    id ??= const UuidV4().generate();
    if (!cacheLastDocReferenceFromSnapshotData) {
      _documentReference = (await _collectionReference
              .where(subCountKey, isLessThan: maximumDocsPerAggregation)
              .limit(1)
              .get())
          .docs
          .firstOrNull
          ?.reference;
    }
    if (_documentReference == null) {
      await _collectionReference.add({
        id: data,
        subIdsKey: [id],
        subCountKey: 1
      });
      return;
    }
    await _documentReference!.update({
      id: data,
      subIdsKey: FieldValue.arrayUnion([id]),
      subCountKey: FieldValue.increment(1)
    });
  }
}

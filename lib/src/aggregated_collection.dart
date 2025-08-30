part of '../aggregated_collection.dart';

class AggregatedCollection {
  static const String subIdsKey = "sub_ids";
  static const String subCountKey = "sub_count";
  static const int maximumDocsPerAggregationVal = 100;
  static const bool cacheLastDocReferenceFromSnapshotDataVal = false;
  static const bool attemptReplaceWhenAddWithIdVal = true;

  final CollectionReference<Map<String, dynamic>> _collectionReference;
  final int maximumDocsPerAggregation;
  final bool cacheLastDocReferenceFromSnapshotData;
  final bool attemptReplaceWhenAddWithId;

  DocumentReference? _documentReference;

  AggregatedCollection(
    this._collectionReference, {
    this.maximumDocsPerAggregation = maximumDocsPerAggregationVal,
    this.cacheLastDocReferenceFromSnapshotData =
        cacheLastDocReferenceFromSnapshotDataVal,
    this.attemptReplaceWhenAddWithId = attemptReplaceWhenAddWithIdVal,
  });

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

  Future<AggregatedDocumentReference?> _replace(
      String id, Map<String, dynamic> data) async {
    final reference = await doc(id);
    reference?.set(data);
    return reference;
  }

  Future<AggregatedDocumentReference> add(Map<String, dynamic> data,
      [String? id]) async {
    if (attemptReplaceWhenAddWithId && id != null) {
      final reference = await _replace(id, data);
      if (reference != null) {
        return reference;
      }
    }

    id ??= const UuidV4().generate();
    var reference = _documentReference;
    if (!cacheLastDocReferenceFromSnapshotData) {
      reference = (await _collectionReference
              .where(subCountKey, isLessThan: maximumDocsPerAggregation)
              .limit(1)
              .get())
          .docs
          .firstOrNull
          ?.reference;
    }
    if (reference == null) {
      reference = await _collectionReference.add({
        id: data,
        subIdsKey: [id],
        subCountKey: 1
      });
    } else {
      await reference.update({
        id: data,
        subIdsKey: FieldValue.arrayUnion([id]),
        subCountKey: FieldValue.increment(1)
      });
    }
    return AggregatedDocumentReference(reference, id: id);
  }
}

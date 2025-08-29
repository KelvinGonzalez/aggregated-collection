part of '../aggregated_collection.dart';

class AggregatedDocumentReference {
  final DocumentReference _documentReference;
  final String id;

  const AggregatedDocumentReference(this._documentReference,
      {required this.id});

  Stream<AggregatedDocumentData> snapshots() {
    return _documentReference
        .snapshots()
        .map((e) => AggregatedDocumentData(reference: this, data: e.get(id)));
  }

  Future<AggregatedDocumentData> get() async {
    final document = await _documentReference.get();
    return AggregatedDocumentData(reference: this, data: document.get(id));
  }

  Future<void> update(Map<String, dynamic> data) async {
    final updateMap = data.map((k, v) => MapEntry("$id.$k", v));
    await _documentReference.update(updateMap);
  }

  Future<void> set(Map<String, dynamic> data) async {
    await _documentReference.update({id: data});
  }

  Future<void> delete() async {
    await _documentReference.update({
      id: FieldValue.delete(),
      AggregatedCollection.subIdsKey: FieldValue.arrayRemove([id]),
      AggregatedCollection.subCountKey: FieldValue.increment(-1),
    });
  }
}

class AggregatedDocumentData {
  final AggregatedDocumentReference reference;
  final Map<String, dynamic> data;

  const AggregatedDocumentData({required this.reference, required this.data});

  dynamic get(String key) => data[key];
}

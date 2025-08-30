part of '../aggregated_collection.dart';

class CollectionAggregator {
  int _maximumDocsPerAggregation;
  bool _cacheLastDocReferenceFromSnapshotData;
  bool _attemptReplaceWhenAddWithId;

  static final CollectionAggregator instance = CollectionAggregator(
      AggregatedCollection.maximumDocsPerAggregationVal,
      AggregatedCollection.cacheLastDocReferenceFromSnapshotDataVal,
      AggregatedCollection.attemptReplaceWhenAddWithIdVal);

  CollectionAggregator(
      this._maximumDocsPerAggregation,
      this._cacheLastDocReferenceFromSnapshotData,
      this._attemptReplaceWhenAddWithId);

  void setMaximumDocsPerAggregation(int value) =>
      _maximumDocsPerAggregation = value;

  void setCacheLastDocReferenceFromSnapshotData(bool value) =>
      _cacheLastDocReferenceFromSnapshotData = value;

  void setAttemptReplaceWhenAddWithId(bool value) =>
      _attemptReplaceWhenAddWithId = value;

  AggregatedCollection collection(String name) => AggregatedCollection(
        FirebaseFirestore.instance.collection(name),
        maximumDocsPerAggregation: _maximumDocsPerAggregation,
        cacheLastDocReferenceFromSnapshotData:
            _cacheLastDocReferenceFromSnapshotData,
        attemptReplaceWhenAddWithId: _attemptReplaceWhenAddWithId,
      );
}

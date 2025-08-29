part of '../aggregated_collection.dart';

class CollectionAggregator {
  int _maximumDocsPerAggregation;
  bool _cacheLastDocReferenceFromSnapshotData;

  static final CollectionAggregator instance = CollectionAggregator(
      AggregatedCollection.maximumDocsPerAggregationVal,
      AggregatedCollection.cacheLastDocReferenceFromSnapshotDataVal);

  CollectionAggregator(this._maximumDocsPerAggregation,
      this._cacheLastDocReferenceFromSnapshotData);

  void setMaximumDocsPerAggregation(int value) =>
      _maximumDocsPerAggregation = value;

  void setCacheLastDocReferenceFromSnapshotData(bool value) =>
      _cacheLastDocReferenceFromSnapshotData = value;

  AggregatedCollection collection(String name) => AggregatedCollection(
        FirebaseFirestore.instance.collection(name),
        maximumDocsPerAggregation: _maximumDocsPerAggregation,
        cacheLastDocReferenceFromSnapshotData:
            _cacheLastDocReferenceFromSnapshotData,
      );
}

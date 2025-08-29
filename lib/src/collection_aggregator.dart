part of '../aggregated_collection.dart';

class CollectionAggregator {
  int _maximumDocsPerAggregation;

  static final CollectionAggregator instance =
      CollectionAggregator(AggregatedCollection.maximumDocsPerAggregationVal);

  CollectionAggregator(this._maximumDocsPerAggregation);

  void setMaximumDocsPerAggregation(int value) =>
      _maximumDocsPerAggregation = value;

  AggregatedCollection collection(String name) =>
      AggregatedCollection(FirebaseFirestore.instance.collection(name),
          maximumDocsPerAggregation: _maximumDocsPerAggregation);
}

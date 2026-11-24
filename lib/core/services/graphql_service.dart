import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLService {
  Future<void> initialize() async {}

  GraphQLClient get client {
    final httpLink = HttpLink('https://example.com/graphql');
    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import 'github_access_token.dart';

void main() {
  final HttpLink httpLink = HttpLink(
    uri: 'https://api.github.com/graphql',
  );

  final AuthLink authLink = AuthLink(
    getToken: () async => 'Bearer $github_access_token',
    // OR
    // getToken: () => 'Bearer <YOUR_PERSONAL_ACCESS_TOKEN>',
  );

  final Link link = authLink.concat(httpLink as Link);

  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      cache: InMemoryCache(),
      link: link,
    ),
  );

  runApp(MyApp(client));
}

class MyApp extends StatelessWidget {
  final ValueNotifier<GraphQLClient> client;

  MyApp(this.client);

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: CacheProvider(
        child: MaterialApp(
          title: 'GraphQL Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: MyHomePage(title: 'GraphQL Flutter Demo Home Page'),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String readRepositories = """
  query ReadRepositories(\$nRepositories: Int!) {
    viewer {
      repositories(last: \$nRepositories) {
        nodes {
          id
          name
          description
          url
        }
      }
    }
  }
""";

  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Query(
        options: QueryOptions(
          document:
              readRepositories, // this is the query string you just created
          variables: {
            'nRepositories': 50,
          },
          pollInterval: 10,
        ),
        // Just like in apollo refetch() could be used to manually trigger a refetch
        builder: (QueryResult result, {VoidCallback refetch}) {
          if (result.errors != null) {
            return Center(child: Text(result.errors.toString()));
          }

          if (result.loading) {
            return Center(child: Text('Loading'));
          }

          // it can be either Map or List
          List repositories = result.data['viewer']['repositories']['nodes'];

          return Center(
            child: ListView.builder(
              itemCount: repositories.length,
              itemBuilder: (context, index) {
                final repository = repositories[index];

                String url = repository['url'].toString();
                return ListTile(
                  title: Text(repository['name'].toString()),
                  leading: Icon(
                    Icons.check,
                    color: Colors.purple,
                  ),
                  subtitle: InkWell(
                    child: Text(url),
                    onTap: () {
                      _launchUrl(url);
                    },
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: () => _launchUrl(url),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

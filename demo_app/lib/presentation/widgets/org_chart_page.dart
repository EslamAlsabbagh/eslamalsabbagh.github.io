// import 'package:hrms_demo/l10n/app_localizations.dart';
// import 'package:hrms_demo/presentation/widgets/main_layout.dart';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'dart:convert';

// class OrgChartPage extends StatefulWidget {
//   const OrgChartPage({super.key});

//   @override
//   State<OrgChartPage> createState() => _OrgChartPageState();
// }

// class _OrgChartPageState extends State<OrgChartPage> {
//   late final WebViewController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..loadFlutterAsset('assets/orgchart/index.html')
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageFinished: (url) async {
//                 await loadOrgChart(_controller);
//               },
//             ),
//           );
//   }

//   Future<void> loadOrgChart(WebViewController controller) async {
//     final supabase = Supabase.instance.client;
//     final response = await supabase
//         .from('users')
//         .select('id, English Name, title, N+1');

//     final data =
//         response
//             .map(
//               (user) => {
//                 'id': user['id'],
//                 'pid': user['N+1'], // parent id for OrgChart
//                 'name': user['English Name'],
//                 'post': user['title'],
//               },
//             )
//             .toList();

//     final jsonData = jsonEncode(data);
//     await controller.runJavaScript('renderOrgChart($jsonData)');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: MainLayout(
//         title: AppLocalizations.of(context)!.orgChart,
//         child: WebViewWidget(controller: _controller),
//       ),
//     );
//   }
// }

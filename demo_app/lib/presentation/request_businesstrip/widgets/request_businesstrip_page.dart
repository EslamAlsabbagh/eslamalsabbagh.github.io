import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/services/disabled_dates_service.dart';
import 'package:hrms_demo/presentation/request_businesstrip/bloc/request_businesstrip_bloc.dart';
import 'package:hrms_demo/presentation/request_businesstrip/widgets/request_businesstrip_content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestBusinesstripPage extends StatelessWidget {
  const RequestBusinesstripPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RequestBusinesstripBloc>(
      create:
          (_) =>
              RequestBusinesstripBloc(context.read<BusinesstripRequestsRepo>(), context.read<DisabledDatesService>()),
      child: RequestBusinesstripContent(),
    );
  }
}

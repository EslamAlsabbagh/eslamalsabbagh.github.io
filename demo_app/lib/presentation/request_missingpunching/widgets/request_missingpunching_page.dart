import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/services/disabled_dates_service.dart';
import 'package:hrms_demo/presentation/request_missingpunching/bloc/request_missingpunching_bloc.dart';
import 'package:hrms_demo/presentation/request_missingpunching/widgets/request_missingpunching_content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestMissingpunchingPage extends StatelessWidget {
  const RequestMissingpunchingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RequestMissingpunchingBloc>(
      create:
          (_) => RequestMissingpunchingBloc(
            context.read<MissingpunchingRequestsRepo>(),
            context.read<DisabledDatesService>(),
          ),
      child: RequestMissingpunchingContent(),
    );
  }
}

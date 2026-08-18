import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/presentation/settlement_review/bloc/settlement_review_bloc.dart';
import 'package:hrms_demo/presentation/settlement_review/widgets/settlement_review_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettlementReviewPage extends StatelessWidget {
  const SettlementReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final advanceRepo = context.read<AdvanceOnSalaryRequestsRepo>();

    return BlocProvider(
      create: (context) => SettlementReviewBloc(advanceRepo)..add(LoadSettlementReviewRequests()),
      child: const SettlementReviewContent(),
    );
  }
}

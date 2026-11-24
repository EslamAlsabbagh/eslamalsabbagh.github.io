import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/web/register_output.dart';
import '../data/contracts_repository.dart';
import '../export/build_register.dart';
import '../export/html_writer.dart';
import '../export/register_labels.dart';
import '../export/xlsx_writer.dart';
import 'contract_groups.dart';

/// What «تصدير» makes.
enum ContractExportFormat { xlsx, print }

enum ContractExportStatus { idle, working, failed }

/// «تصدير» on «العقود» (DESIGN_SPEC §4 View 4 "Export and print"): reads
/// the register for the sections the list shows, lays it out and hands it to
/// the browser, as an .xlsx download or a print. One at a time: a request
/// while one runs is dropped.
class ContractExportBloc extends Bloc<ContractExportEvent, ContractExportState> {
  ContractExportBloc({required this._repository, required this._output}) : super(const ContractExportState()) {
    on<ContractExportRequested>(_onRequested);
  }

  final ContractsRepository _repository;
  final RegisterOutput _output;

  /// The print page's fonts: the app's bundled Arabic face.
  static const String regularFont = 'assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Regular.ttf';
  static const String boldFont = 'assets/fonts/ibm_plex_sans_arabic/IBMPlexSansArabic-Bold.ttf';

  Future<void> _onRequested(ContractExportRequested event, Emitter<ContractExportState> emit) async {
    if (state.status == ContractExportStatus.working) return;
    emit(ContractExportState(status: ContractExportStatus.working, format: event.format));
    try {
      final ids = [
        for (final group in event.groups) ...[
          for (final c in group.current) c.id,
          for (final c in group.terminated) c.id,
        ],
      ];
      final data = await _repository.fetchRegister(ids);
      final doc = buildRegister(groups: event.groups, data: data, labels: event.labels);
      switch (event.format) {
        case ContractExportFormat.xlsx:
          await _output.saveFile(writeXlsx(doc), name: '${event.fileName}.xlsx', mimeType: xlsxMimeType);
        case ContractExportFormat.print:
          await _output.printHtml(writeRegisterHtml(
            doc,
            title: event.fileName,
            regularFontUrl: _output.assetUrl(regularFont),
            boldFontUrl: _output.assetUrl(boldFont),
          ));
      }
      emit(ContractExportState(format: event.format));
    } catch (error, stackTrace) {
      log('Exporting the register (${event.format.name}) failed',
          name: 'contracts', error: error, stackTrace: stackTrace);
      emit(ContractExportState(status: ContractExportStatus.failed, format: event.format));
    }
  }
}

sealed class ContractExportEvent extends Equatable {
  const ContractExportEvent();

  @override
  List<Object?> get props => [];
}

/// Export the list's sections ([groups]: the file chip, the search and the
/// filters applied) as [format]. [fileName] has no extension.
final class ContractExportRequested extends ContractExportEvent {
  const ContractExportRequested({
    required this.format,
    required this.groups,
    required this.labels,
    required this.fileName,
  });

  final ContractExportFormat format;
  final List<FileContracts> groups;
  final RegisterLabels labels;
  final String fileName;

  @override
  List<Object?> get props => [format, groups, labels, fileName];
}

class ContractExportState extends Equatable {
  const ContractExportState({this.status = ContractExportStatus.idle, this.format});

  final ContractExportStatus status;

  /// The format being made, or last made.
  final ContractExportFormat? format;

  bool get working => status == ContractExportStatus.working;

  @override
  List<Object?> get props => [status, format];
}

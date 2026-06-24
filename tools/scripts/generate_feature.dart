import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Error: Please specify the feature name in snake_case.');
    print('Usage: dart tools/scripts/generate_feature.dart <feature_name>');
    exit(1);
  }

  final featureSnake = args[0].toLowerCase();
  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(featureSnake)) {
    print('Error: Feature name must be in snake_case (alphanumeric and underscores only).');
    exit(1);
  }

  final featurePascal = featureSnake.split('_').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1);
  }).join('');

  print('Generating Clean Architecture files for feature: $featurePascal ($featureSnake)...');

  try {
    _generateCoreFiles(featureSnake, featurePascal);
    _generateDataFiles(featureSnake, featurePascal);
    _generateMobileFiles(featureSnake, featurePascal);
    _updateCoreExports(featureSnake);

    print('\n🎉 Feature "$featurePascal" generated successfully!');
    print('Next steps:');
    print('1. Implement fields and mapping in the generated entities, models, and repositories.');
    print('2. Run code generation:');
    print('   - To run build_runner for the whole project: melos run build:runner');
    print('   - To run build_runner for core: melos run build:runner:core');
    print('   - To run build_runner for data: melos run build:runner:data');
    print('   - To run build_runner for mobile: melos run build:runner:mobile');
  } catch (e) {
    print('An error occurred during generation: $e');
    exit(1);
  }
}

void _createFile(String path, String content) {
  final file = File(path);
  if (file.existsSync()) {
    print('⚠️  File already exists: $path (Skipping)');
    return;
  }
  file.createSync(recursive: true);
  file.writeAsStringSync(content);
  print('✅ Generated: $path');
}

void _generateCoreFiles(String snake, String pascal) {
  // 1. Entity
  final entityContent = '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '$snake.freezed.dart';
part '$snake.g.dart';

/// Domain entity representing a $pascal.
@freezed
abstract class $pascal with _\$$pascal {
  const factory $pascal({
    required String id,
    required String name,
    required DateTime createdAt,
  }) = _$pascal;

  const $pascal._();

  factory $pascal.fromJson(Map<String, dynamic> json) => _\$${pascal}FromJson(json);
}
''';
  _createFile('packages/core/lib/src/entities/$snake.dart', entityContent);

  // 2. Repository Interface
  final repoInterfaceContent = '''
import 'package:fpdart/fpdart.dart';
import 'package:sayr_core/src/entities/$snake.dart';
import 'package:sayr_core/src/failures/failure.dart';

/// Interface for $pascal operations.
abstract class ${pascal}Repository {
  /// Fetch a $pascal by its identifier.
  Future<Either<Failure, $pascal>> get$pascal(String id);

  /// Fetch a list of $pascal entities.
  Future<Either<Failure, List<$pascal>>> get${pascal}s();
}
''';
  _createFile('packages/core/lib/src/repositories/${snake}_repository.dart', repoInterfaceContent);
}

void _generateDataFiles(String snake, String pascal) {
  // 1. Model (DTO)
  final modelContent = '''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part '${snake}_model.freezed.dart';
part '${snake}_model.g.dart';

/// Data Transfer Object (DTO) for $pascal.
@freezed
abstract class ${pascal}Model with _\$${pascal}Model {
  const factory ${pascal}Model({
    required String id,
    required String name,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _${pascal}Model;

  const ${pascal}Model._();

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) =>
      _\$${pascal}ModelFromJson(json);

  /// Converts the DTO into the domain entity.
  $pascal toEntity() => $pascal(
        id: id,
        name: name,
        createdAt: createdAt,
      );
}
''';
  _createFile('packages/data/lib/src/models/${snake}_model.dart', modelContent);

  // 2. Remote DataSource
  final dataSourceContent = '''
import 'package:injectable/injectable.dart';
import 'package:sayr_data/src/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Remote DataSource for $pascal database/API operations.
abstract class ${pascal}RemoteDatasource {
  Future<Map<String, dynamic>?> fetch$pascal(String id);
  Future<List<Map<String, dynamic>>> fetch${pascal}s();
}

@LazySingleton(as: ${pascal}RemoteDatasource)
class ${pascal}RemoteDatasourceImpl implements ${pascal}RemoteDatasource {
  ${pascal}RemoteDatasourceImpl({SayrSupabase? supabase})
      : _supabase = supabase ?? SayrSupabase.instance;

  final SayrSupabase _supabase;
  supabase.SupabaseClient get _client => _supabase.client;

  @override
  Future<Map<String, dynamic>?> fetch$pascal(String id) async {
    return _client
        .from('${snake}s')
        .select()
        .eq('id', id)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> fetch${pascal}s() async {
    final response = await _client.from('${snake}s').select();
    return List<Map<String, dynamic>>.from(response);
  }
}
''';
  _createFile('packages/data/lib/src/datasources/${snake}_remote_datasource.dart', dataSourceContent);

  // 3. Repository Implementation
  final repoImplContent = '''
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_data/src/datasources/${snake}_remote_datasource.dart';
import 'package:sayr_data/src/models/${snake}_model.dart';
import 'package:sayr_data/src/repositories/base_repository.dart';

@LazySingleton(as: ${pascal}Repository)
class ${pascal}RepositoryImpl extends BaseRepository implements ${pascal}Repository {
  ${pascal}RepositoryImpl({
    required ${pascal}RemoteDatasource remoteDatasource,
    required super.talker,
  }) : _remoteDatasource = remoteDatasource;

  final ${pascal}RemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, $pascal>> get$pascal(String id) async {
    return guard(() async {
      final response = await _remoteDatasource.fetch$pascal(id);
      if (response == null) {
        throw const NotFoundFailure(resource: '$snake');
      }
      return ${pascal}Model.fromJson(response).toEntity();
    });
  }

  @override
  Future<Either<Failure, List<$pascal>>> get${pascal}s() async {
    return guard(() async {
      final response = await _remoteDatasource.fetch${pascal}s();
      return response.map(${pascal}Model.fromJson).map((m) => m.toEntity()).toList();
    });
  }
}
''';
  _createFile('packages/data/lib/src/repositories/${snake}_repository.dart', repoImplContent);
}

void _generateMobileFiles(String snake, String pascal) {
  final baseDir = 'apps/mobile/lib/features/$snake/presentation';

  // 1. Bloc Event
  final eventContent = '''
part of '${snake}_bloc.dart';

sealed class ${pascal}Event extends Equatable {
  const ${pascal}Event();

  @override
  List<Object?> get props => [];
}

class Load$pascal extends ${pascal}Event {
  const Load$pascal(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
''';
  _createFile('$baseDir/bloc/${snake}_event.dart', eventContent);

  // 2. Bloc State
  final stateContent = '''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sayr_core/sayr_core.dart';

part '${snake}_state.freezed.dart';

@freezed
class ${pascal}State with _\$${pascal}State {
  const factory ${pascal}State.initial() = _Initial;
  const factory ${pascal}State.loading() = _Loading;
  const factory ${pascal}State.loaded({required $pascal data}) = _Loaded;
  const factory ${pascal}State.error({required Failure failure}) = _Error;
}
''';
  _createFile('$baseDir/bloc/${snake}_state.dart', stateContent);

  // 3. Bloc implementation
  final blocContent = '''
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/$snake/presentation/bloc/${snake}_state.dart';

part '${snake}_event.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${pascal}State> {
  ${pascal}Bloc({required ${pascal}Repository repository})
      : _repository = repository,
        super(const ${pascal}State.initial()) {
    on<Load$pascal>(_onLoad$pascal);
  }

  final ${pascal}Repository _repository;

  Future<void> _onLoad$pascal(
    Load$pascal event,
    Emitter<${pascal}State> emit,
  ) async {
    emit(const ${pascal}State.loading());
    final result = await _repository.get$pascal(event.id);
    if (isClosed) return;
    result.fold(
      (Failure failure) => emit(${pascal}State.error(failure: failure)),
      ($pascal data) => emit(${pascal}State.loaded(data: data)),
    );
  }
}
''';
  _createFile('$baseDir/bloc/${snake}_bloc.dart', blocContent);

  // 4. Feature Page
  final pageContent = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sayr_core/sayr_core.dart';
import 'package:sayr_mobile/features/$snake/presentation/bloc/${snake}_bloc.dart';
import 'package:sayr_mobile/features/$snake/presentation/bloc/${snake}_state.dart';
import 'package:sayr_ui_kit/sayr_ui_kit.dart';

class ${pascal}Page extends StatelessWidget {
  const ${pascal}Page({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<${pascal}Bloc>(
      create: (context) => ${pascal}Bloc(
        repository: context.read<${pascal}Repository>(),
      )..add(Load$pascal(id)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('$pascal'),
        ),
        body: BlocBuilder<${pascal}Bloc, ${pascal}State>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: LoadingWidget()),
              loading: () => const Center(child: LoadingWidget()),
              loaded: (data) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Created At: \${data.createdAt}'),
                  ],
                ),
              ),
              error: (failure) => Center(
                child: AppErrorWidget(
                  title: 'Error',
                  message: failure.toString(),
                  retryLabel: 'Retry',
                  onRetry: () {
                    context.read<${pascal}Bloc>().add(Load$pascal(id));
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
''';
  _createFile('$baseDir/pages/${snake}_page.dart', pageContent);
}

void _updateCoreExports(String snake) {
  final coreFile = File('packages/core/lib/sayr_core.dart');
  if (!coreFile.existsSync()) {
    print('⚠️  packages/core/lib/sayr_core.dart not found. Skip export registration.');
    return;
  }

  var content = coreFile.readAsStringSync();
  
  final entityExport = "export 'src/entities/$snake.dart';";
  final repoExport = "export 'src/repositories/${snake}_repository.dart';";

  if (content.contains(entityExport) && content.contains(repoExport)) {
    return;
  }

  // Find a good place to insert exports.
  // We can insert at the end of the exports list.
  final lines = content.split('\n');
  final newLines = <String>[];
  var insertedEntity = false;
  var insertedRepo = false;

  for (var line in lines) {
    if (!insertedEntity && line.startsWith("export 'src/entities/") && line.compareTo("export 'src/entities/$snake.dart';") > 0) {
      newLines.add("export 'src/entities/$snake.dart';");
      insertedEntity = true;
    }
    if (!insertedRepo && line.startsWith("export 'src/repositories/") && line.compareTo("export 'src/repositories/${snake}_repository.dart';") > 0) {
      newLines.add("export 'src/repositories/${snake}_repository.dart';");
      insertedRepo = true;
    }
    newLines.add(line);
  }

  if (!insertedEntity) {
    // If not inserted because it's alphabetically last, find the last entities export
    final lastEntityIndex = newLines.lastIndexWhere((l) => l.startsWith("export 'src/entities/"));
    if (lastEntityIndex != -1) {
      newLines.insert(lastEntityIndex + 1, "export 'src/entities/$snake.dart';");
    }
  }

  if (!insertedRepo) {
    // If not inserted because it's alphabetically last, find the last repositories export
    final lastRepoIndex = newLines.lastIndexWhere((l) => l.startsWith("export 'src/repositories/"));
    if (lastRepoIndex != -1) {
      newLines.insert(lastRepoIndex + 1, "export 'src/repositories/${snake}_repository.dart';");
    }
  }

  coreFile.writeAsStringSync(newLines.join('\n'));
  print('✅ Registered exports in packages/core/lib/sayr_core.dart');
}

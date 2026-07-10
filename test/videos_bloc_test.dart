import 'package:am_player/bloc/videos_bloc/videos_bloc.dart';
import 'package:am_player/models/video_folder.dart';
import 'package:am_player/models/video_item.dart';
import 'package:am_player/repositories/video_library_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cachedFolder = VideoFolder(
    id: 'movies',
    name: 'Movies',
    count: 2,
    coverAssetId: 'cover',
    latestModifiedMs: 100,
  );

  test('startup keeps cached folders and uses a lightweight sync check',
      () async {
    final repository = _FakeVideoRepository(cachedFolders: [cachedFolder]);
    final bloc = VideosBloc(repository: repository);
    addTearDown(bloc.close);

    final settled = bloc.stream.firstWhere(
      (state) => repository.syncCalls == 1 && !state.isSyncing,
    );
    bloc.add(const LoadVideosEvent());
    final state = await settled;

    expect(state.folders, [cachedFolder]);
    expect(repository.lastForceValue, isFalse);
  });

  test('startup lets the repository validate an empty cached library',
      () async {
    final repository = _FakeVideoRepository(cachedFolders: const []);
    final bloc = VideosBloc(repository: repository);
    addTearDown(bloc.close);

    final settled = bloc.stream.firstWhere(
      (state) => repository.syncCalls == 1 && !state.isSyncing,
    );
    bloc.add(const LoadVideosEvent());
    await settled;

    expect(repository.lastForceValue, isFalse);
  });

  test('manual refresh always forces a full sync', () async {
    final repository = _FakeVideoRepository(cachedFolders: [cachedFolder]);
    final bloc = VideosBloc(repository: repository);
    addTearDown(bloc.close);

    final settled = bloc.stream.firstWhere(
      (state) => repository.syncCalls == 1 && !state.isSyncing,
    );
    bloc.add(const RefreshVideosEvent());
    await settled;

    expect(repository.lastForceValue, isTrue);
  });
}

class _FakeVideoRepository extends VideoLibraryRepository {
  final List<VideoFolder> cachedFolders;
  int syncCalls = 0;
  bool? lastForceValue;

  _FakeVideoRepository({required this.cachedFolders});

  @override
  Future<List<VideoFolder>> loadFolders() async => cachedFolders;

  @override
  Future<bool> syncDeviceVideos({bool force = false}) async {
    syncCalls += 1;
    lastForceValue = force;
    return false;
  }

  @override
  Future<List<VideoItem>> loadVideosInFolder(String folderId) async => const [];
}

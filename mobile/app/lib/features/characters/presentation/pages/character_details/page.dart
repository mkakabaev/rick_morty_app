import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/di/di.dart';
import 'package:app/features/reachability/reachability.dart';
import 'package:app/l10n/l10n.dart';
import 'package:app/ui/ui.dart';

import '../../../domain/entities/character.dart';
import '../../../domain/entities/character_id.dart';
import '../../../domain/use_cases/observe_character.dart';
import '../../../domain/use_cases/reload_character.dart';
import '../../shared/character_portrait.dart';

import 'bloc.dart';

class CharacterDetailsPage extends StatefulWidget {
  final CharacterId id;

  const CharacterDetailsPage({super.key, required this.id});

  @override
  State createState() => _CharacterDetailsPageState();
}

class _CharacterDetailsPageState
    extends PageState<CharacterDetailsPage, CharacterDetailsPageBloc, CharacterDetailsPageBlocState> {
  @override
  CharacterDetailsPageBloc createBloc() => .new(
    host,
    characterId: widget.id,
    observeCharacter: getIt<ObserveCharacterUseCase>(),
    reloadCharacter: getIt<ReloadCharacterUseCase>(),
    observeReachability: getIt<ObserveReachabilityUseCase>(),
  );

  @override
  Widget buildPage(BuildContext context) {
    final state = bloc.state;
    final characterState = state.character;
    final isOffline = state.isOffline;

    // Show content
    final character = characterState.value;
    if (character != null) {
      return Scaffold(
        body: _CharacterScroll(character: character, isOffline: isOffline, onRefresh: bloc.reload),
      );
    }

    // Show full screen error
    final error = characterState.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(forceMaterialTransparency: true),
        body: ErrorPlate(error: error, isOffline: isOffline, onRetry: bloc.reload),
      );
    }

    // Still loading
    return Scaffold(appBar: AppBar(forceMaterialTransparency: true), body: const LoadingPlate());
  }
}

class _CharacterScroll extends StatelessWidget {
  final Character character;
  final bool isOffline;
  final Future<void> Function() onRefresh;

  const _CharacterScroll({required this.character, required this.isOffline, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expandedHeight = MediaQuery.sizeOf(context).width;
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final centerTitle = switch (theme.platform) {
      .iOS || .macOS => true,
      .android || .fuchsia || .linux || .windows => false,
    };

    return RefreshIndicator(
      edgeOffset: MediaQuery.paddingOf(context).top,
      onRefresh: onRefresh,
      child: CustomScrollView(
        // Bouncing physics lets the header overscroll on Android. Clamping
        // scroll never grows the sliver, so pull-down zoom would not run.
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            expandedHeight: expandedHeight,
            backgroundColor: colors.imageBackground,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: centerTitle,
              titlePadding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16),
              title: Text(
                character.name,
                maxLines: 2,
                textAlign: centerTitle ? .center : .start,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: _Portrait(url: character.imageUrl, isOffline: isOffline),
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverList.list(
              children: [
                _DetailRow(label: l10n.characterStatus, value: character.status),
                _DetailRow(label: l10n.species, value: character.species),
                _DetailRow(label: l10n.origin, value: character.origin),
                _DetailRow(label: l10n.location, value: character.location),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  final String url;
  final bool isOffline;

  const _Portrait({required this.url, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == .dark;
    final bottomColor = isDark ? theme.colorScheme.surface : const Color(0xFF000000);
    final bottomAlpha = isDark ? 1.0 : 0.8;

    return Stack(
      fit: StackFit.expand,
      children: [
        CharacterPortrait(url: url, style: .large, isOffline: isOffline),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x66000000),
                const Color(0x26000000),
                const Color(0x00000000),
                bottomColor.withValues(alpha: 0),
                bottomColor.withValues(alpha: bottomAlpha * 0.35),
                bottomColor.withValues(alpha: bottomAlpha * 0.7),
                bottomColor.withValues(alpha: bottomAlpha),
              ],
              stops: const [0, 0.2, 0.38, 0.5, 0.7, 0.86, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(label, style: theme.textTheme.labelLarge),
      subtitle: Text(value, style: theme.textTheme.titleMedium),
    );
  }
}
